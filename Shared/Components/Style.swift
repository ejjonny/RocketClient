//
//  Style.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import SwiftUI

extension Color {
    static let main: Color = .primary
    static let alternate: Color = .blue
}
extension Text {
    func localStyle(_ textStyle: Font.TextStyle, color: Color) -> Self {
        self
            .font(.system(textStyle, design: .rounded))
            .foregroundColor(color)
    }
}

enum Style {
    static let cornerRadius: CGFloat = 25.0
    static let animation: Animation = .easeInOut
}
