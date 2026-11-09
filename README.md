# Mis Gastos

App de iPhone/iPad (SwiftUI) para registrar gastos, ingresos y la meta de ahorro. Los datos viven en Supabase (proyecto `mis-gastos`), así que se sincronizan entre dispositivos y Claude puede leerlos y editarlos.

## Cómo se compila

No hace falta Mac. Cada vez que se sube un cambio a la rama `main`, GitHub Actions:

1. genera el proyecto de Xcode con XcodeGen (`project.yml`),
2. compila la app sin firmar,
3. deja un archivo `MisGastos.ipa` para descargar en la pestaña **Actions** → la última ejecución → **Artifacts**.

## Cómo se instala (desde Windows)

1. Descarga `MisGastos-ipa` desde Actions y descomprímelo: queda `MisGastos.ipa`.
2. Abre **Sideloadly**, conecta el iPhone por cable, arrastra el `.ipa` y escribe tu Apple ID. Toca **Start**.
3. En el iPhone: Ajustes → Privacidad y seguridad → **Modo desarrollador** → activar (se reinicia).
4. Ajustes → General → **VPN y gestión de dispositivos** → tu Apple ID → **Confiar**.
5. Abre Mis Gastos y crea tu cuenta.

La firma con Apple ID gratis dura 7 días: para renovarla, vuelve a pasar el mismo `.ipa` con Sideloadly (los datos no se pierden porque están en Supabase).

## Estructura

- `project.yml`: configuración del proyecto (XcodeGen).
- `MisGastos/API.swift`: login y base de datos (API REST de Supabase).
- `MisGastos/Store.swift`: estado de la app y cálculos del mes.
- `MisGastos/Vistas/`: pantallas.
- `.github/workflows/compilar.yml`: compilación en la nube.
