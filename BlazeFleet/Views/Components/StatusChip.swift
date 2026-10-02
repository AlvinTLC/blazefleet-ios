import SwiftUI

public struct StatusChip: View {
    public let state: VehicleState
    
    public init(state: VehicleState) {
        self.state = state
    }
    
    private var color: Color {
        switch state {
        case .moving: return BlazeTheme.moving
        case .idle: return BlazeTheme.idle
        case .stopped: return BlazeTheme.stopped
        case .offline: return BlazeTheme.offline
        case .sos: return BlazeTheme.danger
        }
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(state.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
