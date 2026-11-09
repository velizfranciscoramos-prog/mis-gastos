import Foundation
import Security

/// Guarda la sesión de forma segura en el llavero del iPhone.
enum Keychain {
    private static let servicio = "com.francisco.misgastos"

    private static func consulta(_ clave: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicio,
            kSecAttrAccount as String: clave,
        ]
    }

    static func guardar(_ datos: Data, clave: String) {
        SecItemDelete(consulta(clave) as CFDictionary)
        var nuevo = consulta(clave)
        nuevo[kSecValueData as String] = datos
        nuevo[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(nuevo as CFDictionary, nil)
    }

    static func leer(_ clave: String) -> Data? {
        var q = consulta(clave)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var resultado: AnyObject?
        let estado = SecItemCopyMatching(q as CFDictionary, &resultado)
        return estado == errSecSuccess ? resultado as? Data : nil
    }

    static func borrar(_ clave: String) {
        SecItemDelete(consulta(clave) as CFDictionary)
    }
}
