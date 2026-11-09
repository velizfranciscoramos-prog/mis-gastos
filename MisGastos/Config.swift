import Foundation

/// Datos de conexión a Supabase.
/// La clave "publishable" está hecha para ir dentro de la app: los datos
/// quedan protegidos por las reglas de la base (solo tu cuenta puede leerlos).
enum Config {
    static let supabaseURL = "https://uhevmndieoumjenrkedj.supabase.co"
    static let supabaseKey = "sb_publishable_WQ0CAhdUAUTO2G9v3jfNAw_oMyOeKYO"
}
