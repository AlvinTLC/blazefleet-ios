import Foundation
import Combine

@MainActor
public final class VehicleDetailViewModel: ObservableObject {
    @Published public var vehicle: MobileVehicleSummary
    @Published public var isExecutingCommand = false
    @Published public var commandSuccessMessage: String?
    @Published public var commandErrorMessage: String?
    @Published public var showCommandConfirmation = false
    @Published public var pendingCommand: String?
    
    private let api = APIClient.shared
    private let biometricAuth = BiometricAuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init(vehicle: MobileVehicleSummary) {
        self.vehicle = vehicle
        bindWebSocket()
    }
    
    private func bindWebSocket() {
        WebSocketService.shared.$positions
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] (dict: [String: LivePosition]) -> LivePosition? in
                guard let self = self else { return nil }
                return dict[self.vehicle.trackerId]
            }
            .sink { [weak self] (update: LivePosition) in
                guard let self = self else { return }
                self.vehicle = MobileVehicleSummary(
                    vehicleId: self.vehicle.vehicleId,
                    trackerId: self.vehicle.trackerId,
                    plate: update.plate ?? self.vehicle.plate,
                    vehicleModel: update.vehicleModel ?? self.vehicle.vehicleModel,
                    driverName: update.driverName ?? self.vehicle.driverName,
                    state: update.state ?? self.vehicle.state,
                    time: update.time ?? self.vehicle.time,
                    lat: update.lat ?? self.vehicle.lat,
                    lng: update.lng ?? self.vehicle.lng,
                    speedKmh: update.speedKmh ?? self.vehicle.speedKmh,
                    course: update.course ?? self.vehicle.course,
                    ignition: update.ignition ?? self.vehicle.ignition,
                    satellites: update.satellites ?? self.vehicle.satellites,
                    odometerKm: update.odometerKm ?? self.vehicle.odometerKm,
                    vehicleOdometerKm: update.vehicleOdometerKm ?? self.vehicle.vehicleOdometerKm,
                    batteryPct: self.vehicle.batteryPct
                )
            }
            .store(in: &cancellables)
    }
    
    public func promptCommand(command: String) {
        self.pendingCommand = command
        self.showCommandConfirmation = true
    }
    
    public func confirmAndExecuteCommand() async {
        guard let command = pendingCommand else { return }
        
        // If command is critical (engine shutoff), require biometric FaceID/TouchID
        if command == "engine_stop" {
            let authenticated = await biometricAuth.authenticateForSensitiveAction(
                reason: "Confirma con Face ID / Touch ID para apagar el motor remotamente"
            )
            guard authenticated else {
                self.commandErrorMessage = "Autenticación biométrica requerida para apagar motor."
                return
            }
        }
        
        isExecutingCommand = true
        commandErrorMessage = nil
        commandSuccessMessage = nil
        
        do {
            let resp = try await api.dispatchCommand(
                vehicleId: vehicle.vehicleId,
                command: command,
                reason: "Comando móvil desde app iOS"
            )
            self.commandSuccessMessage = "Comando '\(resp.command)' enviado exitosamente (ID: \(resp.commandId.prefix(8)))"
        } catch {
            self.commandErrorMessage = "Error ejecutando comando: \(error.localizedDescription)"
        }
        
        isExecutingCommand = false
        pendingCommand = nil
    }
}
