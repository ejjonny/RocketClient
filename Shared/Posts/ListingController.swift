//
//  ListingController.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import Foundation
import Combine
#if os(macOS)
import AppKit
#else
import UIKit
#endif

class ListingController {
    enum ListingError: Error {
        case needAuthentication
    }
    let token: () -> String?
    init(token: @escaping () -> String?) {
        self.token = token
    }
    var listings = [ListingResponse.ListingData.Listing]()
    var cancellables = Set<AnyCancellable>()
    var images = [String: UIImage]()
    var lastItem: String?
    func loadImages(listings: ListingResponse) -> AnyPublisher<[(String, UIImage)], Error> {
        let previews = listings.data.children
            .map(\.data)
            .compactMap(\.preview)
            .flatMap(\.images)
            .compactMap { imagePublisher(id: $0.id, $0.source.url) }
        return Publishers.Sequence(sequence: previews)
            .setFailureType(to: Never.self)
            .flatMap { $0 }
            .collect()
            .eraseToAnyPublisher()
    }
    func tokenIsValid() -> Bool {
        guard let token = token(),
              !token.isEmpty else {
            return false
        }
        return true
    }
    func imagePublisher( id: String, _ url: String) -> AnyPublisher<(String, UIImage), Error>? {
        guard let url = URL(string: url.replacingOccurrences(of: "&amp;", with: "&")) else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return URLSession.shared
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .compactMap { UIImage(data: $0.0) }
            .mapError { error in error }
            .map { (id, $0) }
            .eraseToAnyPublisher()
    }
    func getListings(after: Bool) -> AnyPublisher<ListingResponse, Error> {
        guard tokenIsValid() else {
            return Fail(error: ListingError.needAuthentication)
                .eraseToAnyPublisher()
        }
        var components = URLComponents(url: URL(string: "https://oauth.reddit.com/hot")!, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem]()
        components.queryItems?.append(URLQueryItem(name: "limit", value: "25"))
        if after,
           let lastItem = lastItem {
            components.queryItems?.append(URLQueryItem(name: "after", value: lastItem))
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token() ?? "")", forHTTPHeaderField: "Authorization")
        return URLSession.shared
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap {
//                print($0.0.prettyPrintedJSONString ?? "")
                return try JSONDecoder().decode(ListingResponse.self, from: $0.0)
            }
            .handleEvents(receiveOutput: { listings in
                self.listings.append(contentsOf: listings.data.children)
                self.lastItem = listings.data.after
            })
            .eraseToAnyPublisher()
    }
    func voteCurrent(_ post: String, vote: Vote) -> AnyPublisher<Void, Error> {
        guard tokenIsValid() else {
            return Fail(error: ListingError.needAuthentication)
                .eraseToAnyPublisher()
        }
        var request = URLRequest(url: URL(string: "https://oauth.reddit.com/api/vote?dir=\(vote.voteValue)&id=\(post)")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token() ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("ios:\(Bundle.main.bundleIdentifier!):v0.0.1", forHTTPHeaderField: "User-Agent")
        return URLSession.shared
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .map { _ in
//                print($0)
                return ()
            }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    func getComments(articleID: String) -> AnyPublisher<[String], Error> {
        guard tokenIsValid() else {
            return Fail(error: ListingError.needAuthentication)
                .eraseToAnyPublisher()
        }
        let url = URL(string: "https://oauth.reddit.com/comments/\(articleID)")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "context", value: "1"),
            URLQueryItem(name: "showedits", value: "true"),
            URLQueryItem(name: "showmedia", value: "true"),
            URLQueryItem(name: "showmore", value: "true"),
            URLQueryItem(name: "showtitle", value: "true"),
            URLQueryItem(name: "sort", value: "top"),
            URLQueryItem(name: "theme", value: "default"),
            URLQueryItem(name: "threaded", value: "true"),
            URLQueryItem(name: "truncate", value: "10")
        ]
        var request = URLRequest(url: URL(string: "\(components.url!.absoluteString).json")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token() ?? "")", forHTTPHeaderField: "Authorization")
        return URLSession.shared
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap {
                return try JSONDecoder().decode([String].self, from: $0.0)
            }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
