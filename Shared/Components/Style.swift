//
//  Style.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import SwiftUI

extension Color {
    static let main: Color = .primary
    static let alternate: Color = Color(red: 24/255, green: 41/255, blue: 82/255)
    static let tertiary: Color = Color(red: 225/255, green: 69/255, blue: 148/255)
    static let quaternary: Color = Color(red: 43/255, green: 53/255, blue: 149/255)
}
extension Text {
    func localStyle(_ textStyle: Font.TextStyle, color: Color) -> Self {
        self
            .font(.system(textStyle, design: .main))
            .foregroundColor(color)
    }
}

enum Style {
    static let cornerRadius: CGFloat = 25.0
    static let animation: Animation = .easeInOut
}

extension Font.Design {
    static let main: Font.Design = .default
}
