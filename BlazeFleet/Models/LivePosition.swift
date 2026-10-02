import Foundation
import CoreLocation

public enum VehicleState: String, Codable, CaseIterable {
    case moving
    case idle
    case stopped
    case offline
    case sos
    
    public var displayName: String {
        switch self {
        case .moving: return "En movimiento"
        case .idle: return "En ralentí"
        case .stopped: return "Detenido"
        case .offline: return "Sin señal"
        case .sos: return "S.O.S. / Pánico"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch raw {
        case "moving", "en movimiento":
            self = .moving
        case "idle", "ralenti", "en ralentí":
            self = .idle
        case "stopped", "detenido", "detenidos":
            self = .stopped
        case "sos", "panic", "panico", "pánico":
            self = .sos
        case "offline", "desconectado", "sin señal":
            self = .offline
        default:
            self = .offline
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

public struct LivePosition: Codable, Identifiable {
    public var id: String { trackerId }
    public let trackerId: String
    public let vehicleId: String?
    public let plate: String?
    public let vehicleModel: String?
    public let driverName: String?
    public let state: VehicleState?
    public let lat: Double?
    public let lng: Double?
    public let speedKmh: Double?
    public let course: Double?
    public let ignition: Bool?
    public let satellites: Int?
    public let odometerKm: Double?
    public let vehicleOdometerKm: Int?
    public let time: String?
    
    public var coordinate: CLLocationCoordinate2D? {
        guard let lat = lat, let lng = lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    public init(
        trackerId: String,
        vehicleId: String? = nil,
        plate: String? = nil,
        vehicleModel: String? = nil,
        driverName: String? = nil,
        state: VehicleState? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        speedKmh: Double? = nil,
        course: Double? = nil,
        ignition: Bool? = nil,
        satellites: Int? = nil,
        odometerKm: Double? = nil,
        vehicleOdometerKm: Int? = nil,
        time: String? = nil
    ) {
        self.trackerId = trackerId
        self.vehicleId = vehicleId
        self.plate = plate
        self.vehicleModel = vehicleModel
        self.driverName = driverName
        self.state = state
        self.lat = lat
        self.lng = lng
        self.speedKmh = speedKmh
        self.course = course
        self.ignition = ignition
        self.satellites = satellites
        self.odometerKm = odometerKm
        self.vehicleOdometerKm = vehicleOdometerKm
        self.time = time
    }
    
    enum CodingKeys: String, CodingKey {
        case trackerId = "tracker_id"
        case vehicleId = "vehicle_id"
        case plate
        case vehicleModel = "vehicle_model"
        case driverName = "driver_name"
        case state
        case lat
        case lng
        case speedKmh = "speed_kmh"
        case speed
        case course
        case ignition
        case satellites
        case odometerKm = "odometer_km"
        case vehicleOdometerKm = "vehicle_odometer_km"
        case time
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        trackerId = try c.decode(String.self, forKey: .trackerId)
        vehicleId = try c.decodeIfPresent(String.self, forKey: .vehicleId)
        plate = try c.decodeIfPresent(String.self, forKey: .plate)
        vehicleModel = try c.decodeIfPresent(String.self, forKey: .vehicleModel)
        driverName = try c.decodeIfPresent(String.self, forKey: .driverName)
        
        let explicitState = try c.decodeIfPresent(VehicleState.self, forKey: .state)
        lat = try c.decodeIfPresent(Double.self, forKey: .lat)
        lng = try c.decodeIfPresent(Double.self, forKey: .lng)
        
        let skmh = try c.decodeIfPresent(Double.self, forKey: .speedKmh)
        let sraw = try c.decodeIfPresent(Double.self, forKey: .speed)
        speedKmh = skmh ?? sraw
        
        course = try c.decodeIfPresent(Double.self, forKey: .course)
        ignition = try c.decodeIfPresent(Bool.self, forKey: .ignition)
        satellites = try c.decodeIfPresent(Int.self, forKey: .satellites)
        odometerKm = try c.decodeIfPresent(Double.self, forKey: .odometerKm)
        vehicleOdometerKm = try c.decodeIfPresent(Int.self, forKey: .vehicleOdometerKm)
        time = try c.decodeIfPresent(String.self, forKey: .time)
        
        if let s = explicitState {
            state = s
        } else {
            state = LivePosition.computeState(time: time, ignition: ignition, speedKmh: speedKmh)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(trackerId, forKey: .trackerId)
        try c.encodeIfPresent(vehicleId, forKey: .vehicleId)
        try c.encodeIfPresent(plate, forKey: .plate)
        try c.encodeIfPresent(vehicleModel, forKey: .vehicleModel)
        try c.encodeIfPresent(driverName, forKey: .driverName)
        try c.encodeIfPresent(state, forKey: .state)
        try c.encodeIfPresent(lat, forKey: .lat)
        try c.encodeIfPresent(lng, forKey: .lng)
        try c.encodeIfPresent(speedKmh, forKey: .speedKmh)
        try c.encodeIfPresent(course, forKey: .course)
        try c.encodeIfPresent(ignition, forKey: .ignition)
        try c.encodeIfPresent(satellites, forKey: .satellites)
        try c.encodeIfPresent(odometerKm, forKey: .odometerKm)
        try c.encodeIfPresent(vehicleOdometerKm, forKey: .vehicleOdometerKm)
        try c.encodeIfPresent(time, forKey: .time)
    }
    
    public static func computeState(time: String?, ignition: Bool?, speedKmh: Double?) -> VehicleState {
        // Algorithm matching BlazeFleet web core:
        // 1. If time is missing or > 30 minutes old -> offline
        if let timeStr = time {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var date = formatter.date(from: timeStr)
            if date == nil {
                formatter.formatOptions = [.withInternetDateTime]
                date = formatter.date(from: timeStr)
            }
            if let d = date, Date().timeIntervalSince(d) > 1800 {
                return .offline
            }
        } else {
            return .offline
        }
        
        // 2. If ignition is explicitly false -> stopped
        if ignition == false {
            return .stopped
        }
        
        // 3. If speed > 3 km/h -> moving
        if let s = speedKmh, s > 3.0 {
            return .moving
        }
        
        // 4. Default -> idle
        return .idle
    }
}
