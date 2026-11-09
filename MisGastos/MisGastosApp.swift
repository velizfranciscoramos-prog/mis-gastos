import SwiftUI

@main
struct MisGastosApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        Group {
            if store.conectado {
                TabView {
                    ResumenView()
                        .tabItem { Label("Resumen", systemImage: "chart.pie.fill") }
                    MovimientosView()
                        .tabItem { Label("Movimientos", systemImage: "list.bullet") }
                    MetaView()
                        .tabItem { Label("Meta", systemImage: "target") }
                    AjustesView()
                        .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
                }
                .task { await store.cargarTodo() }
            } else {
                LoginView()
            }
        }
        .tint(Color(hex: "#2C5E4F"))
        .alert(
            "Algo falló",
            isPresented: Binding(
                get: { store.error != nil },
                set: { if !$0 { store.error = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.error ?? "")
        }
    }
}
