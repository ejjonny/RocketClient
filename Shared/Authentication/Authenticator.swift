//
//  Authenticator.swift
//  RocketClient
//
//  Created by Ethan John on 1/18/21.
//

import Combine
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

class Authenticator {
    enum TokenCallType {
        case authenticate(code: String)
        case refresh
    }
    let clientID = "o5JA03c-WT7yiw"
    let stateString = "rocketClient88"
    let redirectURI = "rocketClient://response"
    let duration = "permanent"
    let scope = "identity,edit,flair,history,modconfig,modflair,modlog,modposts,modwiki,mysubreddits,privatemessages,read,report,save,submit,subscribe,vote,wikiedit,wikiread"
    var consentURL: URL? {
        URL(string: "https://www.reddit.com/api/v1/authorize.compact?client_id=\(clientID)&response_type=code&state=\(stateString)&redirect_uri=\(redirectURI)&duration=\(duration)&scope=\(scope)")
    }
    @UserDefault(key: "rocketClient.refreshToken", defaultValue: nil)
    var refreshToken: String?
    @UserDefault(key: "rocketClient.token", defaultValue: nil)
    var token: String?
    
    func launchConsentPage() {
        // https://www.reddit.com/api/v1/authorize?client_id=CLIENT_ID&response_type=TYPE&state=RANDOM_STRING&redirect_uri=URI&duration=DURATION&scope=SCOPE_STRING
        if let url = consentURL {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            UIApplication.shared.open(url)
            #endif
        }
    }
    
    func stateIsValid(_ state: String) -> Bool {
        stateString == state
    }
    
    func tokenCall(_ callType: TokenCallType) -> AnyPublisher<Void, Error> {
        var request = URLRequest(url: URL(string: "https://www.reddit.com/api/v1/access_token")!)
        request.httpMethod = "POST"
        let parameters: [String: Any]
        switch callType {
        case let .authenticate(code):
            parameters = [
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": redirectURI,
                "duration": "permanent"
            ]
        case .refresh:
            parameters = [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken ?? ""
            ]
        }
        request.httpBody = parameters.percentEncoded()
        let credentials = "\(clientID):".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        return URLSession.shared
            .dataTaskPublisher(for: request)
            .tryMap { try JSONDecoder().decode(AuthResponse.self, from: $0.0) }
            .handleEvents(receiveOutput: { response in
                self.refreshToken = response.refresh ?? ""
                self.token = response.token
            })
            .handleEvents(
                receiveOutput: { response in
                    self.refreshToken = response.refresh ?? ""
                    self.token = response.token
                }
            )
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    enum AuthError: Error {
        case badRequest
    }
    struct AuthResponseData: Codable {
        let message: String
        let error: Int
    }

    struct AuthResponse: Codable {
//        {
//            "access_token": Your access token,
//            "token_type": "bearer",
//            "expires_in": Unix Epoch Seconds,
//            "scope": A scope string,
//            "refresh_token": Your refresh token
//        }
        let token: String
        let tokenType: String
        let expires: Int
        let scope: String
        let refresh: String?
        enum CodingKeys: String, CodingKey {
            case token = "access_token"
            case tokenType = "token_type"
            case expires = "expires_in"
            case scope = "scope"
            case refresh = "refresh_token"
        }
    }
}

