# BlazeFleet iOS — Native Fleet Monitoring Application 🛰️📱

Aplicación nativa en **Swift (SwiftUI / iOS 17+)** diseñada con la identidad visual corporativa de BlazeFleet para la monitorización en tiempo real, telemetría satelital y control de flotas vehiculares en República Dominicana y Latinoamérica.

---

## 🚀 Características Principales

- **🛰️ Monitoreo Satelital en Tiempo Real**:
  - Transmisión continua vía **WebSocket v2** (`/ws/live?ticket={ticket}&v=2`).
  - Animación suave de posición, azimut (rumbo en grados) y velocidad.
  - Indicador de ignición en vivo (encendido/apagado/ralentí/sin señal).
- **🗺️ Mapa Interactivo Nativo (MapKit / Custom Basemaps)**:
  - Marcadores de diseño corporativo con halos de movimiento y chevron de rumbo.
  - Ajuste inteligente de encuadre de la flota completa (*Fit Fleet*).
  - Hoja inferior deslizante (*Slide-over card*) con telemetría de la unidad seleccionada.
- **🛡️ Inmovilizador & Comandos Remotos con Biometría**:
  - Apagado remoto de motor (`engine_stop`) protegido con **Face ID / Touch ID** (`LocalAuthentication`).
  - Habilitación de encendido (`engine_resume`).
  - Auditoría de despacho conectada a `/api/v1/mobile/vehicles/{id}/command`.
- **🔔 Notificaciones Push Nativas (APNs)**:
  - Registro automático de APNs device token en `/api/v1/mobile/push-token`.
  - Alertas instantáneas de Botón de Pánico (SOS), Entrada/Salida de Geocercas, Corte de Energía y Exceso de Velocidad.
  - Navegación directa (*Deep Link*) desde la notificación hacia la unidad en el mapa.
- **🔐 Seguridad y Autenticación**:
  - Gestión de tokens JWT en el **iOS Keychain** del dispositivo.
  - Renovación automática de sesión (*Silent Token Refresh*) con ventana de gracia anti-colisión de 60 segundos.

---

## 🏗️ Arquitectura de la Aplicación

La aplicación implementa el patrón **MVVM (Model-View-ViewModel)** reactivo impulsado por Swift Modern Concurrency (`async/await`) y `Combine`:

```
apps/ios/BlazeFleet/
├── App/
│   ├── BlazeFleetApp.swift            # Punto de entrada y temas globales
│   └── AppDelegate.swift              # Manejo de APNs y ciclo de vida de push
├── Models/
│   ├── AuthResponse.swift             # DTOs de login, sesión y WS ticket
│   ├── LivePosition.swift             # Modelo de telemetría de posición GPS
│   ├── FleetSummary.swift             # Resumen rápido de flota y contadores
│   └── NotificationItem.swift         # Modelo de alerta push / evento
├── Services/
│   ├── APIClient.swift                # Cliente HTTP async/await con refresh de token
│   ├── WebSocketService.swift         # Cliente URLSessionWebSocketTask con ping/backoff
│   ├── KeychainManager.swift          # Almacenamiento seguro en Secure Enclave
│   ├── PushNotificationManager.swift  # Registro APNs y delegado UNUserNotificationCenter
│   └── BiometricAuthService.swift     # Autenticación Face ID / Touch ID
├── ViewModels/
│   ├── AuthViewModel.swift            # Estado de autenticación y sesión
│   ├── FleetViewModel.swift           # Búsqueda, filtros y fusión de telemetría WS
│   └── VehicleDetailViewModel.swift   # Telemetría de unidad y despacho de comandos
└── Views/
    ├── Auth/LoginView.swift           # Pantalla de inicio de sesión y config de servidor
    ├── Map/LiveMapView.swift          # Mapa en vivo MapKit
    ├── Fleet/FleetListView.swift      # Listado de unidades con filtros y sparklines
    ├── Detail/VehicleDetailView.swift # Ficha de unidad, indicadores y comandos
    ├── Alerts/AlertsListView.swift    # Feed de alertas en tiempo real
    └── Components/                    # Tokens de diseño BlazeTheme, StatusChip, etc.
```

---

## 🛠️ Requisitos de Compilación

- **macOS Sonoma 14.0+**
- **Xcode 15.0+** (recomendado Xcode 16)
- **iOS 17.0+** como target de despliegue
- **Swift 5.9+** / Swift 6

---

## ⚙️ Configuración del Servidor

Por defecto, la app conecta con el entorno de producción en `https://fleet.blaze.do`.
Para apuntar a un entorno de desarrollo local o staging:
1. En la pantalla de login, toca el botón inferior **"Servidor: fleet.blaze.do"**.
2. Ingresa la URL de tu API (ej. `http://192.168.1.100:8080`).
3. Toca **Guardar**.

---

## 📱 Permisos del Sistema (`Info.plist`)

- `NSFaceIDUsageDescription`: Requerido para autorizar comandos críticos de seguridad (corte de motor).
- `NSLocationWhenInUseUsageDescription`: Requerido para centrar el mapa y calcular distancias hacia las unidades.
- `UIBackgroundModes`: Incluye `remote-notification` para recepción de alertas de pánico en segundo plano.
