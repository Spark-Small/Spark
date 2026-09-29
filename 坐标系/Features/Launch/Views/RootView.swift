//
//  RootView.swift
//  坐标系
//
//  未登录根：直接进入视频背景登录页（不再经信封引导）。
//

import SwiftUI

struct RootView: View {
    @Bindable var session: LocalAuthSession

    var body: some View {
        LoginView(session: session)
    }
}

#Preview("Launch Root") {
    RootView(session: LocalAuthSession())
}
