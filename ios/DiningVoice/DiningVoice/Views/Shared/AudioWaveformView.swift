import SwiftUI

struct AudioWaveformView: View {
    let isActive: Bool
    let level: Float
    let isPaused: Bool

    @State private var bars: [CGFloat] = Array(repeating: 0.1, count: 30)

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<bars.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.15).delay(Double(index) * 0.01),
                        value: bars[index]
                    )
            }
        }
        .frame(height: 60)
        .onChange(of: level) { _, newLevel in
            guard isActive, !isPaused else { return }
            updateBars(level: newLevel)
        }
        .onChange(of: isPaused) { _, paused in
            if paused {
                bars = bars.map { _ in 0.1 }
            }
        }
    }

    private var barColor: Color {
        if isPaused { return .gray.opacity(0.4) }
        if isActive { return AppColors.primary }
        return .gray.opacity(0.3)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 4
        let maxHeight: CGFloat = 56
        return base + bars[index] * maxHeight
    }

    private func updateBars(level: Float) {
        var newBars = bars
        newBars.removeFirst()
        let randomVariation = Float.random(in: -0.1...0.1)
        let normalized = CGFloat(min(max(level + randomVariation, 0), 1))
        newBars.append(normalized)
        bars = newBars
    }
}
