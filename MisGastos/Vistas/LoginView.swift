import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: Store
    @State private var email = ""
    @State private var clave = ""
    @State private var cargando = false
    @State private var mensaje: String?

    private var listo: Bool { !cargando && email.contains("@") && clave.count >= 6 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Correo", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Clave (mínimo 6 caracteres)", text: $clave)
                        .textContentType(.password)
                } footer: {
                    Text("Usa el mismo correo y clave en el iPhone y en el iPad.")
                }

                Section {
                    Button {
                        Task { await entrar() }
                    } label: {
                        HStack {
                            Text("Entrar")
                            Spacer()
                            if cargando { ProgressView() }
                        }
                    }
                    .disabled(!listo)

                    Button("Crear cuenta") {
                        Task { await crear() }
                    }
                    .disabled(!listo)
                }

                if let mensaje = mensaje {
                    Section {
                        Text(mensaje).font(.callout)
                    }
                }
            }
            .navigationTitle("Mis Gastos")
        }
    }

    private var correo: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func entrar() async {
        cargando = true
        mensaje = nil
        do {
            try await API.shared.entrar(email: correo, clave: clave)
            store.conectado = true
        } catch {
            mensaje = error.localizedDescription
        }
        cargando = false
    }

    private func crear() async {
        cargando = true
        mensaje = nil
        do {
            let entro = try await API.shared.crearCuenta(email: correo, clave: clave)
            if entro {
                store.conectado = true
            } else {
                mensaje = "Cuenta creada. Te llegó un correo de Supabase: ábrelo, confirma y vuelve aquí a tocar Entrar."
            }
        } catch {
            mensaje = error.localizedDescription
        }
        cargando = false
    }
}
