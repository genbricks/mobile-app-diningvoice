import SwiftUI

struct SentimentBadge: View {
    let sentiment: SentimentType
    var confidence: Double?
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: sentiment.iconName)
                .font(compact ? .caption2 : .caption)

            Text(sentiment.displayName)
                .font(compact ? .caption2 : .caption)
                .fontWeight(.semibold)

            if let confidence, !compact {
                Text("\(Int(confidence * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 3 : 5)
        .background(AppColors.sentimentColor(sentiment).opacity(0.15))
        .foregroundStyle(AppColors.sentimentColor(sentiment))
        .clipShape(Capsule())
    }
}

struct UrgencyBadge: View {
    let score: Double

    private var level: String {
        if score >= 0.7 { return "High" }
        if score >= 0.4 { return "Medium" }
        return "Low"
    }

    private var color: Color {
        if score >= 0.7 { return .red }
        if score >= 0.4 { return .orange }
        return .green
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "bolt.fill")
                .font(.caption2)
            Text(level)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}
