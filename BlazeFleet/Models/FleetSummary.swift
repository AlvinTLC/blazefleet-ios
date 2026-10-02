import Foundation

public struct FleetSummaryCounts: Codable, Equatable {
    public let total: Int
    public let moving: Int
    public let idle: Int
    public let stopped: Int
    public let offline: Int
    public let sos: Int
    
    public init(total: Int, moving: Int, idle: Int, stopped: Int, offline: Int, sos: Int = 0) {
        self.total = total
        self.moving = moving
        self.idle = idle
        self.stopped = stopped
        self.offline = offline
        self.sos = sos
    }
    
    public static var zero: FleetSummaryCounts {
        FleetSummaryCounts(total: 0, moving: 0, idle: 0, stopped: 0, offline: 0, sos: 0)
    }
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
    public let vehicleOdometerKm: Int?
    public let batteryPct: Int?
    
    public init(
        vehicleId: String,
        trackerId: String,
        plate: String,
        vehicleModel: String = "",
        driverName: String? = nil,
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
        batteryPct: Int? = nil
    ) {
        self.vehicleId = vehicleId
        self.trackerId = trackerId
        self.plate = plate
        self.vehicleModel = vehicleModel
        self.driverName = driverName
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
    }
    
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
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        vehicleId = (try? c.decode(String.self, forKey: .vehicleId)) ?? ""
        trackerId = try c.decode(String.self, forKey: .trackerId)
        plate = (try? c.decode(String.self, forKey: .plate)) ?? "S/P"
        vehicleModel = (try? c.decode(String.self, forKey: .vehicleModel)) ?? ""
        driverName = try? c.decodeIfPresent(String.self, forKey: .driverName)
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

public struct EventItem: Codable, Identifiable {
    public let id: String
    public let vehicleId: String?
    public let kind: String
    public let time: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case kind
        case time
    }
}

public struct EventsResponse: Codable {
    public let items: [EventItem]
}
