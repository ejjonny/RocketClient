//
//  ListingsView.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/18/21.
//

import Combine
import ComposableArchitecture
import SwiftUI

struct ListingsView: View {
    let store: Store<ListingViewState, ListingViewAction>
    @State var swipeOffset: CGFloat = 0
    @State var transitionToLast = false
    @State var transitionToNext = false
    @State var returnToPlace = false
    @State var transitionDuration: Double = 0.05
    func imageForPost(_ post: ListingResponse.ListingData.Listing) -> UIImage? {
        guard let id = post.data.preview?.images.first?.id,
              let image = ViewStore(store).images[id] else {
            return nil
        }
        return image.image
    }
    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                GeometryReader { geometry in
                    ZStack {
                        if viewStore.listings.indices.contains(viewStore.currentIndex),
                           let post = viewStore.listings[viewStore.currentIndex] {
                            PostView(post: post, image: imageForPost(post))
                                .onTapGesture(count: 2) {
                                    viewStore.send(.upvoteCurrent)
                                }
                        }
                        if viewStore.listings.indices.contains(viewStore.currentIndex + 1),
                            let nextPost = viewStore.listings[viewStore.currentIndex + 1] {
                            PostView(post: nextPost, image: imageForPost(nextPost))
                                .offset(y: geometry.size.height)
                                .transition(AnyTransition.move(edge: .bottom).animation(.default))
                        }
                        if viewStore.listings.indices.contains(viewStore.currentIndex - 1),
                            let lastPost = viewStore.listings[viewStore.currentIndex - 1] {
                            PostView(post: lastPost, image: imageForPost(lastPost))
                                .offset(y: -geometry.size.height)
                        }
                        if viewStore.listings.indices.contains(viewStore.currentIndex - 2),
                            let lastLastPost = viewStore.listings[viewStore.currentIndex - 2] {
                            PostView(post: lastLastPost, image: imageForPost(lastLastPost))
                                .offset(y: -geometry.size.height * 2)
                        }
                        if viewStore.listings.indices.contains(viewStore.currentIndex + 2),
                            let nextNextPost = viewStore.listings[viewStore.currentIndex + 2] {
                            PostView(post: nextNextPost, image: imageForPost(nextNextPost))
                                .offset(y: geometry.size.height * 2)
                        }
                    }
                    .offset(y: swipeOffset)
                    .offset(y: transitionToNext ? -geometry.size.height : 0)
                    .offset(y: transitionToLast ? geometry.size.height : 0)
                    .animation((transitionToNext || returnToPlace || transitionToLast) ? Animation.easeInOut(duration: transitionDuration) : nil)
                    .gesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { state in
                                let translation = state.location.y - state.startLocation.y
                                if translation.sign == .minus,
                                   !viewStore.listings.indices.contains(viewStore.currentIndex + 1) {
                                    swipeOffset = translation - (translation * 0.6)
                                    return
                                } else if translation.sign == .plus,
                                          !viewStore.listings.indices.contains(viewStore.currentIndex - 1) {
                                    swipeOffset = translation - (translation * 0.6)
                                    return
                                }
                                swipeOffset = state.location.y - state.startLocation.y
                            }
                            .onEnded { state in
                                let translation = state.location.y - state.startLocation.y
                                swipeOffset = 0
                                guard abs(translation) > 100 else {
                                    returnToPlace = true
                                    return
                                }
                                if translation.sign == .minus,
                                   viewStore.listings.indices.contains(viewStore.currentIndex + 1) {
                                    transitionToNext = true
                                } else if translation.sign == .plus,
                                          viewStore.listings.indices.contains(viewStore.currentIndex - 1) {
                                    transitionToLast = true
                                } else {
                                    returnToPlace = true
                                }
                            }
                    )
                    .onReceive(Just($transitionToNext).delay(for: .seconds(transitionDuration), scheduler: DispatchQueue.main)) { next in
                        guard next.wrappedValue else {
                            return
                        }
                        transitionToNext = false
                        viewStore.send(.next)
                    }
                    .onReceive(Just($returnToPlace).delay(for: .seconds(transitionDuration), scheduler: DispatchQueue.main)) { _ in
                        returnToPlace = false
                    }
                    .onReceive(Just($transitionToLast).delay(for: .seconds(transitionDuration), scheduler: DispatchQueue.main)) { last in
                        guard last.wrappedValue else {
                            return
                        }
                        transitionToLast = false
                        viewStore.send(.last)
                    }
                }
            }
            .onAppear {
                viewStore.send(.getListings(after: false))
            }
        }
    }
}



enum Vote: Equatable {
    case upVote
    case unVote
    case downVote
    var voteValue: Int {
        switch self {
        case .upVote: return 1
        case .unVote: return 0
        case .downVote: return -1
        }
    }
    var likesValue: Bool? {
        switch self {
        case .upVote: return true
        case .unVote: return nil
        case .downVote: return false
        }
    }
}
struct ListingResponse: Codable, Equatable {
    struct ListingData: Codable, Equatable {
        struct Listing: Codable, Equatable {
            struct ListingData: Codable, Equatable {
                struct Preview: Codable, Equatable {
                    struct Image: Codable, Equatable {
                        struct Resolution: Codable, Equatable {
                            let url: String
                            let width: Int
                            let height: Int
                        }
                        let id: String
                        let source: Resolution
                        let resolutions: [Resolution]
                        init(id: String, source: Resolution, resolutions: [Resolution]) {
                            self.id = id
                            self.source = source
                            self.resolutions = resolutions
                        }
                    }
                    let images: [Image]
                }
                struct Media: Codable, Equatable {
                    struct Video: Codable, Equatable {
                        let height: Int
                        let hls_url: String
                    }
                    let reddit_video: Video?
                }
                let media: Media?
                var score: Int
                let preview: Preview?
                let over_18: Bool
                let num_comments: Int
                let archived: Bool
                let author: String
                let created: Int
                let title: String
                let crosspost_parent_list: [ListingData]?
                let name: String
                var likes: Bool?
            }
            let kind: String
            var data: ListingData
        }
        let before: String?
        let after: String?
        let children: [Listing]
    }
    let kind: String
    let data: ListingData
}
