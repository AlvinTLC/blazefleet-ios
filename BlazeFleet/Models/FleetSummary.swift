import Foundation

public struct FleetSummaryCounts: Codable, Equatable {
    public let total: Int
    public let moving: Int
    public let idle: Int
    public let stopped: Int
    public let offline: Int
    public let sos: Int
    public let speeding: Int?
    public let insideGeofence: Int?
    
    public init(total: Int, moving: Int, idle: Int, stopped: Int, offline: Int, sos: Int = 0, speeding: Int? = 0, insideGeofence: Int? = 0) {
        self.total = total
        self.moving = moving
        self.idle = idle
        self.stopped = stopped
        self.offline = offline
        self.sos = sos
        self.speeding = speeding
        self.insideGeofence = insideGeofence
    }
    
    public static var zero: FleetSummaryCounts {
        FleetSummaryCounts(total: 0, moving: 0, idle: 0, stopped: 0, offline: 0, sos: 0, speeding: 0, insideGeofence: 0)
    }
    
    enum CodingKeys: String, CodingKey {
        case total, moving, idle, stopped, offline, sos, speeding
        case insideGeofence = "inside_geofence"
    }
}

public struct MobileVehicleSummary: Codable, Identifiable {
    public var id: String { vehicleId.isEmpty ? trackerId : vehicleId }
    public let vehicleId: String
    public let trackerId: String
    public let plate: String
    public let vehicleModel: String
    public let driverName: String?
    public let driverPhone: String?
    public let state: VehicleState
    public let time: String?
    public let lat: Double?
    public let lng: Double?
    public let speedKmh: Double?
    public let course: Double?
    public let ignition: Bool?
    public let satellites: Int?
    public let odometerKm: Double?
    public let vehicleOdometerKm: Int?
    public let batteryPct: Int?
    public let speedLimitKmh: Double?
    public let currentGeofence: String?
    public let todayAlertsCount: Int?
    
    public init(
        vehicleId: String,
        trackerId: String,
        plate: String,
        vehicleModel: String = "",
        driverName: String? = nil,
        driverPhone: String? = nil,
        state: VehicleState,
        time: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        speedKmh: Double? = nil,
        course: Double? = nil,
        ignition: Bool? = nil,
        satellites: Int? = nil,
        odometerKm: Double? = nil,
        vehicleOdometerKm: Int? = nil,
        batteryPct: Int? = nil,
        speedLimitKmh: Double? = nil,
        currentGeofence: String? = nil,
        todayAlertsCount: Int? = nil
    ) {
        self.vehicleId = vehicleId
        self.trackerId = trackerId
        self.plate = plate
        self.vehicleModel = vehicleModel
        self.driverName = driverName
        self.driverPhone = driverPhone
        self.state = state
        self.time = time
        self.lat = lat
        self.lng = lng
        self.speedKmh = speedKmh
        self.course = course
        self.ignition = ignition
        self.satellites = satellites
        self.odometerKm = odometerKm
        self.vehicleOdometerKm = vehicleOdometerKm
        self.batteryPct = batteryPct
        self.speedLimitKmh = speedLimitKmh
        self.currentGeofence = currentGeofence
        self.todayAlertsCount = todayAlertsCount
    }
    
    enum CodingKeys: String, CodingKey {
        case vehicleId = "vehicle_id"
        case trackerId = "tracker_id"
        case plate
        case vehicleModel = "vehicle_model"
        case driverName = "driver_name"
        case driverPhone = "driver_phone"
        case state
        case time
        case lat
        case lng
        case speedKmh = "speed_kmh"
        case course
        case ignition
        case satellites
        case odometerKm = "odometer_km"
        case vehicleOdometerKm = "vehicle_odometer_km"
        case batteryPct = "battery_pct"
        case speedLimitKmh = "speed_limit_kmh"
        case currentGeofence = "current_geofence"
        case todayAlertsCount = "today_alerts_count"
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        vehicleId = (try? c.decode(String.self, forKey: .vehicleId)) ?? ""
        trackerId = try c.decode(String.self, forKey: .trackerId)
        plate = (try? c.decode(String.self, forKey: .plate)) ?? "S/P"
        vehicleModel = (try? c.decode(String.self, forKey: .vehicleModel)) ?? ""
        driverName = try? c.decodeIfPresent(String.self, forKey: .driverName)
        driverPhone = try? c.decodeIfPresent(String.self, forKey: .driverPhone)
        state = (try? c.decode(VehicleState.self, forKey: .state)) ?? .offline
        time = try? c.decodeIfPresent(String.self, forKey: .time)
        lat = try? c.decodeIfPresent(Double.self, forKey: .lat)
        lng = try? c.decodeIfPresent(Double.self, forKey: .lng)
        speedKmh = try? c.decodeIfPresent(Double.self, forKey: .speedKmh)
        course = try? c.decodeIfPresent(Double.self, forKey: .course)
        ignition = try? c.decodeIfPresent(Bool.self, forKey: .ignition)
        satellites = try? c.decodeIfPresent(Int.self, forKey: .satellites)
        odometerKm = try? c.decodeIfPresent(Double.self, forKey: .odometerKm)
        vehicleOdometerKm = try? c.decodeIfPresent(Int.self, forKey: .vehicleOdometerKm)
        batteryPct = try? c.decodeIfPresent(Int.self, forKey: .batteryPct)
        speedLimitKmh = try? c.decodeIfPresent(Double.self, forKey: .speedLimitKmh)
        currentGeofence = try? c.decodeIfPresent(String.self, forKey: .currentGeofence)
        todayAlertsCount = try? c.decodeIfPresent(Int.self, forKey: .todayAlertsCount)
    }
}

public struct FleetSummaryResponse: Codable {
    public let counts: FleetSummaryCounts
    public let vehicles: [MobileVehicleSummary]
    public let activeAlertsCount: Int
    public let serverTime: String
    
    public init(counts: FleetSummaryCounts, vehicles: [MobileVehicleSummary], activeAlertsCount: Int, serverTime: String) {
        self.counts = counts
        self.vehicles = vehicles
        self.activeAlertsCount = activeAlertsCount
        self.serverTime = serverTime
    }
    
    enum CodingKeys: String, CodingKey {
        case counts
        case vehicles
        case activeAlertsCount = "active_alerts_count"
        case serverTime = "server_time"
    }
}

public struct MobileConfigResponse: Codable {
    public let tenantId: String
    public let wsPath: String
    public let brandColor: String
    public let mapStyleDefault: String
    public let minRefreshIntervalSec: Int
    public let emergencySosPhone: String
    public let supportPhone: String
    
    enum CodingKeys: String, CodingKey {
        case tenantId = "tenant_id"
        case wsPath = "ws_path"
        case brandColor = "brand_color"
        case mapStyleDefault = "map_style_default"
        case minRefreshIntervalSec = "min_refresh_interval_sec"
        case emergencySosPhone = "emergency_sos_phone"
        case supportPhone = "support_phone"
    }
}

public struct RemoteCommandResponse: Codable {
    public let commandId: String
    public let vehicleId: String
    public let trackerId: String
    public let command: String
    public let status: String
    public let dispatchedAt: String
    
    enum CodingKeys: String, CodingKey {
        case commandId = "command_id"
        case vehicleId = "vehicle_id"
        case trackerId = "tracker_id"
        case command
        case status
        case dispatchedAt = "dispatched_at"
    }
}

public struct NotificationItem: Codable, Identifiable, Equatable {
    public let id: String
    public let kind: String
    public let title: String
    public let body: String
    public let entityType: String?
    public let entityId: String?
    public var read: Bool
    public let createdAt: String
    
    public init(
        id: String,
        kind: String,
        title: String,
        body: String,
        entityType: String? = nil,
        entityId: String? = nil,
        read: Bool = false,
        createdAt: String
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.entityType = entityType
        self.entityId = entityId
        self.read = read
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case body
        case entityType = "entity_type"
        case entityId = "entity_id"
        case read
        case createdAt = "created_at"
    }
}

public struct NotificationsResponse: Codable {
    public let items: [NotificationItem]
    public let unread: Int?
}

public struct EventItem: Codable, Identifiable, Equatable {
    public let id: String
    public let vehicleId: String?
    public let plate: String?
    public let kind: String
    public let time: String
    
    public init(id: String, vehicleId: String? = nil, plate: String? = nil, kind: String, time: String) {
        self.id = id
        self.vehicleId = vehicleId
        self.plate = plate
        self.kind = kind
        self.time = time
    }
    
    public var displayName: String {
        switch kind {
        case "ignition_on": return "Motor Encendido"
        case "ignition_off": return "Motor Apagado"
        case "power_cut": return "Corte de Alimentación GPS"
        case "power_restored": return "Alimentación Restablecida"
        case "speeding": return "Exceso de Velocidad"
        case "panic", "sos": return "Alerta S.O.S. / Pánico"
        case "geofence_enter": return "Entrada a Geocerca"
        case "geofence_exit": return "Salida de Geocerca"
        default: return kind.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    public var iconName: String {
        switch kind {
        case "ignition_on": return "key.fill"
        case "ignition_off": return "key"
        case "power_cut": return "powercord.fill"
        case "power_restored": return "bolt.fill"
        case "speeding": return "speedometer"
        case "panic", "sos": return "exclamationmark.shield.fill"
        case "geofence_enter": return "arrow.down.right.and.arrow.up.left"
        case "geofence_exit": return "arrow.up.left.and.arrow.down.right"
        default: return "clock.fill"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case plate
        case kind
        case time
    }
}

public struct EventsResponse: Codable {
    public let items: [EventItem]
}

public struct MobileAlertItem: Codable, Identifiable, Equatable {
    public let id: String
    public let kind: String
    public let title: String
    public let body: String
    public let severity: String
    public let vehicleId: String?
    public let plate: String?
    public let vehicleModel: String?
    public let geofenceId: String?
    public let geofenceName: String?
    public let speedKmh: Double?
    public let speedLimitKmh: Double?
    public let time: String?
    public let acknowledged: Bool
    public let acknowledgedAt: String?
    public let ackNote: String?
    
    enum CodingKeys: String, CodingKey {
        case id, kind, title, body, severity
        case vehicleId = "vehicle_id"
        case plate
        case vehicleModel = "vehicle_model"
        case geofenceId = "geofence_id"
        case geofenceName = "geofence_name"
        case speedKmh = "speed_kmh"
        case speedLimitKmh = "speed_limit_kmh"
        case time, acknowledged
        case acknowledgedAt = "acknowledged_at"
        case ackNote = "ack_note"
    }
}

public struct MobileAlertCounts: Codable, Equatable {
    public let total: Int
    public let unacknowledged: Int
    public let critical: Int
    public let warning: Int
    public let info: Int
}

public struct MobileAlertsResponse: Codable {
    public let counts: MobileAlertCounts
    public let items: [MobileAlertItem]
}

public struct MobileMetricsResponse: Codable {
    public let totalDistanceKmToday: Double
    public let tripsToday: Int
    public let speedingAlertsToday: Int
    public let geofenceAlertsToday: Int
    public let sosAlertsToday: Int
    public let totalVehicles: Int
    public let movingVehicles: Int
    public let idleVehicles: Int
    public let stoppedVehicles: Int
    public let offlineVehicles: Int
    public let fleetUtilizationPct: Double
    public let generatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case totalDistanceKmToday = "total_distance_km_today"
        case tripsToday = "trips_today"
        case speedingAlertsToday = "speeding_alerts_today"
        case geofenceAlertsToday = "geofence_alerts_today"
        case sosAlertsToday = "sos_alerts_today"
        case totalVehicles = "total_vehicles"
        case movingVehicles = "moving_vehicles"
        case idleVehicles = "idle_vehicles"
        case stoppedVehicles = "stopped_vehicles"
        case offlineVehicles = "offline_vehicles"
        case fleetUtilizationPct = "fleet_utilization_pct"
        case generatedAt = "generated_at"
    }
}

public struct VehicleShareLinkResponse: Codable {
    public let id: String
    public let vehicleId: String
    public let token: String
    public let shareUrl: String
    public let expiresAt: String
    public let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case token
        case shareUrl = "share_url"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}

