import XCTest
@testable import BlazeFleet

final class NotificationsTests: XCTestCase {
    
    func testNotificationsResponseDecoding() throws {
        let json = """
        {
          "items": [
            {
              "id": "01a0fd63-0104-7384-b88d-07a267c2d2b7",
              "kind": "billing",
              "title": "Cuenta suspendida",
              "body": "Tu cuenta fue suspendida por falta de pago.",
              "entity_type": "invoice",
              "entity_id": "019ed69f-c449-7f0a-8e1d-996063b644fa",
              "read": false,
              "created_at": "2026-10-02T16:11:59Z"
            },
            {
              "id": "01a0fd63-0104-7384-b88d-07a267c2d2b8",
              "kind": "sos",
              "title": "Botón de pánico",
              "body": "Alerta de pánico activada en unidad A123456",
              "entity_type": "vehicle",
              "entity_id": "019ed69f-c449-7f0a-8e1d-996063b644fb",
              "read": true,
              "created_at": "2026-10-02T16:00:00Z"
            }
          ],
          "unread": 1
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(NotificationsResponse.self, from: json)
        XCTAssertEqual(response.items.count, 2)
        XCTAssertEqual(response.unread, 1)
        
        let item1 = response.items[0]
        XCTAssertEqual(item1.id, "01a0fd63-0104-7384-b88d-07a267c2d2b7")
        XCTAssertEqual(item1.kind, "billing")
        XCTAssertFalse(item1.read)
        
        let item2 = response.items[1]
        XCTAssertEqual(item2.kind, "sos")
        XCTAssertTrue(item2.read)
    }
    
    func testEventsResponseDecoding() throws {
        let json = """
        {
          "items": [
            {
              "id": "ev-01",
              "vehicle_id": "vh-01",
              "kind": "ignition_on",
              "time": "2026-10-02T16:10:00Z"
            },
            {
              "id": "ev-02",
              "vehicle_id": "vh-01",
              "kind": "power_cut",
              "time": "2026-10-02T16:05:00Z"
            }
          ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(EventsResponse.self, from: json)
        XCTAssertEqual(response.items.count, 2)
        XCTAssertEqual(response.items[0].kind, "ignition_on")
        XCTAssertEqual(response.items[1].kind, "power_cut")
    }
}
