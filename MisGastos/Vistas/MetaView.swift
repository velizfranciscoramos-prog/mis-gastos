import SwiftUI

struct MetaView: View {
    @EnvironmentObject var store: Store
    @State private var nombre = ""
    @State private var objetivo = ""
    @State private var ahorrado = ""
    @State private var aporte = ""

    var body: some View {
        NavigationStack {
            Form {
                if let meta = store.meta {
                    Section {
                        TarjetaMeta(meta: meta)
                            .listRowInsets(EdgeInsets())
                    }

                    Section("Sumar ahorro") {
                        HStack {
                            TextField("$0", text: $aporte)
                                .keyboardType(.numberPad)
                            Button("Sumar") {
                                let suma = meta.ahorrado + Formato.soloDigitos(aporte)
                                Task {
                                    await store.guardarMeta(nombre: meta.nombre, objetivo: meta.objetivo, ahorrado: suma)
                                    aporte = ""
                                    rellenar()
                                }
                            }
                            .buttonStyle(.borderless)
                            .disabled(Formato.soloDigitos(aporte) == 0)
                        }
                    }

                    Section("Editar meta") {
                        TextField("Nombre", text: $nombre)
                        LabeledContent("Objetivo") {
                            TextField("$0", text: $objetivo)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        LabeledContent("Ahorrado") {
                            TextField("$0", text: $ahorrado)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        Button("Guardar cambios") {
                            Task {
                                await store.guardarMeta(
                                    nombre: nombre.trimmingCharacters(in: .whitespacesAndNewlines),
                                    objetivo: Formato.soloDigitos(objetivo),
                                    ahorrado: Formato.soloDigitos(ahorrado)
                                )
                            }
                        }
                        .disabled(nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Formato.soloDigitos(objetivo) == 0)
                    }
                } else {
                    Text("Todavía no hay una meta de ahorro.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Meta de ahorro")
            .onAppear { rellenar() }
        }
    }

    private func rellenar() {
        guard let meta = store.meta else { return }
        nombre = meta.nombre
        objetivo = Formato.miles(meta.objetivo)
        ahorrado = Formato.miles(meta.ahorrado)
    }
}

struct AjustesView: View {
    @EnvironmentObject var store: Store

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuenta") {
                    Button("Cerrar sesión", role: .destructive) {
                        store.salir()
                    }
                }
                Section {
                    LabeledContent("Versión", value: version)
                } footer: {
                    Text("Tus datos están guardados en Supabase. Claude puede verlos y editarlos cuando se lo pidas en el chat.")
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
