//
//  RocketClientApp.swift
//  Shared
//
//  Created by Ethan John on 1/18/21.
//

import ComposableArchitecture
import Combine
import SwiftUI

@main
struct RocketClientApp: App {
    let store = Store(reducer: appReducer, environment: AppEnvironment.live(), initialState: AppState.init)
    var body: some Scene {
        WindowGroup {
            WithViewStore(store) { viewStore in
                switch viewStore.authenticationState.authState {
                case .authenticated:
                    ListingsView(store: store.scope(state: \.listingState, action: { AppAction.listingAction($0) }))
                default:
                    AuthenticationView(store: store.scope(state: \.authenticationState, action: { AppAction.authenticationAction($0) }))
                }
            }
        }
    }
}
