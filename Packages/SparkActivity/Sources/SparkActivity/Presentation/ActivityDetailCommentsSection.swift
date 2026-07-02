// Module: SparkActivity — Activity detail discussion / comments (UI shell until API ships).

import SparkDesignSystem
import SwiftUI

struct ActivityDetailCommentsSection: View {
    let isAuthenticated: Bool
    let canParticipate: Bool
    let onSignInRequired: (() -> Void)?

    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            sectionHeader

            if canParticipate {
                composer
            } else if !isAuthenticated {
                signInPrompt
            } else {
                joinPrompt
            }

            ContentUnavailableView(
                String(
                    localized: "activity.detail.comments.empty.title",
                    defaultValue: "还没有讨论",
                    comment: "Comments empty title"
                ),
                systemImage: "text.bubble",
                description: Text(
                    String(
                        localized: "activity.detail.comments.empty.subtitle",
                        defaultValue: "向主办或参与者提问，分享集合信息。",
                        comment: "Comments empty subtitle"
                    )
                )
            )
            .frame(maxWidth: .infinity, minHeight: 140)
            .sparkContentUnavailableCanvas()
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        }
    }

    private var sectionHeader: some View {
        Text(
            String(
                localized: "activity.detail.comments.section",
                defaultValue: "讨论",
                comment: "Activity comments section"
            )
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.top, ActivityDetailMeetupLayout.sectionTopPadding)
        .padding(.bottom, SparkLayoutMetrics.compactVerticalPadding)
        .accessibilityAddTraits(.isHeader)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                String(
                    localized: "activity.detail.comments.placeholder",
                    defaultValue: "说点什么…",
                    comment: "Comment placeholder"
                ),
                text: $draft,
                axis: .vertical
            )
            .lineLimit(1 ... 4)
            .textFieldStyle(.roundedBorder)

            Button {
                draft = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(
                String(
                    localized: "activity.detail.comments.send",
                    defaultValue: "发送",
                    comment: "Send comment"
                )
            )
        }
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
    }

    private var signInPrompt: some View {
        Button(action: { onSignInRequired?() }) {
            Text(
                String(
                    localized: "activity.detail.comments.signIn",
                    defaultValue: "登录后参与讨论",
                    comment: "Sign in to comment"
                )
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
    }

    private var joinPrompt: some View {
        Text(
            String(
                localized: "activity.detail.comments.joinRequired",
                defaultValue: "报名后可在此与参与者交流。",
                comment: "Join to comment"
            )
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
    }
}

#Preview {
    ActivityDetailCommentsSection(
        isAuthenticated: true,
        canParticipate: true,
        onSignInRequired: nil
    )
}
