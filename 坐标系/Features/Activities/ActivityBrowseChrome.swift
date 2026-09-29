//
//  ActivityBrowseChrome.swift
//  坐标系
//
//  活动发现页顶栏 chrome。
//

import SwiftUI
import CoordinateModels

struct ActivityBrowseCategoryTitleMenu: View {
    @Binding var selection: ActivityCategory

    var body: some View {
        Picker("分类", selection: $selection) {
            ForEach(ActivityCategory.browseTitleCategories) { category in
                Label(category.title, systemImage: category.systemImage)
                    .tag(category)
            }
        }
        .pickerStyle(.inline)
    }
}
