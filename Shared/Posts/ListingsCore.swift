//
//  ListingsCore.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import Combine
import ComposableArchitecture
import SwiftUI

struct ListingViewState: Equatable {
    var listings = [ListingResponse.ListingData.Listing]()
    var currentIndex: Int = 0
    var images = [String: EquatableImageBox]()
}
struct EquatableImageBox: Equatable {
    let image: UIImage
    static func ==(lhs: EquatableImageBox, rhs: EquatableImageBox) -> Bool {
        return false
    }
}
struct ListingViewEnvironment {
    let scheduler: AnySchedulerOf<DispatchQueue>
    let listings: (Bool) -> Effect<ListingResponse, Error>
    let images: (ListingResponse) -> Effect<[(String, UIImage)], Error>
    let upvote: (String, Vote) -> Effect<Void, Error>
    let hapticNextFeedback: () -> ()
    static func live(token: String) -> ListingViewEnvironment {
        let controller = ListingController(token: token)
        return ListingViewEnvironment(
            scheduler: AnySchedulerOf<DispatchQueue>(DispatchQueue.main),
            listings: {
                controller
                    .getListings(after: $0)
                    .eraseToEffect()
            },
            images: {
                controller
                    .loadImages(listings: $0)
                    .eraseToEffect()
            },
            upvote: {
                controller
                    .voteCurrent($0, vote: $1)
                    .eraseToEffect()
            },
            hapticNextFeedback: {
                UIImpactFeedbackGenerator(style: .medium)
                    .impactOccurred()
            }
        )
    }
}
enum ListingViewAction {
    case getListings(after: Bool)
    case listingsResponse(Result<ListingResponse, Error>)
    case imagesResponse(Result<[(String, UIImage)], Error>)
    case next
    case last
    case upvoteCurrent
    case upvoteCurrentResponse(Result<Void, Error>)
}
let listingViewReducer = Reducer<ListingViewState, ListingViewAction, ListingViewEnvironment> { state, action, environment in
    switch action {
    case let .getListings(after):
        return environment
                .listings(after)
                .catchToEffect()
                .receive(on: environment.scheduler)
                .map(ListingViewAction.listingsResponse)
                .eraseToEffect()
    case let .listingsResponse(.success(listings)):
        state.listings.append(contentsOf: listings.data.children)
        return environment
            .images(listings)
            .catchToEffect()
            .receive(on: environment.scheduler)
            .map(ListingViewAction.imagesResponse)
            .eraseToEffect()
    case let .listingsResponse(.failure(error)):
        print(error)
        return .none
    case let .imagesResponse(.success(images)):
        images.forEach {
            state.images[$0.0] = EquatableImageBox(image: $0.1)
        }
        return .none
    case .imagesResponse(.failure):
        print("Images failed")
        return .none
    case .next:
        guard state.listings.indices.contains(state.currentIndex + 1) else {
            return .none
        }
        var effects = [Effect<ListingViewAction, Never>]()
        if state.listings.count - state.currentIndex < 5 {
            effects.append(
                Just(ListingViewAction.getListings(after: true))
                    .receive(on: environment.scheduler)
                    .eraseToEffect()
            )
        }
        state.currentIndex = state.currentIndex + 1
        effects.append(
            .fireAndForget {
                environment.hapticNextFeedback()
            }
        )
        return Effect.merge(effects)
    case .last:
        guard state.listings.indices.contains(state.currentIndex - 1) else {
            return .none
        }
        state.currentIndex = state.currentIndex - 1
        return .fireAndForget {
            environment.hapticNextFeedback()
        }
    case .upvoteCurrent:
        let listing = state.listings[state.currentIndex]
        let vote: Vote
        if listing.data.likes == true {
            vote = .unVote
        } else {
            vote = .upVote
        }
        state.listings[state.currentIndex].data.score += vote.voteValue
        state.listings[state.currentIndex].data.likes = vote.likesValue
        return environment
            .upvote(listing.data.name, vote)
            .catchToEffect()
            .receive(on: environment.scheduler)
            .map(ListingViewAction.upvoteCurrentResponse)
            .eraseToEffect()
    case .upvoteCurrentResponse(.success):
        return .fireAndForget {
            environment
                .hapticNextFeedback()
        }
    case .upvoteCurrentResponse(.failure):
        return .none
    }
}
