//
//  CommunityBookmarkSheet.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

struct CommunityBookmarkSheet: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        MessagesFormSheet(title: CommunitySheetCopy.bookmarkTitle, dismissAction: .cancel) {
            List {
                Section {
                    ForEach(CommunitySheetCopy.presetCollections, id: \.self) { name in
                        Button {
                            model.saveBookmark(postID, collection: name)
                            dismiss()
                        } label: {
                            Text(name)
                                .foregroundStyle(.primary)
                        }
                    }

                    Button {
                        showCreateCollection = true
                    } label: {
                        Label(CommunitySheetCopy.createCollection, systemImage: "folder.badge.plus")
                    }
                } header: {
                    Text(CommunitySheetCopy.bookmarkToHeader)
                }
            }
            .sheet(isPresented: $showCreateCollection) {
                createCollectionSheet
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
    }

    private var createCollectionSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(CommunitySheetCopy.collectionNamePlaceholder, text: $newCollectionName)
                        .textInputAutocapitalization(.never)
                } footer: {
                    Text(CommunitySheetCopy.createCollectionFooter)
                }
            }
            .navigationTitle(CommunitySheetCopy.createCollectionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CommunitySheetCopy.cancel) {
                        newCollectionName = ""
                        showCreateCollection = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CommunitySheetCopy.create) {
                        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        model.saveBookmark(postID, collection: name)
                        newCollectionName = ""
                        showCreateCollection = false
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .platformSheet(.form)
    }
}
