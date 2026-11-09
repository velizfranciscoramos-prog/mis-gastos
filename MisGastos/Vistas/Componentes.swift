import SwiftUI

struct SelectorMes: View {
    @EnvironmentObject var store: Store

    var body: some View {
        HStack {
            Button {
                store.cambiarMes(-1)
            } label: {
                Image(systemName: "chevron.left").padding(8)
            }
            Spacer()
            Text(Formato.mesLargo.string(from: store.mes).capitalized)
                .font(.headline)
            Spacer()
            Button {
                store.cambiarMes(1)
            } label: {
                Image(systemName: "chevron.right").padding(8)
            }
        }
        .buttonStyle(.borderless)
    }
}

struct Cifra: View {
    let titulo: String
    let valor: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titulo)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Formato.clp(valor))
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TarjetaMeta: View {
    let meta: Meta

    private var progreso: Double {
        min(1, Double(meta.ahorrado) / Double(max(meta.objetivo, 1)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(meta.nombre, systemImage: "target")
                    .font(.headline)
                Spacer()
                Text("\(Int(progreso * 100))%")
                    .font(.subheadline.monospacedDigit())
            }
            ProgressView(value: progreso)
            Text("\(Formato.clp(meta.ahorrado)) de \(Formato.clp(meta.objetivo)) · faltan \(Formato.clp(max(0, meta.objetivo - meta.ahorrado)))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct BarraCategoria: View {
    let fila: FilaCategoria
    let maximo: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(fila.nombre, systemImage: fila.icono)
                    .font(.subheadline)
                Spacer()
                Text(Formato.clp(fila.total))
                    .font(.subheadline.monospacedDigit())
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(fila.color)
                        .frame(width: max(6, g.size.width * CGFloat(fila.total) / CGFloat(max(maximo, 1))))
                }
            }
            .frame(height: 8)
        }
    }
}

struct FilaMovimiento: View {
    @EnvironmentObject var store: Store
    let m: Movimiento

    private var colorMonto: Color {
        if m.tipo == "ingreso" { return Color.green }
        if m.estado == "pendiente" { return Color.orange }
        return Color.primary
    }

    var body: some View {
        let cat = store.categoria(m.categoriaId)
        HStack(spacing: 12) {
            Image(systemName: cat?.icono ?? "questionmark.circle")
                .font(.subheadline)
                .foregroundStyle(Color.white)
                .frame(width: 34, height: 34)
                .background(Color(hex: cat?.color ?? "#76807B"), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(titulo(cat))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(cat?.nombre ?? "Sin categoría")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if m.estado == "pendiente" {
                        Text("POR PAGAR")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.orange, in: Capsule())
                            .foregroundStyle(Color.white)
                    }
                }
            }

            Spacer()

            Text((m.tipo == "ingreso" ? "+" : "−") + Formato.clp(m.monto))
                .font(.body.monospacedDigit())
                .foregroundStyle(colorMonto)
        }
    }

    private func titulo(_ cat: Categoria?) -> String {
        if let d = m.descripcion, !d.isEmpty { return d }
        if let c = m.comercio, !c.isEmpty { return c }
        return cat?.nombre ?? "Movimiento"
    }
}

struct BotonCategoria: View {
    let c: Categoria
    let elegida: Bool
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            VStack(spacing: 6) {
                Image(systemName: c.icono)
                    .font(.title3)
                Text(c.nombre)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(6)
            .background(
                elegida ? Color(hex: c.color) : Color(.tertiarySystemFill),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundStyle(elegida ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}
