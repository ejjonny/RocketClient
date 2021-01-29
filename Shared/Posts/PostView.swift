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
                    VStack {
                        Text("r/\(post.data.subreddit)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .bold()
                            .foregroundColor(.main)
                        Spacer()
                            .frame(height: 5)
                        Text("u/\(post.data.author)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .bold()
                            .foregroundColor(.main)
                    }
                    .frame(alignment: .leading)
                    .padding(10)
                    Spacer()
                    ZStack {
                        Text("\(post.data.score)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .bold()
                            .foregroundColor(.main)
                            .frame(maxHeight: .infinity)
                            .padding(10)
                        Text("\(post.data.score)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .bold()
                            .foregroundColor(.main)
                            .offset(y: post.data.likes == nil ? 0 : -20)
                            .opacity(post.data.likes == nil ? 1 : 0)
                            .scaleEffect(post.data.likes == nil ? 1 : 4)
                            .rotationEffect(Angle(degrees: post.data.likes == nil ? 0 : -10), anchor: .center)
                    }
                }
                .frame(maxHeight: 70)
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
    }
}
