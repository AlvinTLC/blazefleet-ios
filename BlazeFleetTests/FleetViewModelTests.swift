import XCTest
@testable import BlazeFleet

@MainActor
final class FleetViewModelTests: XCTestCase {
    
    var viewModel: FleetViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = FleetViewModel()
        
        viewModel.vehicles = [
            MobileVehicleSummary(
                vehicleId: "v-1",
                trackerId: "t-1",
                plate: "A111111",
                vehicleModel: "Toyota Hilux",
                driverName: "Carlos Santana",
                state: .moving,
                speedKmh: 65.0
            ),
            MobileVehicleSummary(
                vehicleId: "v-2",
                trackerId: "t-2",
                plate: "B222222",
                vehicleModel: "Honda Civic",
                driverName: "Maria Rodriguez",
                state: .idle,
                speedKmh: 0.0
            ),
            MobileVehicleSummary(
                vehicleId: "v-3",
                trackerId: "t-3",
                plate: "C333333",
                vehicleModel: "Isuzu Forward",
                driverName: nil,
                state: .stopped,
                speedKmh: 0.0
            ),
            MobileVehicleSummary(
                vehicleId: "v-4",
                trackerId: "t-4",
                plate: "D444444",
                vehicleModel: "Ford F-150",
                driverName: "Pedro Pascal",
                state: .offline,
                speedKmh: nil
            )
        ]
        
        viewModel.counts = FleetSummaryCounts(
            total: 4,
            moving: 1,
            idle: 1,
            stopped: 1,
            offline: 1
        )
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testFilterAll() {
        viewModel.selectedFilter = .all
        XCTAssertEqual(viewModel.filteredVehicles.count, 4)
    }
    
    func testFilterMoving() {
        viewModel.selectedFilter = .moving
        XCTAssertEqual(viewModel.filteredVehicles.count, 1)
        XCTAssertEqual(viewModel.filteredVehicles.first?.plate, "A111111")
    }
    
    func testFilterIdle() {
        viewModel.selectedFilter = .idle
        XCTAssertEqual(viewModel.filteredVehicles.count, 1)
        XCTAssertEqual(viewModel.filteredVehicles.first?.plate, "B222222")
    }
    
    func testFilterStopped() {
        viewModel.selectedFilter = .stopped
        XCTAssertEqual(viewModel.filteredVehicles.count, 1)
        XCTAssertEqual(viewModel.filteredVehicles.first?.plate, "C333333")
    }
    
    func testFilterOffline() {
        viewModel.selectedFilter = .offline
        XCTAssertEqual(viewModel.filteredVehicles.count, 1)
        XCTAssertEqual(viewModel.filteredVehicles.first?.plate, "D444444")
    }
    
    func testSearchByPlate() {
        viewModel.selectedFilter = .all
        viewModel.searchQuery = "A11"
        XCTAssertEqual(viewModel.filteredVehicles.count, 1)
        XCTAssertEqual(viewModel.filteredVehicles.first?.plate, "A111111")
    }
    
    func testSearchByModel() {
        viewModel.selectedFilter = .all
        viewModel.searchQuery = "civic"
        XCTAssertEqual(viewModel.filteredVehicles.count, 1)
        XCTAssertEqual(viewModel.filteredVehicles.first?.plate, "B222222")
    }
    
    func testSearchByDriver() {
        viewModel.selectedFilter = .all
        viewModel.searchQuery = "pascal"
        XCTAssertEqual(viewModel.filteredVehicles.count, 1)
        XCTAssertEqual(viewModel.filteredVehicles.first?.plate, "D444444")
    }
    
    func testSearchAndFilterCombined() {
        viewModel.selectedFilter = .moving
        viewModel.searchQuery = "civic" // civic is idle, not moving
        XCTAssertEqual(viewModel.filteredVehicles.count, 0)
        
        viewModel.searchQuery = "hilux" // hilux is moving
        XCTAssertEqual(viewModel.filteredVehicles.count, 1)
    }
}
