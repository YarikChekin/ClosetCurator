// DesignTokens.swift
// Centralized design constants for Closet Curator
//
// ✔ HIG: System colors, 8pt grid, 10pt corner radius

import SwiftUI

struct DesignTokens {
    // Spacing
    static let spacing8: CGFloat = 8
    static let spacing16: CGFloat = 16
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    
    // Corner Radius
    static let cardCornerRadius: CGFloat = 10
    static let buttonCornerRadius: CGFloat = 10
    
    // System Colors (semantic)
    static let primaryColor = Color.primary
    static let secondaryColor = Color.secondary
    static let accent = Color.accentColor
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    // Tappable area
    static let minTappable: CGFloat = 44
} 