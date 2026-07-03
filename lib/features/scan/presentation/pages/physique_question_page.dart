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

const _kQuestionBgColor = Color(0xFFF4F1EB);
const _kQuestionPrimary = Color(0xFF2D6A4F);
const _kQuestionPrimaryLight = Color(0xFF3DAB78);
const _kDefaultPhysiqueQuestionCategory = String.fromEnvironment(
  'PHYSIQUE_QUESTION_CATEGORY',
  defaultValue: ScanSession.reportSource,
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
      clinicId: _resolveOptionalInt(<String>[
        appIdMapping?.clinicId ?? '',
        appIdMapping?.defaultClinicId ?? '',
        appIdMapping?.storeId ?? '',
        appIdMapping?.defaultStoreId ?? '',
      ]),
      gender: resolvedGender,
      medicalCaseId: _scanSession.medicalCaseId,
      name: _resolveName(profile),
      phone: _resolvePhone(profile),
      phyCategory: resolvedPhysiqueCategory,
      tongueReportId: _scanSession.tongueReportId,
      topOrgId: _resolveOptionalInt(<String>[
        appIdMapping?.topOrgId ?? '',
        appIdMapping?.tenantId ?? '',
      ]),
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

  int? _resolveOptionalInt(List<String> values) {
    for (final value in values) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
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

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({
    required this.title,
    required this.subtitle,
    required this.answeredCount,
    required this.skipLabel,
    required this.onSkip,
  });

  final String title;
  final String subtitle;
  final int answeredCount;
  final String skipLabel;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kQuestionPrimary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: _kQuestionPrimary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2C312E),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('scan_question_skip_button'),
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: _kQuestionPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text(skipLabel),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFF3A3028).withValues(alpha: 0.76),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.question_answer_outlined,
                label: l10n.scanQuestionAnsweredCount(answeredCount),
              ),
              _InfoChip(
                icon: Icons.bolt_outlined,
                label: l10n.scanQuestionOptionalTag,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.l10n,
    required this.question,
    required this.answeredCount,
    required this.selectedOptionValue,
    required this.isSubmitting,
    required this.hasSelection,
    required this.onOptionSelected,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final PhysiqueQuestionPayload? question;
  final int answeredCount;
  final String? selectedOptionValue;
  final bool isSubmitting;
  final bool hasSelection;
  final ValueChanged<String> onOptionSelected;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final resolvedQuestion = question;
    if (resolvedQuestion == null) {
      return _QuestionErrorView(
        title: l10n.scanQuestionLoadFailed,
        message: l10n.scanQuestionMissingQuestion,
        retryLabel: l10n.scanQuestionRetry,
        onRetry: onSubmit,
      );
    }

    final isLastQuestion =
        resolvedQuestion.currentIndex != null &&
        resolvedQuestion.totalCount != null &&
        resolvedQuestion.currentIndex! >= resolvedQuestion.totalCount!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kQuestionPrimary.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: _kQuestionPrimary.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      resolvedQuestion.currentIndex != null &&
                              resolvedQuestion.totalCount != null
                          ? l10n.scanQuestionProgressTitle(
                              resolvedQuestion.currentIndex!,
                              resolvedQuestion.totalCount!,
                            )
                          : l10n.scanQuestionSectionTitle,
                      style: const TextStyle(
                        color: _kQuestionPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Text(
                    l10n.scanQuestionAnsweredCount(answeredCount),
                    style: TextStyle(
                      color: const Color(0xFF3A3028).withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                resolvedQuestion.title,
                key: const ValueKey('scan_question_title'),
                style: const TextStyle(
                  color: Color(0xFF242924),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              if (resolvedQuestion.description.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  resolvedQuestion.description,
                  style: TextStyle(
                    color: const Color(0xFF3A3028).withValues(alpha: 0.72),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ...resolvedQuestion.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuestionOptionTile(
                    option: option,
                    selected: option.value == selectedOptionValue,
                    onTap: () => onOptionSelected(option.value),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: LinearProgressIndicator(
                    key: ValueKey('scan_question_submit_progress'),
                    minHeight: 4,
                    color: _kQuestionPrimaryLight,
                    backgroundColor: Color(0xFFE5EFE9),
                  ),
                ),
              _PrimaryQuestionButton(
                key: const ValueKey('scan_question_submit_button'),
                label: isLastQuestion
                    ? l10n.scanQuestionSubmitAndReport
                    : l10n.scanQuestionNextButton,
                enabled: hasSelection && !isSubmitting,
                onTap: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionOptionTile extends StatelessWidget {
  const _QuestionOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PhysiqueQuestionOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('scan_question_option_${option.value}'),
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? _kQuestionPrimary.withValues(alpha: 0.08)
              : const Color(0xFFF9F8F4),
          border: Border.all(
            color: selected
                ? _kQuestionPrimaryLight
                : _kQuestionPrimary.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _kQuestionPrimary : Colors.white,
                border: Border.all(
                  color: selected
                      ? _kQuestionPrimary
                      : _kQuestionPrimary.withValues(alpha: 0.25),
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      color: const Color(0xFF242924),
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  if (option.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      option.description,
                      style: TextStyle(
                        color: const Color(0xFF3A3028).withValues(alpha: 0.66),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionLoadingView extends StatelessWidget {
  const _QuestionLoadingView({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _kQuestionPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF242924),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF3A3028).withValues(alpha: 0.72),
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionErrorView extends StatelessWidget {
  const _QuestionErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _kQuestionPrimary.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFB36A4C),
                size: 32,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF242924),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF3A3028).withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 16),
              _PrimaryQuestionButton(
                label: retryLabel,
                enabled: true,
                onTap: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionFooter extends StatelessWidget {
  const _QuestionFooter({required this.hint, required this.isLoading});

  final String hint;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kQuestionPrimary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            isLoading ? Icons.sync_rounded : Icons.shield_outlined,
            size: 18,
            color: _kQuestionPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                color: const Color(0xFF3A3028).withValues(alpha: 0.74),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryQuestionButton extends StatelessWidget {
  const _PrimaryQuestionButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => unawaited(onTap()) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [
                    Color(0xFF1D5E40),
                    _kQuestionPrimary,
                    _kQuestionPrimaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : const Color(0xFFE0DDD8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _kQuestionPrimary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : const Color(0xFF9A9590),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _kQuestionPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _kQuestionPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
