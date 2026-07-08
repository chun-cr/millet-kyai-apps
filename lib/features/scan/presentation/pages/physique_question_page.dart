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
import '../../../../features/share/domain/entities/app_id_mapping_entity.dart';
import '../../../../features/share/domain/entities/share_referral_state.dart';
import '../../../../features/share/presentation/providers/share_referral_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/physique_question_models.dart';
import '../../data/models/scan_session.dart';
import '../../data/sources/physique_question_remote_source.dart';
import '../utils/scan_upload_tenant_context.dart';

part 'physique_question_widgets.dart';

const _kQuestionBgColor = Color(0xFFF4F1EB);
const _kQuestionPrimary = Color(0xFF2D6A4F);
const _kQuestionPrimaryLight = Color(0xFF3DAB78);
const _kDefaultPhysiqueQuestionCategory = String.fromEnvironment(
  'PHYSIQUE_QUESTION_CATEGORY',
  defaultValue: 'tzpd',
);

typedef ProfileLoader = Future<ProfileMeEntity?> Function(BuildContext context);
typedef AppIdMappingLoader =
    Future<AppIdMappingEntity?> Function(BuildContext context);
typedef ReportNavigator =
    Future<void> Function(BuildContext context, String? reportId);

class PhysiqueQuestionPage extends StatefulWidget {
  const PhysiqueQuestionPage({
    super.key,
    this.remoteSource,
    this.scanSession,
    this.profileLoader,
    this.appIdMappingLoader,
    this.navigateToReport,
    this.physiqueCategoryOverride,
  });

  final PhysiqueQuestionRemoteSource? remoteSource;
  final ScanSession? scanSession;
  final ProfileLoader? profileLoader;
  final AppIdMappingLoader? appIdMappingLoader;
  final ReportNavigator? navigateToReport;
  final String? physiqueCategoryOverride;

  @override
  State<PhysiqueQuestionPage> createState() => _PhysiqueQuestionPageState();
}

class _PhysiqueQuestionPageState extends State<PhysiqueQuestionPage> {
  late final PhysiqueQuestionRemoteSource _remoteSource;
  late final ScanSession _scanSession;

  PhysiqueQuestionRequestContext? _requestContext;
  PhysiqueQuestionPayload? _question;
  Object? _error;
  String? _selectedOptionValue;
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
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requestContext = await _buildRequestContext();
      if (!mounted) {
        return;
      }
      _requestContext = requestContext;
      await _requestNextQuestion(
        nextAnswers: _answers,
        amenorrhea: _amenorrhea,
        showFullScreenLoading: true,
      );
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

  Future<PhysiqueQuestionRequestContext> _buildRequestContext() async {
    final profile = await _loadProfile();
    final appIdMapping = await _loadAppIdMapping();
    final tenantContext = resolveScanUploadTenantContext(appIdMapping);

    final detectedGender = _scanSession.detectedGender;
    final resolvedGender = _resolveGender(profile?.gender, detectedGender);
    if (resolvedGender.isEmpty) {
      throw StateError('Missing gender for physique questionnaire.');
    }

    final resolvedPhysiqueCategory = _resolvePhysiqueCategory();
    if (resolvedPhysiqueCategory.isEmpty) {
      throw StateError('Missing phyCategory for physique questionnaire.');
    }

    return PhysiqueQuestionRequestContext(
      age: _scanSession.detectedAge,
      clinicId: tenantContext.clinicId,
      gender: resolvedGender,
      medicalCaseId: _scanSession.medicalCaseId,
      name: _resolveName(profile),
      phone: _resolvePhone(profile),
      phyCategory: resolvedPhysiqueCategory,
      storeId: tenantContext.storeId,
      t: _scanSession.nextQuestionT,
      tenantId: tenantContext.tenantId,
      key: _scanSession.nextQuestionKey,
      tongueReportId: _scanSession.tongueReportId,
      topOrgId: tenantContext.topOrgId,
    );
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

  Future<AppIdMappingEntity?> _loadAppIdMapping() async {
    final loader = widget.appIdMappingLoader;
    if (loader != null) {
      return loader(context);
    }

    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final state = await container.read(
        shareReferralControllerProvider.future,
      );
      return state.appIdMapping.isEmpty ? null : state.appIdMapping;
    } on Object {
      final cached = container.read(shareReferralControllerProvider);
      if (cached case AsyncData<ShareReferralState>(:final value)) {
        return value.appIdMapping.isEmpty ? null : value.appIdMapping;
      }
      return null;
    }
  }

  String _resolveGender(String? profileGender, String detectedGender) {
    final normalizedProfileGender = _normalizeGender(profileGender);
    if (normalizedProfileGender.isNotEmpty) {
      return normalizedProfileGender;
    }

    final normalizedDetectedGender = _normalizeGender(detectedGender);
    if (normalizedDetectedGender.isNotEmpty) {
      return normalizedDetectedGender;
    }

    return profileGender?.trim().isNotEmpty == true
        ? profileGender!.trim()
        : detectedGender.trim();
  }

  String _normalizeGender(String? rawValue) {
    final value = rawValue?.trim();
    if (value == null || value.isEmpty) {
      return '';
    }
    switch (value.toLowerCase()) {
      case 'male':
      case 'man':
      case 'm':
      case 'boy':
      case '男':
        return 'M';
      case 'female':
      case 'woman':
      case 'f':
      case 'girl':
      case '女':
        return 'F';
      default:
        return value;
    }
  }

  String _resolvePhysiqueCategory() {
    final override = widget.physiqueCategoryOverride?.trim() ?? '';
    if (override.isNotEmpty) {
      return override;
    }
    final sessionValue = _scanSession.phyCategory.trim();
    if (sessionValue.isNotEmpty) {
      return sessionValue;
    }
    return _kDefaultPhysiqueQuestionCategory.trim();
  }

  String? _resolveName(ProfileMeEntity? profile) {
    final values = <String?>[profile?.realName, profile?.nickname];
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  String? _resolvePhone(ProfileMeEntity? profile) {
    final trimmed = profile?.phone?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _requestNextQuestion({
    required List<PhysiqueQuestionRequestAnswer> nextAnswers,
    required String? amenorrhea,
    required bool showFullScreenLoading,
  }) async {
    final requestContext = _requestContext;
    if (requestContext == null) {
      return;
    }

    setState(() {
      _error = null;
      _isLoading = showFullScreenLoading;
      _isSubmitting = !showFullScreenLoading;
    });

    try {
      final envelope = await _remoteSource.fetchNextQuestion(
        requestContext.buildRequest(
          answers: nextAnswers,
          amenorrhea: amenorrhea,
        ),
      );
      final result = PhysiqueQuestionFlowResult.fromData(envelope.data);
      final nextReportId = result.reportId?.trim();
      if (nextReportId != null && nextReportId.isNotEmpty) {
        _scanSession.saveReportId(nextReportId);
      }

      if (result.isCompleted) {
        if (!mounted) {
          return;
        }
        setState(() {
          _answers = nextAnswers;
          _amenorrhea = amenorrhea;
          _question = null;
          _selectedOptionValue = null;
          _isLoading = false;
          _isSubmitting = false;
        });
        await _navigateToReport(nextReportId ?? _scanSession.reportId);
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _answers = nextAnswers;
        _amenorrhea = amenorrhea;
        _question = result.question;
        _selectedOptionValue = null;
        _isLoading = false;
        _isSubmitting = false;
      });
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

  Future<void> _submitCurrentAnswer() async {
    final question = _question;
    final selectedOption = _selectedOption;
    if (question == null || selectedOption == null || question.id == null) {
      return;
    }

    final nextAmenorrhea = question.isAmenorrheaQuestion
        ? selectedOption.value
        : _amenorrhea;
    final nextAnswers = <PhysiqueQuestionRequestAnswer>[
      ..._answers,
      PhysiqueQuestionRequestAnswer(
        id: question.id!,
        optionValue: selectedOption.value,
      ),
    ];

    await _requestNextQuestion(
      nextAnswers: nextAnswers,
      amenorrhea: nextAmenorrhea,
      showFullScreenLoading: false,
    );
  }

  Future<void> _navigateToReport(String? reportId) async {
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
      context.go(location);
    } finally {
      _isNavigating = false;
    }
  }

  void _handleSkip() {
    unawaited(_navigateToReport(_scanSession.reportId));
  }

  PhysiqueQuestionOption? get _selectedOption {
    final selectedValue = _selectedOptionValue;
    final question = _question;
    if (selectedValue == null || question == null) {
      return null;
    }
    for (final option in question.options) {
      if (option.value == selectedValue) {
        return option;
      }
    }
    return null;
  }

  String _errorMessage(AppLocalizations l10n) {
    final error = _error;
    if (error == null) {
      return l10n.scanQuestionLoadFailed;
    }
    final message = error.toString().trim();
    if (message.isEmpty) {
      return l10n.scanQuestionLoadFailed;
    }
    return message;
  }

  bool get _hasSelection => _selectedOptionValue != null;

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
                        selectedOptionValue: _selectedOptionValue,
                        isSubmitting: _isSubmitting,
                        hasSelection: _hasSelection,
                        onOptionSelected: (value) {
                          if (_isSubmitting) {
                            return;
                          }
                          setState(() => _selectedOptionValue = value);
                        },
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
