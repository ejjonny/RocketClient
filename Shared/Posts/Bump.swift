//
//  Bump.swift
//  RocketClient
//
//  Created by Ethan John on 1/20/21.
//

import SwiftUI

extension View {
    func bump(_ blendMode: BlendMode = .normal) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous)
                        .foregroundColor(.alternate)
                        .shadow(color: .alternate, radius: 5, x: -5, y: -5)
                        .blendMode(.screen)
                        .opacity(0.2)
                    RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous)
                        .foregroundColor(.alternate)
                        .shadow(color: .black, radius: 5, x: 5, y: 5)
                        .opacity(0.2)
                    RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous)
                        .foregroundColor(.alternate)
                        .blendMode(blendMode)
                        .opacity(0.2)
                }
            )
    }
}
