//
//  BuddyBrowseSearchSheet.swift
//  坐标系
//
//  搭子搜索：独立 Sheet，不用 Navigation searchable drawer。
//

import SwiftUI

struct BuddyBrowseSearchSheet: View {
    @Binding var query: String
    var prompt: String

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(prompt, text: $draft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.search)
                        .onSubmit { applyAndDismiss() }
                } footer: {
                    Text("输入后点搜索；结果会替换当前列表。清除可回到推荐浏览。")
                }
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("搜索") { applyAndDismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button("清除", role: .destructive) {
                            draft = ""
                            query = ""
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                draft = query
                focused = true
            }
        }
        .platformSheet(.filter)
    }

    private func applyAndDismiss() {
        query = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}
