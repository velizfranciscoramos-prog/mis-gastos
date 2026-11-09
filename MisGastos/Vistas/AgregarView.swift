import SwiftUI

struct AgregarView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var tipo = "gasto"          // "gasto", "ingreso" o "pendiente"
    @State private var montoTexto = ""
    @State private var categoriaId: UUID?
    @State private var descripcion = ""
    @State private var fecha = Date()
    @State private var guardando = false

    private var monto: Int { Formato.soloDigitos(montoTexto) }

    private var categoriasVisibles: [Categoria] {
        let buscado = tipo == "ingreso" ? "ingreso" : "gasto"
        return store.categorias.filter { $0.tipo == buscado }
    }

    private var titulo: String {
        switch tipo {
        case "ingreso": return "Nuevo ingreso"
        case "pendiente": return "Nuevo por pagar"
        default: return "Nuevo gasto"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Tipo", selection: $tipo) {
                    Text("Gasto").tag("gasto")
                    Text("Ingreso").tag("ingreso")
                    Text("Por pagar").tag("pendiente")
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                Section("Monto") {
                    TextField("$0", text: $montoTexto)
                        .keyboardType(.numberPad)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .onChange(of: montoTexto) { _, nuevo in
                            let n = Formato.soloDigitos(nuevo)
                            let formateado = n == 0 ? "" : Formato.miles(n)
                            if formateado != nuevo { montoTexto = formateado }
                        }
                }

                Section("Categoría") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                        ForEach(categoriasVisibles) { c in
                            BotonCategoria(c: c, elegida: categoriaId == c.id) {
                                categoriaId = c.id
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Detalle") {
                    TextField("Descripción (opcional)", text: $descripcion)
                    DatePicker("Fecha", selection: $fecha, displayedComponents: .date)
                }
            }
            .navigationTitle(titulo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await guardar() }
                    }
                    .disabled(monto == 0 || categoriaId == nil || guardando)
                }
            }
            .onChange(of: tipo) { _, _ in
                categoriaId = nil
            }
        }
    }

    private func guardar() async {
        guardando = true
        let texto = descripcion.trimmingCharacters(in: .whitespacesAndNewlines)
        let nuevo = NuevoMovimiento(
            tipo: tipo == "ingreso" ? "ingreso" : "gasto",
            estado: tipo == "pendiente" ? "pendiente" : "hecho",
            monto: monto,
            categoriaId: categoriaId,
            descripcion: texto.isEmpty ? nil : texto,
            comercio: nil,
            origen: "manual",
            fecha: Formato.dia(fecha)
        )
        let ok = await store.agregar(nuevo)
        guardando = false
        if ok { dismiss() }
    }
}
