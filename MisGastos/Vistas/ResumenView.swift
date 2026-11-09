import SwiftUI

struct ResumenView: View {
    @EnvironmentObject var store: Store
    @State private var agregando = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SelectorMes()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disponible real")
                            .font(.subheadline)
                            .opacity(0.85)
                        Text(Formato.clp(store.disponible))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("Ingresos − gastos − lo que falta pagar")
                            .font(.caption)
                            .opacity(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .foregroundStyle(Color.white)
                    .background(Color(hex: "#2C5E4F"), in: RoundedRectangle(cornerRadius: 16))

                    HStack(spacing: 10) {
                        Cifra(titulo: "Ingresos", valor: store.ingresos, color: .green)
                        Cifra(titulo: "Gastado", valor: store.gastado, color: .red)
                        Cifra(titulo: "Por pagar", valor: store.porPagar, color: .orange)
                    }

                    if let meta = store.meta {
                        TarjetaMeta(meta: meta)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gasto por categoría")
                            .font(.headline)
                        let filas = store.gastoPorCategoria
                        if filas.isEmpty {
                            Text("Sin gastos este mes.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(filas) { fila in
                            BarraCategoria(fila: fila, maximo: filas.first?.total ?? 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Resumen")
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
