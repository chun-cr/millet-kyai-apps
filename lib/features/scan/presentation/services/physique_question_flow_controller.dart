import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../../../features/profile/domain/entities/profile_me_entity.dart';
import '../../../../features/profile/presentation/providers/profile_repository_provider.dart';
import '../../../../features/share/domain/entities/app_id_mapping_entity.dart';
import '../../../../features/share/domain/entities/share_referral_state.dart';
import '../../../../features/share/presentation/providers/share_referral_provider.dart';
import '../../data/models/physique_question_models.dart';
import '../../data/models/scan_session.dart';
import '../../data/sources/physique_question_remote_source.dart';
import '../../data/sources/scan_remote_source.dart';
import '../utils/scan_upload_tenant_context.dart';

const defaultPhysiqueQuestionCategory = 'tzpd';
const questionBootstrapRetryDelays = <Duration>[
  Duration(milliseconds: 300),
  Duration(milliseconds: 800),
  Duration(milliseconds: 1500),
];
const questionSubmitRetryDelays = <Duration>[
  Duration(milliseconds: 300),
  Duration(milliseconds: 800),
  Duration(milliseconds: 1500),
  Duration(milliseconds: 2500),
  Duration(milliseconds: 4000),
];

typedef PhysiqueQuestionProfileLoader = Future<ProfileMeEntity?> Function();
typedef PhysiqueQuestionAppIdMappingLoader =
    Future<AppIdMappingEntity?> Function();

class MissingReportIdException implements Exception {
  const MissingReportIdException();

  @override
  String toString() => '报告还在生成中，请稍候重试。';
}

class FirstQuestionMissingException implements Exception {
  const FirstQuestionMissingException();

  @override
  String toString() => '暂未获取到体质问卷题目，请稍后重试。';
}

class QuestionContextValidationException implements Exception {
  const QuestionContextValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QuestionContextNotReadyException implements Exception {
  const QuestionContextNotReadyException(this.cause);

  final Object cause;

  @override
  String toString() => cause.toString();
}

class PhysiqueQuestionFlowController {
  const PhysiqueQuestionFlowController({
    required this.remoteSource,
    required this.scanSession,
    this.profileLoader,
    this.appIdMappingLoader,
  });

  final PhysiqueQuestionRemoteSource remoteSource;
  final ScanSession scanSession;
  final PhysiqueQuestionProfileLoader? profileLoader;
  final PhysiqueQuestionAppIdMappingLoader? appIdMappingLoader;

  Future<PhysiqueQuestionFlowSnapshot> ensureFirstQuestion({
    bool allowReadinessRetry = false,
    List<Duration> readinessRetryDelays = questionBootstrapRetryDelays,
  }) {
    final cached = scanSession.questionFlowSnapshot;
    if (cached != null) {
      return Future<PhysiqueQuestionFlowSnapshot>.value(cached);
    }

    final existingPrefetch = scanSession.questionPrefetchFuture;
    if (existingPrefetch != null) {
      return existingPrefetch;
    }

    final future = requestNextQuestion(
      nextAnswers: const <PhysiqueQuestionRequestAnswer>[],
      amenorrhea: null,
      allowReadinessRetry: allowReadinessRetry,
      readinessRetryDelays: readinessRetryDelays,
    );
    return scanSession.trackQuestionPrefetch(future);
  }

  Future<PhysiqueQuestionFlowSnapshot> requestNextQuestion({
    required List<PhysiqueQuestionRequestAnswer> nextAnswers,
    required String? amenorrhea,
    required bool allowReadinessRetry,
    required List<Duration> readinessRetryDelays,
  }) async {
    final requestContext = await buildRequestContext();
    return _requestNextQuestionWithRetry(
      requestContext: requestContext,
      nextAnswers: nextAnswers,
      amenorrhea: amenorrhea,
      allowReadinessRetry: allowReadinessRetry,
      readinessRetryDelays: readinessRetryDelays,
    );
  }

  Future<PhysiqueQuestionRequestContext> buildRequestContext() async {
    final profile = await _loadProfile();
    if (profile != null) {
      scanSession.saveQuestionProfileSnapshot(
        name: _resolveName(profile),
        phone: _resolvePhone(profile),
        gender: profile.gender,
      );
    }

    final appIdMapping = await _loadAppIdMapping();
    final tenantContext = resolveScanUploadTenantContext(appIdMapping);
    scanSession.saveTenantContext(
      tenantId: tenantContext.tenantId,
      topOrgId: tenantContext.topOrgId,
      storeId: tenantContext.storeId,
      clinicId: tenantContext.clinicId,
    );

    final detectedGender = scanSession.detectedGender;
    final resolvedGender = _resolveGender(
      scanSession.questionGender,
      detectedGender,
    );
    if (resolvedGender.isEmpty) {
      throw StateError('Missing gender for physique questionnaire.');
    }

    final resolvedPhysiqueCategory = _resolvePhysiqueCategory();
    if (resolvedPhysiqueCategory.isEmpty) {
      throw StateError('Missing phyCategory for physique questionnaire.');
    }

    final requestContext = PhysiqueQuestionRequestContext(
      age: scanSession.detectedAge,
      clinicId: scanSession.clinicId,
      gender: resolvedGender,
      medicalCaseId: scanSession.medicalCaseId,
      name: scanSession.questionName,
      phone: scanSession.questionPhone,
      phyCategory: resolvedPhysiqueCategory,
      reportId: scanSession.reportId?.trim(),
      storeId: scanSession.storeId,
      t: scanSession.nextQuestionT,
      tenantId: scanSession.tenantId,
      key: scanSession.nextQuestionKey,
      tongueReportId: scanSession.tongueReportId,
      topOrgId: scanSession.topOrgId,
    );
    _validateRequestContext(requestContext);
    _logRequestContext(requestContext);
    return requestContext;
  }

  Future<ProfileMeEntity?> _loadProfile() async {
    final loader = profileLoader;
    if (loader == null) {
      return null;
    }
    try {
      return await loader();
    } on Object {
      return null;
    }
  }

  Future<AppIdMappingEntity?> _loadAppIdMapping() async {
    final loader = appIdMappingLoader;
    if (loader == null) {
      return null;
    }
    try {
      return await loader();
    } on Object {
      return null;
    }
  }

  Future<PhysiqueQuestionFlowSnapshot> _requestNextQuestionWithRetry({
    required PhysiqueQuestionRequestContext requestContext,
    required List<PhysiqueQuestionRequestAnswer> nextAnswers,
    required String? amenorrhea,
    required bool allowReadinessRetry,
    required List<Duration> readinessRetryDelays,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await _requestNextQuestionOnce(
          requestContext: requestContext,
          nextAnswers: nextAnswers,
          amenorrhea: amenorrhea,
          allowContextNotReady: allowReadinessRetry,
        );
      } on Object catch (error) {
        final canRetry =
            allowReadinessRetry &&
            attempt < readinessRetryDelays.length &&
            isRetryableQuestionReadinessError(
              error,
              retryParamInvalid: nextAnswers.isNotEmpty,
            );
        if (!canRetry) {
          rethrow;
        }

        final delay = readinessRetryDelays[attempt];
        AppLogger.network(
          'Physique question flow context not ready; '
          'retry=${attempt + 1}/${readinessRetryDelays.length} '
          'delayMs=${delay.inMilliseconds} error=$error',
        );
        attempt += 1;
        await Future<void>.delayed(delay);
      }
    }
  }

  Future<PhysiqueQuestionFlowSnapshot> _requestNextQuestionOnce({
    required PhysiqueQuestionRequestContext requestContext,
    required List<PhysiqueQuestionRequestAnswer> nextAnswers,
    required String? amenorrhea,
    required bool allowContextNotReady,
  }) async {
    _logRequestPayload(
      requestContext: requestContext,
      answers: nextAnswers,
      amenorrhea: amenorrhea,
    );
    final envelope = await remoteSource.fetchNextQuestion(
      requestContext.buildRequest(answers: nextAnswers, amenorrhea: amenorrhea),
    );
    final result = PhysiqueQuestionFlowResult.fromData(envelope.data);
    _logQuestionResponseParseResult(envelope.data, result);
    final existingReportId = scanSession.reportId?.trim();
    final nextReportId = result.reportId?.trim();
    if (result.isCompleted && nextAnswers.isEmpty) {
      AppLogger.network(
        'Physique question first request returned no renderable question; '
        'treating as not ready. ${_describeQuestionResponseShape(envelope.data)}',
      );
      final error = const FirstQuestionMissingException();
      if (allowContextNotReady) {
        throw QuestionContextNotReadyException(error);
      }
      throw error;
    }

    if (!result.isCompleted &&
        nextReportId != null &&
        nextReportId.isNotEmpty) {
      scanSession.saveReportId(nextReportId);
    }

    String? completionReportId;
    if (result.isCompleted) {
      final targetReportId = existingReportId?.isNotEmpty == true
          ? existingReportId
          : nextReportId;
      if (targetReportId == null || targetReportId.isEmpty) {
        final error = const MissingReportIdException();
        if (allowContextNotReady) {
          throw QuestionContextNotReadyException(error);
        }
        throw error;
      }
      completionReportId = targetReportId;
      if (existingReportId == null || existingReportId.isEmpty) {
        scanSession.saveReportId(targetReportId);
      }
      final completedResult = result.completedResult;
      if (completedResult != null && completedResult.isNotEmpty) {
        scanSession.saveQuestionCompletionResult(completedResult);
      }
    }

    final snapshot = PhysiqueQuestionFlowSnapshot(
      requestContext: requestContext,
      answers: nextAnswers,
      amenorrhea: amenorrhea,
      question: result.question,
      completedResult: result.completedResult,
      completionReportId: completionReportId,
    );
    scanSession.saveQuestionFlowSnapshot(snapshot);
    return snapshot;
  }

  void _validateRequestContext(PhysiqueQuestionRequestContext context) {
    final missingFields = <String>[
      if (context.gender.trim().isEmpty) 'gender',
      if (context.phyCategory.trim().isEmpty) 'phyCategory',
    ];
    if (missingFields.isEmpty) {
      return;
    }

    throw QuestionContextValidationException(
      'Physique questionnaire missing required context: '
      '${missingFields.join(", ")}.',
    );
  }

  void _logRequestContext(PhysiqueQuestionRequestContext context) {
    AppLogger.network(
      'Physique question request context: '
      'tongueReportId=${context.tongueReportId ?? "null"} '
      'reportId=${_isPresent(context.reportId) ? context.reportId : "null"} '
      'medicalCaseId=${context.medicalCaseId ?? "null"} '
      'tenantId=${context.tenantId ?? "null"} '
      'storeId=${context.storeId ?? "null"} '
      'topOrgId=${context.topOrgId ?? "null"} '
      'clinicId=${context.clinicId ?? "null"} '
      'gender=${context.gender.isEmpty ? "empty" : context.gender} '
      'age=${context.age ?? "null"} '
      'phyCategory=${context.phyCategory} '
      't=${context.t ?? "null"} '
      'key=${(context.key ?? "").trim().isEmpty ? "empty" : "present"} '
      'phone=${_maskedPhone(context.phone)}',
    );
  }

  void _logRequestPayload({
    required PhysiqueQuestionRequestContext requestContext,
    required List<PhysiqueQuestionRequestAnswer> answers,
    required String? amenorrhea,
  }) {
    final lastAnswer = answers.isEmpty ? null : answers.last;
    AppLogger.network(
      'Physique question request payload: '
      'tongueReportId=${requestContext.tongueReportId ?? "null"} '
      'tenantId=${requestContext.tenantId ?? "null"} '
      'storeId=${requestContext.storeId ?? "null"} '
      'gender=${requestContext.gender.isEmpty ? "empty" : requestContext.gender} '
      'age=${requestContext.age ?? "null"} '
      'answersLength=${answers.length} '
      'lastAnswerId=${lastAnswer?.id ?? "null"} '
      'lastAnswerOptionValue=${_logValue(lastAnswer?.optionValue)} '
      'isFirstRequest=${answers.isEmpty} '
      'isAnswerAdvanceRequest=${answers.isNotEmpty} '
      'amenorrhea=${_logValue(amenorrhea)}',
    );
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
    final sessionValue = scanSession.phyCategory.trim();
    if (sessionValue.isNotEmpty) {
      return sessionValue;
    }
    return defaultPhysiqueQuestionCategory.trim();
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

  String _maskedPhone(String? phone) {
    final value = phone?.trim() ?? '';
    if (value.isEmpty) {
      return 'empty';
    }
    if (value.length <= 4) {
      return 'present';
    }
    return '***${value.substring(value.length - 4)}';
  }

  bool _isPresent(String? value) => value != null && value.trim().isNotEmpty;

  String _logValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'empty';
    }
    return trimmed;
  }

  String _describeQuestionResponseShape(Map<String, dynamic> data) {
    final keys = data.keys.take(12).join(',');
    final next = _asMap(data['next']);
    final question = _asMap(data['question']);
    final result = _asMap(data['result']);
    return 'keys=${keys.isEmpty ? "empty" : keys} '
        'hasNext=${next.isNotEmpty} '
        'hasQuestion=${question.isNotEmpty} '
        'hasResult=${result.isNotEmpty} '
        'nextKeys=${next.keys.take(8).join(",")} '
        'questionKeys=${question.keys.take(8).join(",")}';
  }

  void _logQuestionResponseParseResult(
    Map<String, dynamic> data,
    PhysiqueQuestionFlowResult result,
  ) {
    final question = result.question;
    AppLogger.network(
      'Physique question response parsed: '
      'hasQuestion=${question != null} '
      'questionId=${question?.id ?? "null"} '
      'titlePresent=${question?.title.trim().isNotEmpty == true} '
      'optionCount=${question?.options.length ?? 0} '
      'isCompleted=${result.isCompleted} '
      '${_describeQuestionResponseShape(data)}',
    );
  }
}

Future<ProfileMeEntity?> loadPhysiqueQuestionProfileFromContainer(
  ProviderContainer container,
) async {
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

Future<AppIdMappingEntity?> loadPhysiqueQuestionAppIdMappingFromContainer(
  ProviderContainer container,
) async {
  try {
    final state = await container.read(shareReferralControllerProvider.future);
    return state.appIdMapping.isEmpty ? null : state.appIdMapping;
  } on Object {
    final cached = container.read(shareReferralControllerProvider);
    if (cached case AsyncData<ShareReferralState>(:final value)) {
      return value.appIdMapping.isEmpty ? null : value.appIdMapping;
    }
    return null;
  }
}

List<PhysiqueQuestionRequestAnswer> upsertPhysiqueQuestionAnswer(
  List<PhysiqueQuestionRequestAnswer> answers,
  PhysiqueQuestionRequestAnswer nextAnswer,
) {
  final nextAnswers = <PhysiqueQuestionRequestAnswer>[];
  var replaced = false;
  for (final answer in answers) {
    if (answer.id == nextAnswer.id) {
      nextAnswers.add(nextAnswer);
      replaced = true;
    } else {
      nextAnswers.add(answer);
    }
  }
  if (!replaced) {
    nextAnswers.add(nextAnswer);
  }
  return nextAnswers;
}

bool isRetryableQuestionReadinessError(
  Object error, {
  bool retryParamInvalid = false,
}) {
  final cause = error is QuestionContextNotReadyException ? error.cause : error;
  if (cause is MissingReportIdException) {
    return true;
  }
  if (cause is FirstQuestionMissingException) {
    return true;
  }
  if (cause is! ScanUploadException) {
    return false;
  }
  if (cause.statusCode == 401 || cause.statusCode == 403) {
    return false;
  }
  if (cause.businessCode == 24043 ||
      cause.messageKey == 'physique.param_invalid') {
    return retryParamInvalid;
  }

  final messageKey = cause.messageKey?.trim();
  if (messageKey != null && messageKey.isNotEmpty) {
    return _retryableQuestionMessageKeys.contains(messageKey);
  }

  final businessCode = cause.businessCode;
  if (businessCode != null) {
    return _retryableQuestionBusinessCodes.contains(businessCode);
  }

  return false;
}

const _retryableQuestionMessageKeys = <String>{
  'physique.question_not_ready',
  'physique.question.not_ready',
  'physique.report_generating',
  'physique.report.generating',
  'physique.no_question',
  'physique.question.no_question',
};

const _retryableQuestionBusinessCodes = <int>{24041, 24042};

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}
