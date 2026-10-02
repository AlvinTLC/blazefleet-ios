import XCTest
@testable import BlazeFleet

final class FleetModelTests: XCTestCase {
    
    func testFleetSummaryResponseDecoding() throws {
        let json = """
        {
          "counts": {
            "total": 3,
            "moving": 1,
            "idle": 1,
            "stopped": 1,
            "offline": 0,
            "sos": 0
          },
          "vehicles": [
            {
              "vehicle_id": "v-1",
              "tracker_id": "t-1",
              "plate": "A123456",
              "vehicle_model": "Toyota Hilux",
              "driver_name": "Juan Perez",
              "state": "moving",
              "time": "2026-10-02T16:00:00Z",
              "lat": 18.4861,
              "lng": -69.9312,
              "speed_kmh": 45.2,
              "course": 90.0,
              "ignition": true,
              "satellites": 12,
              "odometer_km": 15023.4,
              "vehicle_odometer_km": 15023,
              "battery_pct": 98
            },
            {
              "vehicle_id": "v-2",
              "tracker_id": "t-2",
              "plate": "B987654",
              "vehicle_model": "Freightliner M2",
              "driver_name": null,
              "state": "stopped",
              "time": "2026-10-02T15:30:00Z",
              "lat": 19.5400,
              "lng": -70.7356,
              "course": 0,
              "ignition": false
            }
          ],
          "active_alerts_count": 2,
          "server_time": "2026-10-02T16:05:00Z"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(FleetSummaryResponse.self, from: json)
        
        XCTAssertEqual(response.counts.total, 3)
        XCTAssertEqual(response.vehicles.count, 2)
        
        let v1 = response.vehicles[0]
        XCTAssertEqual(v1.plate, "A123456")
        XCTAssertEqual(v1.state, .moving)
        XCTAssertEqual(v1.speedKmh, 45.2)
        XCTAssertEqual(v1.batteryPct, 98)
        XCTAssertEqual(v1.vehicleOdometerKm, 15023)
        
        let v2 = response.vehicles[1]
        XCTAssertEqual(v2.plate, "B987654")
        XCTAssertEqual(v2.state, .stopped)
        XCTAssertNil(v2.driverName)
        XCTAssertNil(v2.speedKmh)
        XCTAssertNil(v2.vehicleOdometerKm)
    }
    
    func testVehicleStateCaseInsensitiveAndAliases() throws {
        struct Container: Decodable {
            let state: VehicleState
        }
        
        func decodeState(_ stringVal: String) throws -> VehicleState {
            let json = "{\"state\": \"\(stringVal)\"}".data(using: .utf8)!
            return try JSONDecoder().decode(Container.self, from: json).state
        }
        
        XCTAssertEqual(try decodeState("moving"), .moving)
        XCTAssertEqual(try decodeState("MOVING"), .moving)
        XCTAssertEqual(try decodeState("En Movimiento"), .moving)
        
        XCTAssertEqual(try decodeState("idle"), .idle)
        XCTAssertEqual(try decodeState("ralenti"), .idle)
        
        XCTAssertEqual(try decodeState("stopped"), .stopped)
        XCTAssertEqual(try decodeState("detenido"), .stopped)
        
        XCTAssertEqual(try decodeState("offline"), .offline)
        XCTAssertEqual(try decodeState("desconectado"), .offline)
        
        XCTAssertEqual(try decodeState("sos"), .sos)
        XCTAssertEqual(try decodeState("panic"), .sos)
        
        // Fallback on unknown string
        XCTAssertEqual(try decodeState("unrecognized_state_123"), .offline)
    }
    
    func testLivePositionSpeedFallback() throws {
        // Test when speed is provided via 'speed' instead of 'speed_kmh'
        let json = """
        {
          "tracker_id": "trk-001",
          "plate": "L123456",
          "lat": 18.48,
          "lng": -69.93,
          "speed": 62.5,
          "ignition": true,
          "time": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """.data(using: .utf8)!
        
        let pos = try JSONDecoder().decode(LivePosition.self, from: json)
        XCTAssertEqual(pos.trackerId, "trk-001")
        XCTAssertEqual(pos.speedKmh, 62.5)
        XCTAssertEqual(pos.state, .moving)
    }
    
    func testComputeStateAlgorithm() {
        let now = ISO8601DateFormatter().string(from: Date())
        let old = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
        
        // Stale timestamp > 30m -> offline
        let state1 = LivePosition.computeState(time: old, ignition: true, speedKmh: 50.0)
        XCTAssertEqual(state1, .offline)
        
        // Missing time -> offline
        let state2 = LivePosition.computeState(time: nil, ignition: true, speedKmh: 50.0)
        XCTAssertEqual(state2, .offline)
        
        // Fresh time, ignition false -> stopped
        let state3 = LivePosition.computeState(time: now, ignition: false, speedKmh: 0.0)
        XCTAssertEqual(state3, .stopped)
        
        // Fresh time, speed > 3 -> moving
        let state4 = LivePosition.computeState(time: now, ignition: true, speedKmh: 15.0)
        XCTAssertEqual(state4, .moving)
        
        // Fresh time, speed <= 3 and ignition not false -> idle
        let state5 = LivePosition.computeState(time: now, ignition: true, speedKmh: 1.0)
        XCTAssertEqual(state5, .idle)
    }
}
