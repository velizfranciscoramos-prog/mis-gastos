import SwiftUI

enum Formato {
    static let zona = TimeZone(identifier: "America/Santiago") ?? .current

    static var calendario: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = zona
        return c
    }

    private static let pesos: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "es_CL")
        f.currencyCode = "CLP"
        f.maximumFractionDigits = 0
        return f
    }()

    private static let enteros: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "es_CL")
        f.maximumFractionDigits = 0
        return f
    }()

    private static let isoDia: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = zona
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let mesLargo: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CL")
        f.timeZone = zona
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private static let diaLargo: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CL")
        f.timeZone = zona
        f.dateFormat = "EEEE d 'de' MMMM"
        return f
    }()

    /// 6000 -> "$6.000"
    static func clp(_ n: Int) -> String {
        pesos.string(from: NSNumber(value: n)) ?? "$\(n)"
    }

    /// 6000 -> "6.000"
    static func miles(_ n: Int) -> String {
        enteros.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    /// "6.000" -> 6000
    static func soloDigitos(_ s: String) -> Int {
        Int(s.filter { $0.isASCII && $0.isNumber }) ?? 0
    }

    static func dia(_ d: Date) -> String {
        isoDia.string(from: d)
    }

    static func tituloDia(_ s: String) -> String {
        guard let d = isoDia.date(from: s) else { return s }
        return diaLargo.string(from: d).capitalized
    }

    static func inicioMes(_ d: Date) -> Date {
        let c = calendario
        return c.date(from: c.dateComponents([.year, .month], from: d)) ?? d
    }
}

extension Color {
    init(hex: String) {
        let limpio = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: limpio).scanHexInt64(&v)
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
