// 视觉能力提供层。通过 Riverpod 向扫描页面暴露共享的视觉管理器和依赖入口。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/vision_manager.dart';
import '../../domain/models/vision_models.dart';

final visionManagerProvider = Provider<VisionManager>((ref) {
  final manager = VisionManager();
  ref.onDispose(() {
    manager.stopDetection(VisionMode.all);
  });
  return manager;
});

final visionStateProvider = NotifierProvider<VisionStateNotifier, VisionState>(() {
  return VisionStateNotifier();
});

class VisionStateNotifier extends Notifier<VisionState> {
  @override
  VisionState build() {
    return const VisionState(mode: VisionMode.faceOnly, isDetecting: false);
  }

  Future<void> setMode(VisionMode mode) async {
    if (state.mode == mode) return;
    await ref.read(visionManagerProvider).stopDetection(state.mode);
    state = state.copyWith(mode: mode, isDetecting: false);
  }

  Future<void> start() async {
    await ref.read(visionManagerProvider).startDetection(state.mode);
    state = state.copyWith(isDetecting: true);
  }

  Future<void> stop() async {
    await ref.read(visionManagerProvider).stopDetection(state.mode);
    state = state.copyWith(isDetecting: false);
  }
}

final faceLandmarkStreamProvider = StreamProvider<FaceLandmarkData>((ref) {
  return ref.read(visionManagerProvider).faceLandmarkStream;
});

final gestureStreamProvider = StreamProvider<GestureResult>((ref) {
  return ref.read(visionManagerProvider).gestureStream;
});

final tongueStreamProvider = StreamProvider<TongueDetectionResult>((ref) {
  return ref.read(visionManagerProvider).tongueStream;
});
