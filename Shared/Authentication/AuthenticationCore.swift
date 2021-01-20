//
//  AuthenticationCore.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import ComposableArchitecture
import Combine

let authenticationReducer = Reducer<AuthenticationState, AuthenticationAction, AuthenticationEnvironment> { state, action, environment in
    switch action {
    case .refreshAuthentication:
        return environment
            .refresh()
            .mapError { _ in AuthenticationState.AppError.authFailed }
            .catchToEffect()
            .receive(on: environment.scheduler)
            .map(AuthenticationAction.authenticateResponse)
            .eraseToEffect()
    case .refreshAuthenticationResponse(.success):
        return .none
    case .refreshAuthenticationResponse(.failure):
        state.authState = .waitingOnUser
        return .none
    case .openAuthWindow:
        state.authState = .loading
        return .fireAndForget {
            environment.openAuthInBrowser()
        }
    case let .authUrlResponse(url):
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems?.reduce(into: [String: String](), { $0[$1.name] = $1.value }),
              let authState = queryItems["state"],
              let code = queryItems["code"],
              environment.stateIsValid(authState) else {
            state.authState = .error
            return .none
        }
        return environment
            .authenticate(code)
            .mapError { _ in AuthenticationState.AppError.authFailed }
            .catchToEffect()
            .receive(on: environment.scheduler)
            .map(AuthenticationAction.authenticateResponse)
            .eraseToEffect()
    case .authenticateResponse(.success):
        state.authState = .showSuccess
        return Just(AuthenticationAction.exitAuthentication)
            .delay(for: 1.5, scheduler: environment.scheduler)
            .eraseToEffect()
    case .authenticateResponse(.failure):
        state.authState = .error
        return .none
    case .exitAuthentication:
        state.authState = .authenticated
        return .none
    }
}

struct AuthenticationState: Equatable {
    enum AppError: Error, Equatable {
        case authFailed
    }
    enum AuthState {
        case authenticated
        case showSuccess
        case error
        case loading
        case waitingOnUser
    }
    var authState: AuthState = .waitingOnUser
}
enum AuthenticationAction {
    case refreshAuthentication
    case refreshAuthenticationResponse(Result<Void, AuthenticationState.AppError>)
    case openAuthWindow
    case authUrlResponse(URL)
    case authenticateResponse(Result<Void, AuthenticationState.AppError>)
    case exitAuthentication
}
struct AuthenticationEnvironment {
    let scheduler: AnySchedulerOf<DispatchQueue>
    let openAuthInBrowser: () -> ()
    let stateIsValid: (String) -> Bool
    let authenticate: (String) -> Effect<Void, Error>
    let refresh: () -> Effect<Void, Error>
    let token: () -> (String?)
    let authenticator: Authenticator
    static func live() -> AuthenticationEnvironment {
        let authenticator = Authenticator()
        return AuthenticationEnvironment(
            scheduler: AnySchedulerOf<DispatchQueue>(DispatchQueue.main),
            openAuthInBrowser: { authenticator.launchConsentPage() },
            stateIsValid: authenticator.stateIsValid,
            authenticate: { authenticator.tokenCall(.authenticate(code: $0)).eraseToEffect() },
            refresh: { authenticator.tokenCall(.refresh).eraseToEffect() },
            token: { authenticator.token },
            authenticator: authenticator
        )
    }
}
