import SwiftUI

public struct StatusFilterBar: View {
    @Binding var selected: FleetFilter
    let counts: FleetSummaryCounts?
    
    public init(selected: Binding<FleetFilter>, counts: FleetSummaryCounts?) {
        self._selected = selected
        self.counts = counts
    }
    
    private func countForFilter(_ f: FleetFilter) -> Int {
        guard let c = counts else { return 0 }
        switch f {
        case .all: return c.total
        case .moving: return c.moving
        case .idle: return c.idle
        case .stopped: return c.stopped
        case .offline: return c.offline
        }
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FleetFilter.allCases) { filter in
                    let isSelected = selected == filter
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selected = filter
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            
                            Text("\(countForFilter(filter))")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isSelected ? Color.white.opacity(0.25) : BlazeTheme.surfaceBorder)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? BlazeTheme.primary : BlazeTheme.surface)
                        .foregroundColor(isSelected ? .white : BlazeTheme.textSecondary)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? BlazeTheme.primary : BlazeTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}
