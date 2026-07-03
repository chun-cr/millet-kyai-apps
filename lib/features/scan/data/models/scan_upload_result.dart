// 扫描模块数据模型：`ScanUploadResult`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

import 'dart:convert';

class ScanFaceUploadResult {
  const ScanFaceUploadResult(this.data);

  factory ScanFaceUploadResult.fromJson(Map<String, dynamic> json) {
    return ScanFaceUploadResult(Map<String, dynamic>.from(json));
  }

  final Map<String, dynamic> data;

  int get faceNum => (_asNum(data['faceNum']) ?? 0).toInt();
  String get imageId => _asString(data['imageId']);
  String get imageUrl => _asString(data['imageUrl']);
  Object? get features => data['features'];
  num? get age => _asNum(data['age']);
  Object? get sex => data['sex'];

  bool get hasSingleFace => faceNum == 1;

  Map<String, dynamic> toTongueFaceData() {
    return <String, dynamic>{
      if (imageId.isNotEmpty) 'unionId': imageId,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (features != null) 'features': features,
      if (age != null) 'age': age,
      if (sex != null) 'sex': sex,
    };
  }

  String toTongueFaceDataJson() => jsonEncode(toTongueFaceData());
}

class ScanTongueUploadResult {
  const ScanTongueUploadResult(this.data);

  factory ScanTongueUploadResult.fromJson(Map<String, dynamic> json) {
    return ScanTongueUploadResult(Map<String, dynamic>.from(json));
  }

  final Map<String, dynamic> data;

  String get imageUrl => _asString(data['imageUrl']);

  Map<String, dynamic> get analysisResult => _asMap(data['analysisResult']);
  Map<String, dynamic> get tongueReport => _asMap(data['tongueReport']);

  String get reportId => _asString(tongueReport['reportId']);
  int? get tongueReportId => _firstInt(<Object?>[
    tongueReport['tongueReportId'],
    tongueReport['id'],
    data['tongueReportId'],
  ]);
  int? get medicalCaseId => _firstInt(<Object?>[
    data['medicalCaseId'],
    tongueReport['medicalCaseId'],
    analysisResult['medicalCaseId'],
  ]);
  String get phyCategory => _firstNonEmptyString(<Object?>[
    data['phyCategory'],
    tongueReport['phyCategory'],
    analysisResult['phyCategory'],
  ]);

  bool get missingTongue {
    return analysisResult['success'] == true &&
        analysisResult['hasTongue'] == false;
  }
}

class ScanPalmUploadResult {
  const ScanPalmUploadResult(this.data);

  factory ScanPalmUploadResult.fromJson(Map<String, dynamic> json) {
    return ScanPalmUploadResult(Map<String, dynamic>.from(json));
  }

  final Map<String, dynamic> data;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

String _asString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

num? _asNum(Object? value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}

int? _firstInt(List<Object?> values) {
  for (final value in values) {
    final parsed = _asNum(value)?.toInt();
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

String _firstNonEmptyString(List<Object?> values) {
  for (final value in values) {
    final parsed = _asString(value).trim();
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }
  return '';
}
