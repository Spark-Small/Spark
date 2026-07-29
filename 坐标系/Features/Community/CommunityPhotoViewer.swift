//
//  CommunityPhotoViewer.swift
//  坐标系
//

import SwiftUI

struct CommunityPhotoViewer: View {
    let photos: [CommunityPhotoRef]
    @State private var index: Int
    @State private var scale: CGFloat = 1
    @Environment(\.dismiss) private var dismiss

    init(photos: [CommunityPhotoRef], startIndex: Int = 0) {
        self.photos = photos
        _index = State(initialValue: min(max(startIndex, 0), max(photos.count - 1, 0)))
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(Array(photos.enumerated()), id: \.offset) { offset, ref in
                    CommunityRemotePhoto(ref: ref)
                        .scaleEffect(scale)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in scale = value.magnification }
                                .onEnded { _ in
                                    withAnimation(.snappy) { scale = 1 }
                                }
                        )
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
