// Module: SparkLikes — Discover filter settings.

import SwiftUI

struct LikesPreferencesSheet: View {
    @Bindable var viewModel: LikesFeedViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        String(localized: "likes.pref.gender.section", defaultValue: "想认识", comment: "Gender section"),
                        selection: $viewModel.preferences.genderPreference
                    ) {
                        ForEach(LikesGenderPreference.allCases) { pref in
                            Text(pref.localizedTitle).tag(pref)
                        }
                    }
                    Picker(
                        String(localized: "likes.pref.intent.section", defaultValue: "目的", comment: "Intent section"),
                        selection: $viewModel.preferences.intent
                    ) {
                        ForEach(LikesIntent.allCases) { intent in
                            Text(intent.localizedTitle).tag(intent)
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .navigationTitle(
                String(localized: "likes.settings.title", defaultValue: "发现偏好", comment: "Settings title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.apply", defaultValue: "应用", comment: "Apply")) {
                        Task {
                            await viewModel.reloadWithPreferences()
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    LikesPreferencesSheet(viewModel: LikesPreviewSupport.feedViewModel())
}

#Preview("Preferences — dark") {
    LikesPreviewSupport.darkMode {
        LikesPreferencesSheet(viewModel: LikesPreviewSupport.feedViewModel())
    }
}
