//
//  RocketButton.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import SwiftUI

struct RocketButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    var body: some View {
        Button(
            action: action,
            label: {
                label()
                    .padding(30)
                    .background(
                        Capsule(style: .circular)
                            .foregroundColor(.alternate)
                    )
            }
        )
    }
}
