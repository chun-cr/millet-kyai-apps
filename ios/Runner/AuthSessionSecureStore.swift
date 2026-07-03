import Foundation
import Security

final class AuthSessionSecureStore {
  static let shared = AuthSessionSecureStore()

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

    let object = try JSONSerialization.jsonObject(with: data)
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
