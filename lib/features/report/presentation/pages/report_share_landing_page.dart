// 报告模块页面：`ReportShareLandingPage`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const String _reportRoutePath = '/report';
const String _homeRoutePath = '/home';
const Set<String> _landingControlKeys = <String>{'p', 'path', 'redirect'};

String? resolveReportShareLandingTarget(Uri uri) {
  final passthroughQueryParameters = Map<String, String>.from(
    uri.queryParameters,
  )..removeWhere((key, _) => _landingControlKeys.contains(key));

  final payloadTarget = _resolvePayloadTarget(
    uri.queryParameters['p'],
    extraQueryParameters: passthroughQueryParameters,
  );
  if (payloadTarget != null) {
    return payloadTarget;
  }

  final redirectTarget = _buildTargetFromPath(
    uri.queryParameters['redirect'],
    extraQueryParameters: passthroughQueryParameters,
  );
  if (redirectTarget != null) {
    return redirectTarget;
  }

  final pathTarget = _buildTargetFromPath(
    uri.queryParameters['path'],
    extraQueryParameters: passthroughQueryParameters,
  );
  if (pathTarget != null) {
    return pathTarget;
  }

  final reportId = _trimmedOrNull(uri.queryParameters['reportId']);
  if (reportId == null) {
    return null;
  }

  return Uri(
    path: _reportRoutePath,
    queryParameters: <String, String>{'reportId': reportId},
  ).toString();
}

class ReportShareLandingPage extends StatefulWidget {
  const ReportShareLandingPage({super.key, required this.initialUri});

  final Uri initialUri;

  @override
  State<ReportShareLandingPage> createState() => _ReportShareLandingPageState();
}

class _ReportShareLandingPageState extends State<ReportShareLandingPage> {
  String? _targetLocation;
  bool _hasScheduledRedirect = false;

  @override
  void initState() {
    super.initState();
    _syncTargetLocation();
  }

  @override
  void didUpdateWidget(covariant ReportShareLandingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUri.toString() == widget.initialUri.toString()) {
      return;
    }
    _syncTargetLocation();
  }

  void _syncTargetLocation() {
    _targetLocation = resolveReportShareLandingTarget(widget.initialUri);
    _hasScheduledRedirect = false;
  }

  void _scheduleRedirect(String location) {
    if (_hasScheduledRedirect) {
      return;
    }
    _hasScheduledRedirect = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.go(location);
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetLocation = _targetLocation;
    if (targetLocation != null) {
      _scheduleRedirect(targetLocation);
      return const Scaffold(
        body: Center(
          child: Column(
            key: ValueKey('report_share_landing_loading'),
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator.adaptive(),
              SizedBox(height: 16),
              Text('Opening report...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            key: const ValueKey('report_share_landing_invalid'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.link_off_outlined,
                size: 40,
                color: Color(0xFFC06A3A),
              ),
              const SizedBox(height: 16),
              const Text(
                'This share link is invalid or incomplete.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('report_share_landing_home_button'),
                onPressed: () => context.go(_homeRoutePath),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _resolvePayloadTarget(
  String? rawPayload, {
  required Map<String, String> extraQueryParameters,
}) {
  final payload = _trimmedOrNull(rawPayload);
  if (payload == null) {
    return null;
  }

  final decodedPayload = _decodeUriComponentIfNeeded(payload);

  dynamic value;
  try {
    value = jsonDecode(decodedPayload);
  } catch (_) {
    return _buildTargetFromPath(
      decodedPayload,
      extraQueryParameters: extraQueryParameters,
    );
  }

  if (value is String) {
    return _buildTargetFromPath(
      value,
      extraQueryParameters: extraQueryParameters,
    );
  }
  if (value is! Map) {
    return null;
  }

  final payloadMap = Map<String, dynamic>.from(value);

  final redirectTarget = _buildTargetFromPath(
    payloadMap['redirect']?.toString(),
    extraQueryParameters: extraQueryParameters,
  );
  if (redirectTarget != null) {
    return redirectTarget;
  }

  final payloadQueryParameters = _normalizeQueryParameters(
    payloadMap['params'],
  );
  final pathTarget = _buildTargetFromPath(
    payloadMap['path']?.toString() ?? payloadMap['page']?.toString(),
    extraQueryParameters: <String, String>{
      ...extraQueryParameters,
      ...payloadQueryParameters,
    },
  );
  if (pathTarget != null) {
    return pathTarget;
  }

  final reportId =
      _trimmedOrNull(payloadMap['reportId']?.toString()) ??
      _trimmedOrNull(payloadMap['id']?.toString());
  if (reportId == null) {
    return null;
  }

  return Uri(
    path: _reportRoutePath,
    queryParameters: <String, String>{
      ...extraQueryParameters,
      'reportId': reportId,
    },
  ).toString();
}

String? _buildTargetFromPath(
  String? rawValue, {
  required Map<String, String> extraQueryParameters,
}) {
  final value = _trimmedOrNull(rawValue);
  if (value == null) {
    return null;
  }

  final decodedValue = _decodeUriComponentIfNeeded(value);
  final parsedUri = Uri.tryParse(decodedValue);
  if (parsedUri == null) {
    return null;
  }

  final path = _trimmedOrNull(parsedUri.path);
  if (path == null || !path.startsWith('/')) {
    return null;
  }

  final mergedQueryParameters = <String, String>{
    ...extraQueryParameters,
    ...parsedUri.queryParameters,
  };

  return Uri(
    path: path,
    queryParameters: mergedQueryParameters.isEmpty
        ? null
        : mergedQueryParameters,
  ).toString();
}

Map<String, String> _normalizeQueryParameters(Object? rawValue) {
  if (rawValue is Map) {
    final normalized = <String, String>{};
    for (final entry in rawValue.entries) {
      final key = _trimmedOrNull(entry.key.toString());
      final value = _trimmedOrNull(entry.value?.toString());
      if (key == null || value == null) {
        continue;
      }
      normalized[key] = value;
    }
    return normalized;
  }

  final value = _trimmedOrNull(rawValue?.toString());
  if (value == null) {
    return const <String, String>{};
  }

  final normalizedQuery = value.startsWith('?') ? value.substring(1) : value;
  if (normalizedQuery.isEmpty) {
    return const <String, String>{};
  }

  return Uri(query: normalizedQuery).queryParameters;
}

String _decodeUriComponentIfNeeded(String value) {
  if (!value.contains('%')) {
    return value;
  }
  try {
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
