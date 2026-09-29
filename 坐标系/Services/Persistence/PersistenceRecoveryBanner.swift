//
//  PersistenceRecoveryBanner.swift
//  坐标系
//
//  SwiftData 降级 / Gateway 写失败提示（Apple HIG：错误可理解、可行动）。
//

import SwiftUI

struct PersistenceRecoveryBanner: View {
    @Environment(AppPersistenceHealth.self) private var persistenceHealth

    var body: some View {
        VStack(spacing: 0) {
            if persistenceHealth.isUsingEphemeralStore {
                Label {
                    Text("本地存储异常：本会话数据可能在退出后丢失，请清理空间后重启 App。")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12))
                .accessibilityElement(children: .combine)
            }

            if let message = persistenceHealth.writeFailureMessage {
                HStack(alignment: .top, spacing: PlatformMetrics.minContentGap) {
                    Label {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    } icon: {
                        Image(systemName: "externaldrive.badge.exclamationmark")
                            .foregroundStyle(.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button("关闭") {
                        persistenceHealth.dismissWriteFailure()
                    }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.10))
                .accessibilityElement(children: .combine)
            }
        }
    }
}
