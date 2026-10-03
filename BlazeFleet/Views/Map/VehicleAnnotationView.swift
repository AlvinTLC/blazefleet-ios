import SwiftUI
import CoreLocation

public struct VehicleAnnotationView: View {
    public let vehicle: MobileVehicleSummary
    public let isSelected: Bool
    
    public init(vehicle: MobileVehicleSummary, isSelected: Bool = false) {
        self.vehicle = vehicle
        self.isSelected = isSelected
    }
    
    private var stateColor: Color {
        switch vehicle.state {
        case .moving: return BlazeTheme.moving
        case .idle: return BlazeTheme.idle
        case .stopped: return BlazeTheme.stopped
        case .offline: return BlazeTheme.offline
        case .sos: return BlazeTheme.danger
        }
    }
    
    public var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Glow Halo when moving or selected
                if vehicle.state == .moving || isSelected {
                    Circle()
                        .fill(stateColor.opacity(isSelected ? 0.35 : 0.2))
                        .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                }
                
                // Ring Background
                Circle()
                    .fill(BlazeTheme.surface)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(stateColor, lineWidth: 3)
                    )
                
                // Course Chevron or Stopped Dot
                if vehicle.state == .moving, let course = vehicle.course {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(stateColor)
                        .rotationEffect(.degrees(course))
                } else if vehicle.state == .stopped {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(stateColor)
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 8, height: 8)
                }
            }
            
            // License Plate & Speed Pill
            HStack(spacing: 3) {
                Text(vehicle.plate)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(BlazeTheme.textPrimary)
                
                if let speed = vehicle.speedKmh, vehicle.state == .moving || speed > 0 {
                    Text("•")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(BlazeTheme.moving)
                    
                    Text("\(Int(speed.rounded())) km/h")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(BlazeTheme.moving)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(BlazeTheme.surface.opacity(0.95))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(vehicle.state == .moving ? BlazeTheme.moving.opacity(0.6) : BlazeTheme.surfaceBorder, lineWidth: 0.8)
            )
        }
    }
}
