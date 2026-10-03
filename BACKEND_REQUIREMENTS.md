# 🛰️ Requerimientos Técnicos del Backend para BlazeFleet iOS
**Para el Equipo de Ingeniería Backend de BlazeFleet**  
**Fecha:** Octubre 2026  
**Cliente / Flota de Referencia:** Telemarch Dominicana (`flotillas@telemarch.com.do`)  
**Aplicación:** BlazeFleet iOS (SwiftUI / Native iOS 17.0+)  
**Bundle ID:** `do.blaze.fleet` | **TestFlight ID:** `6818666254`  

---

## 1. Resumen Ejecutivo
Durante las pruebas de validación en vivo con la cuenta de producción de **Telemarch** (5 unidades operativas en Santiago de los Caballeros: *L507135*, *L479635*, *L497462*, *I119573*, *I132236*), la aplicación iOS ha sido pulida y optimizada para uso continuo en tiempo real con WebSocket nativo y MapKit.

Para completar el ciclo de producción al 100% y garantizar la mejor experiencia operativa diaria, a continuación se detallan los endpoints, payloads y contratos de datos requeridos del lado del backend.

---

## 2. Requerimientos de Alta Prioridad

### 2.1 Registro y Despacho de Notificaciones Push (APNs)
La aplicación iOS ya cuenta con los delegates del sistema para capturar el token de APNs (`UNUserNotificationCenter` y `didRegisterForRemoteNotificationsWithDeviceToken`).

#### Endpoint Requerido:
```http
POST /api/v1/mobile/push-token
Authorization: Bearer <access_token>
Content-Type: application/json
```

#### Payload Enviado por iOS:
```json
{
  "device_token": "740f4707bebcf74f9b7c25d48e3358945f6aa01da5ddb387462c7eaf61bb78ad",
  "platform": "ios",
  "bundle_id": "do.blaze.fleet",
  "app_version": "1.0.0",
  "environment": "production" // o "sandbox" en Debug
}
```

#### Formato de Payload APNs requerido al despachar alertas:
```json
{
  "aps": {
    "alert": {
      "title": "🚨 Alerta de Pánico: L507135",
      "body": "El conductor Bryan Peguero ha presionado el botón de pánico en Licey al Medio."
    },
    "sound": "default",
    "badge": 1,
    "category": "VEHICLE_ALERT",
    "mutable-content": 1
  },
  "vehicle_id": "019ef118-066d-707d-9f6a-1ba3047afee3",
  "plate": "L507135",
  "event_type": "panic",
  "lat": 19.49017,
  "lng": -70.71412
}
```

---

### 2.2 Historial de Recorrido / Playback de Ruta
Actualmente la app muestra la posición en vivo y la lista de eventos de ignición. Para la supervisión diaria, los gerentes de flota necesitan ver la trayectoria recorrida por un vehículo en un rango horario o turno de trabajo.

#### Endpoint Requerido:
```http
GET /api/v1/vehicles/{vehicle_id}/route?from={ISO8601}&to={ISO8601}&sample_step={segundos}
Authorization: Bearer <access_token>
```

#### Ejemplo de Solicitud:
```http
GET /api/v1/vehicles/019ef118-066d-707d-9f6a-1ba3047afee3/route?from=2026-10-02T06:00:00Z&to=2026-10-02T18:00:00Z
```

#### Formato de Respuesta Esperado:
```json
{
  "vehicle_id": "019ef118-066d-707d-9f6a-1ba3047afee3",
  "plate": "L507135",
  "total_distance_km": 142.6,
  "max_speed_kmh": 85.0,
  "idle_duration_min": 45,
  "points": [
    {
      "lat": 19.49017,
      "lng": -70.71412,
      "speed": 0.0,
      "heading": 0.0,
      "ignition": false,
      "timestamp": "2026-10-02T06:00:00Z"
    },
    {
      "lat": 19.49150,
      "lng": -70.71230,
      "speed": 42.5,
      "heading": 85.0,
      "ignition": true,
      "timestamp": "2026-10-02T06:05:12Z"
    }
  ]
}
```

---

### 2.3 Teléfono del Conductor en `/api/v1/mobile/fleet-summary`
En la tarjeta del vehículo y en el detalle de la unidad, la app ya muestra el nombre del chofer (ej. `Bryan Peguero`, `Marino`, `Brayan Quezada`).

#### Requerimiento:
Incluir el campo `driver_phone` en la estructura de cada vehículo dentro de `/api/v1/mobile/fleet-summary`:
```json
{
  "id": "...",
  "plate": "L507135",
  "driver_name": "Bryan Peguero",
  "driver_phone": "+18095551234",
  ...
}
```
*Impacto en iOS:* Permitirá llamadas telefónicas directas y botón de chat vía WhatsApp (`tel://` y `https://wa.me/`) con un solo toque desde la app del supervisor.

---

### 2.4 Confirmación Asíncrona de Comandos Remotos (WebSocket ACK)
La app móvil despacha `POST /api/v1/vehicles/{id}/commands` con `command: "stop_engine"` o `"resume_engine"`.  
El endpoint HTTP devuelve de inmediato `status: "queued"` o `"dispatched"`. Sin embargo, el corte real de combustible en el dispositivo GPS toma entre 3 y 20 segundos por red celular.

#### Requerimiento de Protocolo WebSocket:
Emitir un evento en el canal WebSocket del tenant cuando el rastreador físico envíe la confirmación GPRS/SMS:
```json
{
  "type": "command_status",
  "command_id": "cmd_01j7x8k9...",
  "vehicle_id": "019ef118-066d-707d-9f6a-1ba3047afee3",
  "plate": "L507135",
  "command": "stop_engine",
  "status": "executed", // "executed", "failed", "timeout"
  "message": "Relé de combustible desactivado satisfactoriamente por el GPS"
}
```
*Impacto en iOS:* El botón en la app pasará automáticamente de estado *"Enviando comando..."* a un distintivo verde *"Motor Inmovilizado"* con retroalimentación háptica nativa.

---

### 2.5 Capa de Geocercas para Visualización Móvil
La app cuenta con el selector de capas (Estándar, Satélite, Híbrido, Tráfico en tiempo real). Para agregar la capa de **Geocercas activas**:

#### Endpoint Requerido:
```http
GET /api/v1/geofences
Authorization: Bearer <access_token>
```

#### Respuesta esperada:
```json
{
  "geofences": [
    {
      "id": "geo_01",
      "name": "Almacén Central Santiago",
      "type": "polygon", // o "circle"
      "color": "#1E7BFF",
      "coordinates": [
        {"lat": 19.4920, "lng": -70.7160},
        {"lat": 19.4930, "lng": -70.7120},
        {"lat": 19.4890, "lng": -70.7110},
        {"lat": 19.4880, "lng": -70.7150}
      ]
    },
    {
      "id": "geo_02",
      "name": "Zona Norte Licey",
      "type": "circle",
      "color": "#2ECC5A",
      "center": {"lat": 19.5299, "lng": -70.7067},
      "radius_meters": 500
    }
  ]
}
```

---

### 2.6 Métricas de Sensores Adicionales (Telemetría de Flota)
Para flotas de carga y transporte comercial (como la flota de Telemarch con camiones KIA K2700 y furgonetas):
1. **Voltaje de Batería Principal:** Además del porcentaje `battery: 100`, incluir el voltaje en voltios (ej. `battery_voltage: 12.6` o `24.2`) para detectar alternadores dañados o baterías descargadas antes de que el vehículo falle.
2. **Nivel de Combustible:** Campo `fuel_level_percent` (0-100) y `fuel_liters` para los vehículos con sensor ultrasónico o varilla telemática instalada.
3. **Temperatura:** Para cajas refrigeradas, sensor `cargo_temp_celsius`.

---

## 3. Estado Actual de la App iOS (Entregable Listo)
- **Compilación:** 0 Errores, 0 Warnings en Swift 5.10 / iOS 17.0+.
- **Pruebas Unitarias:** 18/18 pruebas superadas (`** TEST SUCCEEDED **`).
- **Simulador Verificado:** iPhone 17 Pro ejecutando sesión real con datos satelitales en vivo de Santiago de los Caballeros.
- **Distribución TestFlight:**
  - Build ID: `9086273b-7da2-446d-9386-3a6c2e6e4d9e`
  - Enlace público para pruebas: [https://testflight.apple.com/join/r6uRrdcj](https://testflight.apple.com/join/r6uRrdcj)
