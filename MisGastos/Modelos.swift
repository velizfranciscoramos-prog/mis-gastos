import SwiftUI

struct Categoria: Codable, Identifiable, Hashable {
    let id: UUID
    var nombre: String
    var tipo: String        // "gasto" o "ingreso"
    var icono: String       // nombre de SF Symbol
    var color: String       // "#RRGGBB"
    var orden: Int
    var activa: Bool
}

struct Movimiento: Codable, Identifiable, Hashable {
    let id: UUID
    var tipo: String        // "gasto" o "ingreso"
    var estado: String      // "hecho" o "pendiente"
    var monto: Int
    var categoriaId: UUID?
    var descripcion: String?
    var comercio: String?
    var origen: String
    var fecha: String       // "yyyy-MM-dd"
    var creado: String
}

struct NuevoMovimiento: Encodable {
    var tipo: String
    var estado: String
    var monto: Int
    var categoriaId: UUID?
    var descripcion: String?
    var comercio: String?
    var origen: String
    var fecha: String
}

struct Meta: Codable, Identifiable {
    let id: UUID
    var nombre: String
    var objetivo: Int
    var ahorrado: Int
    var fechaLimite: String?
    var activa: Bool
}

struct FilaCategoria: Identifiable {
    let id: String
    let nombre: String
    let icono: String
    let color: Color
    let total: Int
}

struct GrupoDia: Identifiable {
    let id: String          // la fecha "yyyy-MM-dd"
    let items: [Movimiento]
}
