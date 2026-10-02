import SwiftUI

public struct SparklineView: View {
    public let values: [Double]
    public let lineColor: Color
    
    public init(values: [Double], lineColor: Color = BlazeTheme.primary) {
        self.values = values.isEmpty ? [0, 0, 0] : values
        self.lineColor = lineColor
    }
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxVal = max(values.max() ?? 1.0, 1.0)
            let minVal = min(values.min() ?? 0.0, 0.0)
            let range = max(maxVal - minVal, 1.0)
            
            Path { path in
                for (index, val) in values.enumerated() {
                    let x = w * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                    let y = h - (h * CGFloat((val - minVal) / range))
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}
