//
//  ProfileMBTI.swift
//  CoordinateModels
//
//  16 型 MBTI（年轻人社交常用标签；自填，非测评结果背书）。
//

import Foundation

public enum ProfileMBTI: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case INTJ, INTP, ENTJ, ENTP
    case INFJ, INFP, ENFJ, ENFP
    case ISTJ, ISFJ, ESTJ, ESFJ
    case ISTP, ISFP, ESTP, ESFP

    public var id: String { rawValue }
}
