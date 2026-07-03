import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private func readDouble(_ value: Any?) -> Double? {
    if let doubleValue = value as? Double {
      return doubleValue
    }
    if let numberValue = value as? NSNumber {
      return numberValue.doubleValue
    }
    return nil
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let scanRegistrar = registrar(forPlugin: "FaceLandmarkerViewFactory")!
    scanRegistrar.register(FaceLandmarkerViewFactory.shared, withId: "com.yourapp.face_scan/camera_preview")

    let faceChannel = FlutterEventChannel(
      name: "face/landmarkStream",
      binaryMessenger: scanRegistrar.messenger()
    )
    faceChannel.setStreamHandler(FaceScanStatusStreamHandler.shared)

    let gestureChannel = FlutterEventChannel(
      name: "gesture/resultStream",
      binaryMessenger: scanRegistrar.messenger()
    )
    gestureChannel.setStreamHandler(GestureStreamHandler.shared)

    let tongueChannel = FlutterEventChannel(
      name: "tongue/detectionStream",
      binaryMessenger: scanRegistrar.messenger()
    )
    tongueChannel.setStreamHandler(TongueDetectionStreamHandler.shared)

    let methodChannel = FlutterMethodChannel(
      name: "face/channel",
      binaryMessenger: scanRegistrar.messenger()
    )
    methodChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "face/startDetection":
        // start 命令走 perform()，view 不存在时进入 pending 队列
        FaceLandmarkerViewFactory.shared.perform(.startFace)
        result(nil)

      case "face/stopDetection":
        // ★ stop 命令改走 performStop()，view 不存在时直接丢弃，不写入 pending
        FaceLandmarkerViewFactory.shared.performStop(mode: "face")
        result(nil)

      case "tongue/startDetection":
        FaceLandmarkerViewFactory.shared.perform(.startTongue)
        result(nil)

      case "tongue/stopDetection":
        // ★ 同上
        FaceLandmarkerViewFactory.shared.performStop(mode: "tongue")
        result(nil)

      case "gesture/startDetection":
        FaceLandmarkerViewFactory.shared.perform(.startGesture)
        result(nil)

      case "gesture/stopDetection":
        FaceLandmarkerViewFactory.shared.performStop(mode: "gesture")
        result(nil)

      case "face/toggleCamera":
        CameraManager.shared.toggleCamera()
        result(nil)

      case "scan/capture":
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing capture args", details: nil))
          return
        }
        guard let stage = args["stage"] as? String, !stage.isEmpty else {
          result(FlutterError(code: "INVALID_STAGE", message: "Missing capture stage", details: args))
          return
        }
        guard
          let guideRect = args["guideRect"] as? [String: Any],
          let left = self.readDouble(guideRect["left"]),
          let top = self.readDouble(guideRect["top"]),
          let width = self.readDouble(guideRect["width"]),
          let height = self.readDouble(guideRect["height"])
        else {
          result(FlutterError(code: "INVALID_GUIDE_RECT", message: "Missing or invalid guideRect", details: args))
          return
        }
        guard let view = FaceLandmarkerViewFactory.shared.currentView else {
          result(FlutterError(code: "NO_VIEW", message: "No active camera view", details: nil))
          return
        }

        view.captureVisibleRegion(
          stage: stage,
          normalizedRect: CGRect(x: left, y: top, width: width, height: height)
        ) { payload in
          result(payload)
        } onError: { err in
          result(FlutterError(code: "CAPTURE_FAILED", message: err, details: args))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
    let appInfoChannel = FlutterMethodChannel(
      name: "app/info",
      binaryMessenger: scanRegistrar.messenger()
    )
    appInfoChannel.setMethodCallHandler { call, result in
      if call.method == "getAppId" {
        result("com.permillet.myapp.dev")
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let authSessionChannel = FlutterMethodChannel(
      name: "auth/session",
      binaryMessenger: scanRegistrar.messenger()
    )
    authSessionChannel.setMethodCallHandler { call, result in
      do {
        switch call.method {
        case "readAll":
          result(try AuthSessionSecureStore.shared.readAll())
        case "writeAll":
          guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing auth session payload", details: nil))
            return
          }
          try AuthSessionSecureStore.shared.writeAll(args)
          result(nil)
        case "clear":
          try AuthSessionSecureStore.shared.clear()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "SECURE_STORAGE_ERROR", message: error.localizedDescription, details: nil))
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
