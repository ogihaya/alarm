import SwiftUI

struct InfoBanner: View {
    enum Style {
        case info
        case warning
        case success

        var tint: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .success: return .green
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }

    let style: Style
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(style: Style, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.style = style
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: style.icon)
                    .foregroundStyle(style.tint)
                Text(title)
                    .font(.headline)
            }
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .background(style.tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style.tint.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
