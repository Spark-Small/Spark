// Module: SparkDesignSystem — Cross-tab identity sheet content.

import SwiftUI

public struct SparkUnifiedIdentityContent<PrimaryAction: View>: View {
    let model: SparkUnifiedIdentityModel
    let primaryAction: PrimaryAction

    public init(
        model: SparkUnifiedIdentityModel,
        @ViewBuilder primaryAction: () -> PrimaryAction
    ) {
        self.model = model
        self.primaryAction = primaryAction()
    }

    public var body: some View {
        VStack(spacing: 20) {
            avatar
            Text(model.displayName)
                .font(.title2.weight(.semibold))
            if !model.bio.isEmpty {
                Text(model.bio)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            if let relationshipLabel = model.relationshipLabel {
                Text(relationshipLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .sparkGlassControl(Capsule())
            }
            if let trustScore = model.trustScore {
                Label(
                    String(
                        format: String(
                            localized: "identity.trustScore.format",
                            defaultValue: "信任分 %lld",
                            comment: "Trust score; %lld is score"
                        ),
                        locale: .current,
                        trustScore
                    ),
                    systemImage: model.hasLiveness ? "checkmark.seal.fill" : "shield"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            primaryAction
        }
        .padding()
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = model.avatarURL {
            SparkCachedRemoteImage(
                url: url,
                maxPixelSize: 768,
                content: { image in
                    image.resizable().scaledToFill().accessibilityHidden(true)
                },
                placeholder: {
                    Color(.tertiarySystemFill)
                }
            )
            .frame(width: 88, height: 88)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 88, height: 88)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

extension SparkUnifiedIdentityContent where PrimaryAction == EmptyView {
    public init(model: SparkUnifiedIdentityModel) {
        self.init(model: model) { EmptyView() }
    }
}

#Preview {
    SparkUnifiedIdentityContent(
        model: SparkUnifiedIdentityModel(
            id: "u1",
            displayName: "Alex",
            bio: "周末徒步 · 咖啡",
            trustScore: 72,
            hasLiveness: true,
            relationshipLabel: "已配对"
        )
    ) {
        Button("发消息") {}
    }
}
