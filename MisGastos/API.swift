import Foundation

struct APIError: LocalizedError {
    let mensaje: String
    var errorDescription: String? { mensaje }
}

struct Sesion: Codable {
    var accessToken: String
    var refreshToken: String
    var expiraEn: Date
}

private struct TokenRespuesta: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
}

/// Conexión directa con Supabase (login + base de datos) usando su API REST.
final class API {
    static let shared = API()

    private let claveSesion = "sesion"
    private(set) var sesion: Sesion?

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    init() {
        if let datos = Keychain.leer(claveSesion),
           let s = try? JSONDecoder().decode(Sesion.self, from: datos) {
            sesion = s
        }
    }

    var conectado: Bool { sesion != nil }

    // MARK: - Cuenta

    func entrar(email: String, clave: String) async throws {
        let r: TokenRespuesta = try await auth("token?grant_type=password", ["email": email, "password": clave])
        try guardar(r)
    }

    /// Devuelve true si quedó con la sesión iniciada; false si Supabase pide confirmar el correo.
    func crearCuenta(email: String, clave: String) async throws -> Bool {
        let r: TokenRespuesta = try await auth("signup", ["email": email, "password": clave])
        if r.accessToken != nil {
            try guardar(r)
            return true
        }
        return false
    }

    func salir() {
        sesion = nil
        Keychain.borrar(claveSesion)
    }

    private func refrescar() async throws {
        guard let s = sesion else { throw APIError(mensaje: "Inicia sesión de nuevo.") }
        do {
            let r: TokenRespuesta = try await auth("token?grant_type=refresh_token", ["refresh_token": s.refreshToken])
            try guardar(r)
        } catch {
            salir()
            throw APIError(mensaje: "Tu sesión venció. Inicia sesión de nuevo.")
        }
    }

    private func guardar(_ r: TokenRespuesta) throws {
        guard let acceso = r.accessToken, let refresco = r.refreshToken else {
            throw APIError(mensaje: "Respuesta de inicio de sesión inválida.")
        }
        let s = Sesion(
            accessToken: acceso,
            refreshToken: refresco,
            expiraEn: Date().addingTimeInterval(TimeInterval(r.expiresIn ?? 3600))
        )
        sesion = s
        if let datos = try? JSONEncoder().encode(s) {
            Keychain.guardar(datos, clave: claveSesion)
        }
    }

    private func token() async throws -> String {
        guard let s = sesion else { throw APIError(mensaje: "Inicia sesión de nuevo.") }
        if s.expiraEn.timeIntervalSinceNow < 60 {
            try await refrescar()
        }
        guard let t = sesion?.accessToken else { throw APIError(mensaje: "Inicia sesión de nuevo.") }
        return t
    }

    private func auth<T: Decodable>(_ ruta: String, _ cuerpo: [String: String]) async throws -> T {
        guard let url = URL(string: Config.supabaseURL + "/auth/v1/" + ruta) else {
            throw APIError(mensaje: "Dirección inválida.")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(Config.supabaseKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: cuerpo)
        let datos = try await ejecutar(req)
        return try decoder.decode(T.self, from: datos)
    }

    // MARK: - Base de datos

    func leer<T: Decodable>(_ tabla: String, _ query: [URLQueryItem] = []) async throws -> [T] {
        let datos = try await rest("GET", tabla, query, cuerpo: nil, prefer: nil)
        return try decoder.decode([T].self, from: datos)
    }

    func insertar<T: Decodable>(_ tabla: String, _ cuerpo: any Encodable) async throws -> T {
        let json = try encoder.encode(cuerpo)
        let datos = try await rest("POST", tabla, [], cuerpo: json, prefer: "return=representation")
        let filas = try decoder.decode([T].self, from: datos)
        guard let primera = filas.first else { throw APIError(mensaje: "No se pudo guardar.") }
        return primera
    }

    func actualizar(_ tabla: String, id: UUID, _ cambios: [String: Any]) async throws {
        let json = try JSONSerialization.data(withJSONObject: cambios)
        _ = try await rest("PATCH", tabla, [filtroId(id)], cuerpo: json, prefer: "return=minimal")
    }

    func borrar(_ tabla: String, id: UUID) async throws {
        _ = try await rest("DELETE", tabla, [filtroId(id)], cuerpo: nil, prefer: "return=minimal")
    }

    private func filtroId(_ id: UUID) -> URLQueryItem {
        URLQueryItem(name: "id", value: "eq." + id.uuidString.lowercased())
    }

    private func rest(_ metodo: String, _ tabla: String, _ query: [URLQueryItem], cuerpo: Data?, prefer: String?) async throws -> Data {
        guard var comp = URLComponents(string: Config.supabaseURL + "/rest/v1/" + tabla) else {
            throw APIError(mensaje: "Dirección inválida.")
        }
        if !query.isEmpty { comp.queryItems = query }
        guard let url = comp.url else { throw APIError(mensaje: "Dirección inválida.") }

        let t = try await token()
        var req = URLRequest(url: url)
        req.httpMethod = metodo
        req.setValue(Config.supabaseKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer " + t, forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let prefer = prefer { req.setValue(prefer, forHTTPHeaderField: "Prefer") }
        req.httpBody = cuerpo
        return try await ejecutar(req)
    }

    private func ejecutar(_ req: URLRequest) async throws -> Data {
        let resultado: (Data, URLResponse)
        do {
            resultado = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError(mensaje: "Sin conexión. Revisa tu internet e intenta de nuevo.")
        }
        let (datos, respuesta) = resultado
        let codigo = (respuesta as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(codigo) else {
            var mensaje = "Error \(codigo)"
            if let obj = try? JSONSerialization.jsonObject(with: datos) as? [String: Any] {
                for k in ["msg", "message", "error_description", "error"] {
                    if let m = obj[k] as? String { mensaje = m; break }
                }
            }
            throw APIError(mensaje: API.traducir(mensaje))
        }
        return datos
    }

    private static func traducir(_ m: String) -> String {
        switch m {
        case "Invalid login credentials": return "Correo o clave incorrectos."
        case "Email not confirmed": return "Primero confirma tu correo (revisa tu bandeja de entrada)."
        case "User already registered": return "Ya existe una cuenta con ese correo. Usa Entrar."
        default: return m
        }
    }
}
