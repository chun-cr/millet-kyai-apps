// 扫描模块页面：`PhysiqueQuestionPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/logger.dart';
import '../../../../features/profile/domain/entities/profile_me_entity.dart';
import '../../../../features/profile/presentation/providers/profile_repository_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/physique_question_models.dart';
import '../../data/models/scan_session.dart';
import '../../data/sources/physique_question_remote_source.dart';
import '../../data/sources/scan_remote_source.dart';
import '../services/physique_question_flow_controller.dart';
import '../services/physique_question_report_view_builder.dart';

part 'physique_question_widgets.dart';

const _kQuestionBgColor = Color(0xFFF4F1EB);
const _kQuestionPrimary = Color(0xFF2D6A4F);
const _kQuestionPrimaryLight = Color(0xFF3DAB78);

typedef ProfileLoader = Future<ProfileMeEntity?> Function(BuildContext context);
typedef ReportNavigator =
    Future<void> Function(BuildContext context, String? reportId);

class PhysiqueQuestionPage extends StatefulWidget {
  const PhysiqueQuestionPage({
    super.key,
    this.remoteSource,
    this.scanSession,
    this.profileLoader,
    this.navigateToReport,
  });

  final PhysiqueQuestionRemoteSource? remoteSource;
  final ScanSession? scanSession;
  final ProfileLoader? profileLoader;
  final ReportNavigator? navigateToReport;

  @override
  State<PhysiqueQuestionPage> createState() => _PhysiqueQuestionPageState();
}

class _PhysiqueQuestionPageState extends State<PhysiqueQuestionPage> {
  late final PhysiqueQuestionRemoteSource _remoteSource;
  late final ScanSession _scanSession;
  late final PhysiqueQuestionFlowController _flowController;

  PhysiqueQuestionPayload? _question;
  Object? _error;
  Set<String> _selectedOptionValues = <String>{};
  String? _amenorrhea;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isNavigating = false;
  List<PhysiqueQuestionRequestAnswer> _answers =
      const <PhysiqueQuestionRequestAnswer>[];

  @override
  void initState() {
    super.initState();
    initInjector();
    _remoteSource =
        widget.remoteSource ?? PhysiqueQuestionRemoteSource(getIt<DioClient>());
    _scanSession = widget.scanSession ?? getIt<ScanSession>();
    _flowController = PhysiqueQuestionFlowController(
      remoteSource: _remoteSource,
      scanSession: _scanSession,
      profileLoader: () => _loadProfile(),
    );
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await _flowController.ensureFirstQuestion(
        allowReadinessRetry: true,
      );
      await _applyQuestionSnapshot(snapshot);
    } on Object catch (error, stackTrace) {
      AppLogger.log(
        'Failed to bootstrap physique questions: $error\n$stackTrace',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<ProfileMeEntity?> _loadProfile() async {
    final loader = widget.profileLoader;
    if (loader != null) {
      return loader(context);
    }

    final container = ProviderScope.containerOf(context, listen: false);
    try {
      return await container.read(profileMeProvider.future);
    } on Object {
      try {
        final repository = container.read(profileRepositoryProvider);
        return await repository.fetchMe();
      } on Object {
        return null;
      }
    }
  }

  Future<void> _requestNextQuestion({
    required List<PhysiqueQuestionRequestAnswer> nextAnswers,
    required String? amenorrhea,
    required bool showFullScreenLoading,
    bool allowReadinessRetry = false,
    List<Duration> readinessRetryDelays = questionBootstrapRetryDelays,
  }) async {
    setState(() {
      _error = null;
      _isLoading = showFullScreenLoading;
      _isSubmitting = !showFullScreenLoading;
    });

    try {
      final snapshot = await _flowController.requestNextQuestion(
        nextAnswers: nextAnswers,
        amenorrhea: amenorrhea,
        allowReadinessRetry: allowReadinessRetry,
        readinessRetryDelays: readinessRetryDelays,
      );
      await _applyQuestionSnapshot(snapshot);
    } on Object catch (error, stackTrace) {
      AppLogger.log('Physique question request failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
        _isSubmitting = false;
      });
    }
  }

  Future<void> _applyQuestionSnapshot(
    PhysiqueQuestionFlowSnapshot snapshot,
  ) async {
    if (!mounted) {
      return;
    }

    if (!snapshot.hasQuestion) {
      final reportId = snapshot.completionReportId?.trim().isNotEmpty == true
          ? snapshot.completionReportId!.trim()
          : _scanSession.reportId?.trim();
      if (reportId == null || reportId.isEmpty) {
        throw const MissingReportIdException();
      }
      final initialViewData = buildPhysiqueQuestionCompletionReportViewData(
        scanSession: _scanSession,
        snapshot: snapshot,
        reportId: reportId,
      );
      setState(() {
        _answers = snapshot.answers;
        _amenorrhea = snapshot.amenorrhea;
        _question = null;
        _selectedOptionValues = <String>{};
        _error = null;
        _isLoading = false;
        _isSubmitting = false;
      });
      await _navigateToReport(reportId, initialViewData: initialViewData);
      return;
    }

    setState(() {
      _answers = snapshot.answers;
      _amenorrhea = snapshot.amenorrhea;
      _question = snapshot.question;
      _selectedOptionValues = <String>{};
      _error = null;
      _isLoading = false;
      _isSubmitting = false;
    });
  }

  Future<void> _submitCurrentAnswer() async {
    if (_isSubmitting || _isLoading || _isNavigating) {
      return;
    }

    final question = _question;
    if (question == null ||
        _selectedOptionValues.isEmpty ||
        question.id == null) {
      return;
    }

    await _submitAnswer(
      question: question,
      optionValues: _selectedOptionValues.toList(growable: false),
    );
  }

  void _handleOptionSelected(String value) {
    if (_isSubmitting || _isLoading || _isNavigating) {
      return;
    }

    final question = _question;
    if (question == null) {
      return;
    }

    final selectedOptionValues = Set<String>.from(_selectedOptionValues);
    if (question.isSingleChoice) {
      selectedOptionValues
        ..clear()
        ..add(value);
    } else if (!selectedOptionValues.add(value)) {
      selectedOptionValues.remove(value);
    }
    setState(() => _selectedOptionValues = selectedOptionValues);
    if (question.isSingleChoice) {
      unawaited(
        _submitAnswer(question: question, optionValues: <String>[value]),
      );
    }
  }

  Future<void> _submitAnswer({
    required PhysiqueQuestionPayload question,
    required List<String> optionValues,
  }) async {
    if (_isSubmitting ||
        _isLoading ||
        _isNavigating ||
        question.id == null ||
        optionValues.isEmpty) {
      return;
    }

    final nextAmenorrhea = question.isAmenorrheaQuestion
        ? optionValues.first
        : _amenorrhea;
    final nextAnswers = upsertPhysiqueQuestionAnswer(
      _answers,
      PhysiqueQuestionRequestAnswer(
        id: question.id!,
        optionValues: optionValues,
      ),
    );

    await _requestNextQuestion(
      nextAnswers: nextAnswers,
      amenorrhea: nextAmenorrhea,
      showFullScreenLoading: false,
      allowReadinessRetry: true,
      readinessRetryDelays: questionSubmitRetryDelays,
    );
  }

  Future<void> _navigateToReport(
    String? reportId, {
    Object? initialViewData,
  }) async {
    if (_isNavigating || !mounted) {
      return;
    }
    _isNavigating = true;
    try {
      final navigator = widget.navigateToReport;
      if (navigator != null) {
        await navigator(context, reportId);
        return;
      }

      final trimmedReportId = reportId?.trim();
      final location = trimmedReportId == null || trimmedReportId.isEmpty
          ? AppRoutes.reportAnalysis
          : Uri(
              path: AppRoutes.reportAnalysis,
              queryParameters: <String, String>{'reportId': trimmedReportId},
            ).toString();
      if (!mounted) {
        return;
      }
      context.go(location, extra: initialViewData);
    } finally {
      _isNavigating = false;
    }
  }

  void _handleSkip() {
    final reportId = _scanSession.reportId?.trim();
    if (reportId == null || reportId.isEmpty) {
      setState(() {
        _error = const MissingReportIdException();
        _question = null;
        _isLoading = false;
        _isSubmitting = false;
      });
      return;
    }
    unawaited(_navigateToReport(reportId));
  }

  String _errorMessage(AppLocalizations l10n) {
    final error = _error;
    if (error == null) {
      return l10n.scanQuestionLoadFailed;
    }
    if (error is ScanUploadException && error.isAuthenticationFailure) {
      return '登录状态已失效，请重新登录后再试。';
    }
    final message = error.toString().trim();
    if (message.isEmpty) {
      return l10n.scanQuestionLoadFailed;
    }
    return message;
  }

  bool get _hasSelection => _selectedOptionValues.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final question = _question;
    final showLoadingState = _isLoading && question == null;

    return Scaffold(
      backgroundColor: _kQuestionBgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _QuestionHeader(
              title: l10n.scanQuestionTitle,
              subtitle: l10n.scanQuestionSubtitle,
              answeredCount: _answers.length,
              skipLabel: l10n.scanQuestionSkipDirectReport,
              onSkip: _handleSkip,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: showLoadingState
                    ? _QuestionLoadingView(
                        key: const ValueKey('scan_question_loading'),
                        title: l10n.scanQuestionLoadingTitle,
                        subtitle: l10n.scanQuestionLoadingBody,
                      )
                    : _error != null && question == null
                    ? _QuestionErrorView(
                        key: const ValueKey('scan_question_error'),
                        title: l10n.scanQuestionLoadFailed,
                        message: _errorMessage(l10n),
                        retryLabel: l10n.scanQuestionRetry,
                        onRetry: _bootstrap,
                      )
                    : _QuestionCard(
                        key: const ValueKey('scan_question_card'),
                        l10n: l10n,
                        question: question,
                        answeredCount: _answers.length,
                        selectedOptionValues: _selectedOptionValues,
                        isSubmitting: _isSubmitting,
                        hasSelection: _hasSelection,
                        submissionErrorMessage: _error == null
                            ? null
                            : _errorMessage(l10n),
                        onOptionSelected: _handleOptionSelected,
                        onSubmit: _submitCurrentAnswer,
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: _QuestionFooter(
                hint: l10n.scanQuestionFooterHint,
                isLoading: _isLoading || _isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
