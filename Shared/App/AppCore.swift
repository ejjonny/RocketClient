//
//  AppCore.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import ComposableArchitecture
import Combine

struct AppState: Equatable {
    var authenticationState: AuthenticationState
    var listingState: ListingViewState
}
extension AppState {
    init(_ environment: AppEnvironment) {
        guard environment.authenticationEnvironment.token() != nil else {
            self.authenticationState = AuthenticationState(authState: .waitingOnUser)
            self.listingState = ListingViewState()
            return
        }
        self.authenticationState = AuthenticationState(authState: .authenticated)
        self.listingState = ListingViewState()
    }
}
enum AppAction {
    case authenticationAction(AuthenticationAction)
    case listingAction(ListingViewAction)
}
struct AppEnvironment {
    let authenticationEnvironment: AuthenticationEnvironment
    let listingEnvironment: ListingViewEnvironment
    static func live() -> AppEnvironment {
        let authEnv = AuthenticationEnvironment.live()
        return AppEnvironment(
            authenticationEnvironment: .live(),
            listingEnvironment: .live(authEnv.token)
        )
    }
}
let appReducer = Reducer.combine(
    authenticationReducer
        .pullback(
            state: \AppState.authenticationState,
            action: /AppAction.authenticationAction,
            environment: { (global: AppEnvironment) -> AuthenticationEnvironment in
                global.authenticationEnvironment
            }
        ),
    listingViewReducer
        .pullback(
            state: \AppState.listingState,
            action: /AppAction.listingAction,
            environment: { (global: AppEnvironment) -> ListingViewEnvironment in
                global.listingEnvironment
            }
        ),
    Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
        switch action {
        case .authenticationAction:
            return .none
        case let .listingAction(listingAction):
            switch listingAction {
            case .listingsResponse(.failure):
                state.authenticationState.authState = .waitingOnUser
                return Just(AppAction.authenticationAction(.refreshAuthentication))
                    .eraseToEffect()
            case .listingsResponse,
                 .imagesResponse,
                 .getListings,
                 .next,
                 .last,
                 .upvoteCurrent,
                 .downvoteCurrent,
                 .voteResponse:
                return .none
            }
        }
    }
)
