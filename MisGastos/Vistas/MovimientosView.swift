import SwiftUI

struct MovimientosView: View {
    @EnvironmentObject var store: Store
    @State private var agregando = false

    private var grupos: [GrupoDia] {
        var orden: [String] = []
        var porDia: [String: [Movimiento]] = [:]
        for m in store.movimientos {
            if porDia[m.fecha] == nil { orden.append(m.fecha) }
            porDia[m.fecha, default: []].append(m)
        }
        return orden.map { GrupoDia(id: $0, items: porDia[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SelectorMes()
                }

                if store.movimientos.isEmpty {
                    Text("Sin movimientos este mes. Toca + para agregar uno.")
                        .foregroundStyle(.secondary)
                }

                ForEach(grupos) { grupo in
                    Section(Formato.tituloDia(grupo.id)) {
                        ForEach(grupo.items) { m in
                            FilaMovimiento(m: m)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await store.borrar(m) }
                                    } label: {
                                        Label("Borrar", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if m.estado == "pendiente" {
                                        Button {
                                            Task { await store.marcarPagado(m) }
                                        } label: {
                                            Label("Pagado", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Movimientos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        agregando = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Agregar movimiento")
                }
            }
            .sheet(isPresented: $agregando) {
                AgregarView()
            }
            .refreshable {
                await store.cargarTodo()
            }
        }
    }
}
