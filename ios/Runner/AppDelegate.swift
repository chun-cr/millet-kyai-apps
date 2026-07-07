import Flutter
import Security
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
          result(try AppAuthSessionStore.shared.readAll())
        case "writeAll":
          guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing auth session payload", details: nil))
            return
          }
          try AppAuthSessionStore.shared.writeAll(args)
          result(nil)
        case "clear":
          try AppAuthSessionStore.shared.clear()
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

private final class AppAuthSessionStore {
  static let shared = AppAuthSessionStore()

  private let service = "com.permillet.myapp.auth-session"
  private let account = "default"

  private init() {}

  func readAll() throws -> [String: Any]? {
    var query = baseQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound {
      return nil
    }
    guard status == errSecSuccess else {
      throw NSError(
        domain: NSOSStatusErrorDomain,
        code: Int(status),
        userInfo: [NSLocalizedDescriptionKey: "Unable to read secure auth session."]
      )
    }
    guard let data = item as? Data else {
      return nil
    }

    let object = try JSONSerialization.jsonObject(with: data, options: [])
    return object as? [String: Any]
  }

  func writeAll(_ values: [String: Any]) throws {
    let data = try JSONSerialization.data(withJSONObject: values, options: [])
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    let updateStatus = SecItemUpdate(baseQuery() as CFDictionary, attributes as CFDictionary)
    if updateStatus == errSecSuccess {
      return
    }
    if updateStatus != errSecItemNotFound {
      throw NSError(
        domain: NSOSStatusErrorDomain,
        code: Int(updateStatus),
        userInfo: [NSLocalizedDescriptionKey: "Unable to update secure auth session."]
      )
    }

    var addQuery = baseQuery()
    attributes.forEach { addQuery[$0.key] = $0.value }
    let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw NSError(
        domain: NSOSStatusErrorDomain,
        code: Int(addStatus),
        userInfo: [NSLocalizedDescriptionKey: "Unable to persist secure auth session."]
      )
    }
  }

  func clear() throws {
    let status = SecItemDelete(baseQuery() as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw NSError(
        domain: NSOSStatusErrorDomain,
        code: Int(status),
        userInfo: [NSLocalizedDescriptionKey: "Unable to clear secure auth session."]
      )
    }
  }

  private func baseQuery() -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }
}
