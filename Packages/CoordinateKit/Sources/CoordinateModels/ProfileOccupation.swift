//
//  ProfileOccupation.swift
//  CoordinateModels
//
//  轻量身份标签（非学历 / 非恋爱向）。
//

import Foundation

public enum ProfileOccupation: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case student = "学生"
    case employed = "上班"
    case freelance = "自由职业"
    case other = "其他"

    public var id: String { rawValue }
}
