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
    @State var interacting = false
    @ObservedObject var viewStore: ViewStore<ListingViewState, ListingViewAction>
    init(store: Store<ListingViewState, ListingViewAction>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }
    func postOffset(_ currentIndex: Int, geometry: GeometryProxy) -> CGFloat {
        if currentIndex == 0 {
            return 0
        } else if currentIndex == 1 {
            return -geometry.size.height
        } else {
            return -(geometry.size.height * 2)
        }
    }
    var body: some View {
        ZStack {
            if viewStore.listings.isEmpty {
                Spinner(lineWidth: 10)
                    .frame(height: 70)
            } else {
                GeometryReader { geometry in
                    ZStack {
                    VStack(spacing: 0) {
                        ForEachStore(
                            store.scope(
                                state: \.currentListings,
                                action: ListingViewAction.postAction(index:action:)
                            ),
                            content: PostView.init(store:)
                        )
                        .frame(height: geometry.size.height)
                    }
                    .offset(y: swipeOffset)
                    .offset(y: postOffset(viewStore.currentIndex, geometry: geometry))
                    .animation(.spring(response: interacting ? 0.1 : 0.15, dampingFraction: 0.75, blendDuration: 0.25))
                    .gesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { state in
                                interacting = true
                                let translation = state.location.y - state.startLocation.y
                                if translation.sign == .minus,
                                   !viewStore.listings.indices.contains(viewStore.currentIndex + 1) {
                                    swipeOffset = translation * 0.2
                                    return
                                } else if translation.sign == .plus,
                                          !viewStore.listings.indices.contains(viewStore.currentIndex - 1) {
                                    swipeOffset = translation * 0.2
                                    return
                                }
                                swipeOffset = state.location.y - state.startLocation.y
                            }
                            .onEnded { state in
                                interacting = false
                                let translation = state.location.y - state.startLocation.y
                                swipeOffset = 0
                                guard abs(translation) > 100 else {
                                    return
                                }
                                if translation.sign == .minus,
                                   viewStore.listings.indices.contains(viewStore.currentIndex + 1) {
                                    viewStore.send(.next)
                                } else if translation.sign == .plus,
                                          viewStore.listings.indices.contains(viewStore.currentIndex - 1) {
                                    viewStore.send(.last)
                                }
                            }
                    )
                }
//                    Button(action: {
//                        viewStore.send(.getCommentsForCurrent)
//                    }, label: {
//                        Rectangle()
//                            .foregroundColor(.red)
//                            .frame(width: 100, height: 100)
//                    })
                }
//                .padding([.top, .bottom], 20)
            }
        }
        .onAppear {
            viewStore.send(.getListings(after: false))
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
                let id: String
                var likes: Bool?
                let subreddit: String
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
