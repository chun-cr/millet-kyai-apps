import Foundation

enum ModelAssetLocator {
    static func pathInBundle(name: String, ext: String) -> String? {
        let fileName = "\(name).\(ext)"
        print("ModelAssetLocator: looking for \(fileName)")

        // 1. 先找原生 Bundle（Copy Bundle Resources）
        if let nativePath = Bundle.main.path(forResource: name, ofType: ext) {
            print("ModelAssetLocator: ✅ found in native bundle: \(nativePath)")
            return nativePath
        }

        // 2. 再找 Flutter App.framework 里的 assets
        if let appBundle = Bundle(identifier: "io.flutter.flutter.app") ??
                           Bundle.allFrameworks.first(where: { $0.bundlePath.contains("App.framework") }) {
            if let flutterPath = appBundle.path(
                forResource: name,
                ofType: ext,
                inDirectory: "flutter_assets/assets/models"
            ) {
                print("ModelAssetLocator: ✅ found in App.framework: \(flutterPath)")
                return flutterPath
            }
        }

        // 3. 直接扫描主 bundle 中的 Frameworks/App.framework/flutter_assets
        let mainBundlePath = Bundle.main.bundlePath
        let directPath = mainBundlePath + "/Frameworks/App.framework/flutter_assets/assets/models/" + fileName
        if FileManager.default.fileExists(atPath: directPath) {
            print("ModelAssetLocator: ✅ found by direct path: \(directPath)")
            return directPath
        }

        // 4. 搜索主 bundle 下所有可能路径
        let searchPaths = [
            mainBundlePath + "/flutter_assets/assets/models/" + fileName,
            mainBundlePath + "/assets/models/" + fileName,
        ]
        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("ModelAssetLocator: ✅ found at: \(path)")
                return path
            }
        }

        print("ModelAssetLocator: ❌ \(fileName) not found anywhere")
        return nil
    }
}