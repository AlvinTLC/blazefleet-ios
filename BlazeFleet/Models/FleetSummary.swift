import Foundation

public struct FleetSummaryCounts: Codable {
    public let total: Int
    public let moving: Int
    public let idle: Int
    public let stopped: Int
    public let offline: Int
    public let sos: Int
}

public struct MobileVehicleSummary: Codable, Identifiable {
    public var id: String { vehicleId.isEmpty ? trackerId : vehicleId }
    public let vehicleId: String
    public let trackerId: String
    public let plate: String
    public let vehicleModel: String
    public let driverName: String?
    public let state: VehicleState
    public let time: String?
    public let lat: Double?
    public let lng: Double?
    public let speedKmh: Double?
    public let course: Double?
    public let ignition: Bool?
    public let satellites: Int?
    public let odometerKm: Double?
    public let vehicleOdometerKm: Int
    public let batteryPct: Int?
    
    enum CodingKeys: String, CodingKey {
        case vehicleId = "vehicle_id"
        case trackerId = "tracker_id"
        case plate
        case vehicleModel = "vehicle_model"
        case driverName = "driver_name"
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
    }
}

public struct FleetSummaryResponse: Codable {
    public let counts: FleetSummaryCounts
    public let vehicles: [MobileVehicleSummary]
    public let activeAlertsCount: Int
    public let serverTime: String
    
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

public struct NotificationItem: Codable, Identifiable {
    public let id: String
    public let kind: String
    public let title: String
    public let body: String
    public let entityType: String?
    public let entityId: String?
    public let read: Bool
    public let createdAt: String
    
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
