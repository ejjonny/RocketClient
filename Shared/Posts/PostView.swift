//
//  File.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import SwiftUI

struct PostView: View {
    let post: ListingResponse.ListingData.Listing
    let image: UIImage?
    var voteBlendMode: BlendMode {
        switch post.data.likes {
        case true: return .colorDodge
        case false: return .colorBurn
        case nil: return .normal
        case .some(_): fatalError()
        }
    }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Style.cornerRadius)
                .foregroundColor(.alternate)
            VStack(spacing: 20) {
                Text(post.data.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text(post.data.author)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .bold()
                        .foregroundColor(.main)
                    Spacer()
                    Text("\(post.data.score)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .bold()
                        .foregroundColor(.main)
                        .overlay(
                            Text("\(post.data.score)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .bold()
                                .foregroundColor(.main)
                                .offset(y: post.data.likes == nil ? 0 : -20)
                                .opacity(post.data.likes == nil ? 1 : 0)
                                .scaleEffect(post.data.likes == nil ? 1 : 4)
                                .rotationEffect(Angle(degrees: post.data.likes == nil ? 0 : -10), anchor: .center)
                                .animation(post.data.likes == nil ? nil : Style.animation)
                        )
                        .padding(10)
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
                                    .blendMode(voteBlendMode)
                                    .opacity(0.2)
                            }
                        )
                }
                if let image = image {
                    #if os(macOS)
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                    #else
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    #endif
                }
            }
            .padding(20)
        }
        .padding(10)
    }
}
