import SwiftUI

public struct VehicleCardView: View {
    public let vehicle: MobileVehicleSummary
    
    public init(vehicle: MobileVehicleSummary) {
        self.vehicle = vehicle
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Top row: Plate pill, Model, Status Chip
            HStack(alignment: .center) {
                // Dominican Plate Pill
                Text(vehicle.plate)
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundColor(BlazeTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(BlazeTheme.surfaceBorder)
                    .cornerRadius(6)
                
                Text(vehicle.vehicleModel.isEmpty ? "Vehículo" : vehicle.vehicleModel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BlazeTheme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                StatusChip(state: vehicle.state)
            }
            
            // Middle row: Driver & Speed
            HStack(alignment: .center) {
                if let driver = vehicle.driverName, !driver.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(BlazeTheme.textMuted)
                            .font(.system(size: 14))
                        Text(driver)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(BlazeTheme.textSecondary)
                            .lineLimit(1)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "person.slash")
                            .foregroundColor(BlazeTheme.textMuted)
                            .font(.system(size: 12))
                        Text("Sin conductor")
                            .font(.system(size: 13))
                            .foregroundColor(BlazeTheme.textMuted)
                    }
                }
                
                Spacer()
                
                // Speed & Ignition
                HStack(spacing: 10) {
                    if let ign = vehicle.ignition {
                        Image(systemName: ign ? "key.fill" : "key")
                            .foregroundColor(ign ? BlazeTheme.moving : BlazeTheme.stopped)
                            .font(.system(size: 13))
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(vehicle.speedKmh != nil ? String(format: "%.0f", vehicle.speedKmh!) : "0")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(vehicle.state == .moving ? BlazeTheme.moving : BlazeTheme.textPrimary)
                        Text("km/h")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(BlazeTheme.textMuted)
                    }
                }
            }
            
            if let gf = vehicle.currentGeofence {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                        .foregroundColor(BlazeTheme.primary)
                    Text(gf)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BlazeTheme.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let limit = vehicle.speedLimitKmh {
                        Text("Límite \(Int(limit)) km/h")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(BlazeTheme.textMuted)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(BlazeTheme.primary.opacity(0.08))
                .cornerRadius(6)
            }
            
            Divider()
                .background(BlazeTheme.surfaceBorder.opacity(0.6))
            
            // Bottom row: Satellites, Battery, Odometer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 11))
                        .foregroundColor(BlazeTheme.primary)
                    Text("\(vehicle.satellites ?? 0) satélites")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BlazeTheme.textMuted)
                }
                
                Spacer()
                
                if let bat = vehicle.batteryPct {
                    HStack(spacing: 4) {
                        Image(systemName: "battery.75")
                            .font(.system(size: 11))
                            .foregroundColor(bat < 20 ? BlazeTheme.danger : BlazeTheme.textSecondary)
                        Text("\(bat)%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(BlazeTheme.textMuted)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 11))
                        .foregroundColor(BlazeTheme.textSecondary)
                    Text("\(vehicle.vehicleOdometerKm ?? 0) km")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BlazeTheme.textMuted)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(BlazeTheme.textMuted)
                    .padding(.leading, 4)
            }
        }
        .padding(14)
        .background(BlazeTheme.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(vehicle.state == .moving ? BlazeTheme.primaryGlow : BlazeTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
