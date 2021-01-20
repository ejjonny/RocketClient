//
//  Spinner.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/18/21.
//

import SwiftUI

struct Spinner: View {
    @State private var animate = false
    let lineWidth: CGFloat
    var body: some View {
        Circle()
            .trim(from: 0, to: animate ? 0.95 : 0)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 1, dash: [], dashPhase: 0))
            .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true))
            .rotationEffect(Angle(degrees: animate ? 360 : 0))
            .animation(Animation.linear(duration: 0.4).repeatForever(autoreverses: false))
            .aspectRatio(contentMode: .fit)
            .onAppear {
                self.animate = true
        }
        .onDisappear {
            self.animate = false
        }
        .transition(.scale)
        .padding()
    }
}

