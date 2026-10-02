import Foundation
import CoreLocation

public enum VehicleState: String, Codable {
    case moving
    case idle
    case stopped
    case offline
    
    public var displayName: String {
        switch self {
        case .moving: return "En movimiento"
        case .idle: return "En ralentí"
        case .stopped: return "Detenido"
        case .offline: return "Sin señal"
        }
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
        case course
        case ignition
        case satellites
        case odometerKm = "odometer_km"
        case vehicleOdometerKm = "vehicle_odometer_km"
        case time
    }
}
