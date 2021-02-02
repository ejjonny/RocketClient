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
    var listings = [PostState]()
    var viableRange: ClosedRange<Int>? {
        guard [0, 1, 2, 3, 4].allSatisfy(listings.indices.contains) else {
            return nil
        }
        let lowerBound: Int
        if listings.indices.contains(currentIndex - 2) {
            lowerBound = currentIndex - 2
        } else if listings.indices.contains(currentIndex - 1) {
            lowerBound = currentIndex - 1
        } else {
            lowerBound = 0
        }
        let upperBound: Int
        if listings.indices.contains(currentIndex + 2) {
            upperBound = currentIndex + 2
        } else if listings.indices.contains(currentIndex + 1) {
            upperBound = currentIndex + 1
        } else {
            upperBound = 0
        }
        return lowerBound...upperBound
    }
    var currentListings: [PostState] {
        get {
            guard let range = viableRange else { return [] }
            return Array(listings[range])
        }
        set {
            guard let range = viableRange else { return }
            listings.replaceSubrange(range, with: newValue)
        }
    }
    var currentIndex: Int = 0
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
    let getComments: (String) -> Effect<[String], Error>
    let hapticNextFeedback: () -> ()
    let postEnvironment: PostEnvironment
    static func live(_ token: @escaping () -> String?) -> ListingViewEnvironment {
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
            getComments: {
                controller
                    .getComments(articleID: $0)
                    .eraseToEffect()
            },
            hapticNextFeedback: {
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()
                #endif
            },
            postEnvironment: PostEnvironment.live(controller)
        )
    }
}
enum ListingViewAction {
    case getListings(after: Bool)
    case listingsResponse(Result<ListingResponse, Error>)
    case getCommentsForCurrent
    case getCommentsResponse(Result<[String], Error>)
    case imagesResponse(Result<[(String, UIImage)], Error>)
    case next
    case last
    case postAction(index: Int, action: PostAction)
}
let listingViewReducer = Reducer.combine(
    postReducer.forEach(
        state: \.currentListings,
        action: /ListingViewAction.postAction(index: action:),
        environment: { $0.postEnvironment }
    ),
    Reducer<ListingViewState, ListingViewAction, ListingViewEnvironment> { state, action, environment in
        switch action {
        case let .getListings(after):
            return environment
                .listings(after)
                .catchToEffect()
                .receive(on: environment.scheduler)
                .map(ListingViewAction.listingsResponse)
                .eraseToEffect()
        case .getCommentsForCurrent:
            let listing = state.listings[state.currentIndex]
            return environment
                .getComments(listing.post.data.id)
                .catchToEffect()
                .receive(on: environment.scheduler)
                .map(ListingViewAction.getCommentsResponse)
                .eraseToEffect()
        case let .getCommentsResponse(result):
            print(result)
            return .none
        case let .listingsResponse(.success(listings)):
            state.listings.append(contentsOf: listings.data.children.map(PostState.init(post:)))
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
            images.forEach { imageID, image in
                if let postIndex = state.listings.firstIndex(where: { $0.post.data.preview?.images.first?.id == imageID }) {
                    state.listings[postIndex] = PostState(post: state.listings[postIndex].post, image: EquatableImageBox(image: image))
                }
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
        case .postAction:
            return .none
        }
    }
)
