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
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
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
                        .foregroundColor(post.data.likes == true ? .red : .main)
                }
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            .padding(20)
        }
        .padding(10)
    }
}
