import SwiftUI

public struct TelemetryGaugesView: View {
    public let vehicle: MobileVehicleSummary
    
    public init(vehicle: MobileVehicleSummary) {
        self.vehicle = vehicle
    }
    
    public var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Speed Gauge
            GaugeTile(
                icon: "speedometer",
                title: "Velocidad",
                value: vehicle.speedKmh != nil ? String(format: "%.1f", vehicle.speedKmh!) : "0.0",
                unit: "km/h",
                tint: vehicle.state == .moving ? BlazeTheme.moving : BlazeTheme.textPrimary
            )
            
            // Odometer
            GaugeTile(
                icon: "gauge.with.dots.needle.bottom.50percent",
                title: "Odómetro",
                value: "\(vehicle.vehicleOdometerKm ?? 0)",
                unit: "km",
                tint: BlazeTheme.primary
            )
            
            // Ignition
            GaugeTile(
                icon: vehicle.ignition == true ? "key.fill" : "key",
                title: "Ignición",
                value: vehicle.ignition == true ? "ENCENDIDO" : "APAGADO",
                unit: "",
                tint: vehicle.ignition == true ? BlazeTheme.moving : BlazeTheme.stopped
            )
            
            // Battery
            GaugeTile(
                icon: "battery.75",
                title: "Batería GPS",
                value: vehicle.batteryPct != nil ? "\(vehicle.batteryPct!)" : "100",
                unit: "%",
                tint: (vehicle.batteryPct ?? 100) < 20 ? BlazeTheme.danger : BlazeTheme.secondary
            )
            
            // Satellites
            GaugeTile(
                icon: "antenna.radiowaves.left.and.right",
                title: "Satélites",
                value: "\(vehicle.satellites ?? 0)",
                unit: "GPS fixes",
                tint: BlazeTheme.secondary
            )
            
            // Course
            GaugeTile(
                icon: "safari.fill",
                title: "Rumbo",
                value: vehicle.course != nil ? String(format: "%.0f°", vehicle.course!) : "0°",
                unit: "azimut",
                tint: BlazeTheme.primary
            )
        }
    }
}

struct GaugeTile: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BlazeTheme.textSecondary)
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(BlazeTheme.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(BlazeTheme.textMuted)
                }
            }
        }
        .padding(14)
        .background(BlazeTheme.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(BlazeTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
