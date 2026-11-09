import SwiftUI

/// Estado de la app: categorías, movimientos del mes y meta de ahorro.
@MainActor
final class Store: ObservableObject {
    @Published var conectado = API.shared.conectado
    @Published var categorias: [Categoria] = []
    @Published var movimientos: [Movimiento] = []
    @Published var meta: Meta?
    @Published var mes = Formato.inicioMes(Date())
    @Published var error: String?

    // MARK: - Cargar

    func cargarTodo() async {
        do {
            categorias = try await API.shared.leer("categorias", [
                URLQueryItem(name: "activa", value: "eq.true"),
                URLQueryItem(name: "order", value: "orden"),
            ])
            let metas: [Meta] = try await API.shared.leer("metas", [
                URLQueryItem(name: "activa", value: "eq.true"),
                URLQueryItem(name: "order", value: "creado.desc"),
                URLQueryItem(name: "limit", value: "1"),
            ])
            meta = metas.first
            try await cargarMes()
        } catch {
            manejar(error)
        }
    }

    func cargarMes() async throws {
        let inicio = Formato.dia(mes)
        let siguiente = Formato.calendario.date(byAdding: .month, value: 1, to: mes) ?? mes
        let fin = Formato.dia(siguiente)
        movimientos = try await API.shared.leer("movimientos", [
            URLQueryItem(name: "fecha", value: "gte." + inicio),
            URLQueryItem(name: "fecha", value: "lt." + fin),
            URLQueryItem(name: "order", value: "fecha.desc,creado.desc"),
        ])
    }

    func cambiarMes(_ delta: Int) {
        mes = Formato.calendario.date(byAdding: .month, value: delta, to: mes) ?? mes
        Task {
            do { try await cargarMes() } catch { manejar(error) }
        }
    }

    // MARK: - Cambios

    func agregar(_ nuevo: NuevoMovimiento) async -> Bool {
        do {
            let m: Movimiento = try await API.shared.insertar("movimientos", nuevo)
            let prefijoMes = String(Formato.dia(mes).prefix(7))
            if m.fecha.hasPrefix(prefijoMes) {
                movimientos.append(m)
                ordenar()
            }
            return true
        } catch {
            manejar(error)
            return false
        }
    }

    func borrar(_ m: Movimiento) async {
        do {
            try await API.shared.borrar("movimientos", id: m.id)
            movimientos.removeAll { $0.id == m.id }
        } catch {
            manejar(error)
        }
    }

    func marcarPagado(_ m: Movimiento) async {
        do {
            try await API.shared.actualizar("movimientos", id: m.id, [
                "estado": "hecho",
                "fecha": Formato.dia(Date()),
            ])
            try await cargarMes()
        } catch {
            manejar(error)
        }
    }

    func guardarMeta(nombre: String, objetivo: Int, ahorrado: Int) async {
        guard let actual = meta else { return }
        do {
            try await API.shared.actualizar("metas", id: actual.id, [
                "nombre": nombre,
                "objetivo": objetivo,
                "ahorrado": ahorrado,
            ])
            meta?.nombre = nombre
            meta?.objetivo = objetivo
            meta?.ahorrado = ahorrado
        } catch {
            manejar(error)
        }
    }

    func salir() {
        API.shared.salir()
        conectado = false
        movimientos = []
        categorias = []
        meta = nil
    }

    private func manejar(_ e: Error) {
        if !API.shared.conectado { conectado = false }
        error = e.localizedDescription
    }

    private func ordenar() {
        movimientos.sort { ($0.fecha, $0.creado) > ($1.fecha, $1.creado) }
    }

    // MARK: - Cálculos del mes

    var ingresos: Int {
        movimientos.filter { $0.tipo == "ingreso" }.reduce(0) { $0 + $1.monto }
    }

    var gastado: Int {
        movimientos.filter { $0.tipo == "gasto" && $0.estado == "hecho" }.reduce(0) { $0 + $1.monto }
    }

    var porPagar: Int {
        movimientos.filter { $0.estado == "pendiente" }.reduce(0) { $0 + $1.monto }
    }

    var disponible: Int { ingresos - gastado - porPagar }

    func categoria(_ id: UUID?) -> Categoria? {
        guard let id = id else { return nil }
        return categorias.first { $0.id == id }
    }

    var gastoPorCategoria: [FilaCategoria] {
        var totales: [UUID?: Int] = [:]
        for m in movimientos where m.tipo == "gasto" && m.estado == "hecho" {
            totales[m.categoriaId, default: 0] += m.monto
        }
        return totales.map { par -> FilaCategoria in
            let c = categoria(par.key)
            return FilaCategoria(
                id: par.key?.uuidString ?? "sin-categoria",
                nombre: c?.nombre ?? "Sin categoría",
                icono: c?.icono ?? "questionmark.circle",
                color: Color(hex: c?.color ?? "#76807B"),
                total: par.value
            )
        }
        .sorted { $0.total > $1.total }
    }
}
