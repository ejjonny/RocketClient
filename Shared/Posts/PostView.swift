//
//  File.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import ComposableArchitecture
import SwiftUI

enum PostAction {
    case upvoteCurrent
    case voteResponse(Result<Void, Error>)
    case downvoteCurrent
}

struct PostState: Equatable, Identifiable {
    let id = UUID()
    var post: ListingResponse.ListingData.Listing
    let image: EquatableImageBox?
    init(post: ListingResponse.ListingData.Listing) {
        self.post = post
        self.image = nil
    }
    init(post: ListingResponse.ListingData.Listing, image: EquatableImageBox? = nil) {
        self.post = post
        self.image = image
    }
}

struct PostEnvironment {
    let scheduler: AnySchedulerOf<DispatchQueue>
    let vote: (String, Vote) -> Effect<Void, Error>
    let hapticFeedback: () -> ()
    static func live(_ controller: ListingController) -> PostEnvironment {
        PostEnvironment(
            scheduler: AnySchedulerOf<DispatchQueue>(DispatchQueue.main),
            vote: {
                controller
                    .voteCurrent($0, vote: $1)
                    .eraseToEffect()
            },
            hapticFeedback: {
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()
                #endif
            }
        )
    }
}

let postReducer = Reducer<PostState, PostAction, PostEnvironment> { state, action, environment in
    switch action {
    case .upvoteCurrent:
        let vote: Vote
        if state.post.data.likes == true {
            vote = .unVote
            state.post.data.score -= Vote.upVote.voteValue
        } else {
            state.post.data.score += Vote.upVote.voteValue
            vote = .upVote
        }
        state.post.data.likes = vote.likesValue
        return environment
            .vote(state.post.data.name, vote)
            .catchToEffect()
            .receive(on: environment.scheduler)
            .map(PostAction.voteResponse)
            .eraseToEffect()

    case .downvoteCurrent:
        let vote: Vote
        if state.post.data.likes == false {
            vote = .unVote
            state.post.data.score -= Vote.downVote.voteValue
        } else {
            vote = .downVote
            state.post.data.score += Vote.downVote.voteValue
        }
        state.post.data.likes = vote.likesValue
        return environment
            .vote(state.post.data.name, vote)
            .catchToEffect()
            .receive(on: environment.scheduler)
            .map(PostAction.voteResponse)
            .eraseToEffect()
    case let .voteResponse(result):
        switch result {
        case .success:
            return .fireAndForget {
                environment
                    .hapticFeedback()
            }
        case let .failure(error):
            print(error)
            return .none
        }
    }
}

struct PostView: View {
    let store: Store<PostState, PostAction>
    @ObservedObject var viewStore: ViewStore<PostState, PostAction>
    var voteColor: Color {
        switch viewStore.post.data.likes {
        case nil:
            return .main
        case .some(true):
            return .tertiary
        case .some(false):
            return .quaternary
        }
    }
    init(store: Store<PostState, PostAction>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }
    var body: some View {
        ZStack {
            ZStack {
                VStack {
                    if let image = viewStore.image {
                        #if os(macOS)
                        Image(nsImage: image.image)
                            .resizable()
                            .scaledToFit()
                        #else
                        Image(uiImage: image.image)
                            .resizable()
                            .scaledToFit()
                        #endif
                    }
                    Spacer(minLength: 0)
                }
                VStack {
                    Spacer()
                    HStack {
                        Text(viewStore.post.data.title)
                            .font(.system(size: 20, weight: .bold, design: .main))
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 20) {
                            ZStack {
                                Text("\(viewStore.post.data.score)")
                                    .font(.system(size: 15, weight: .bold, design: .main))
                                    .bold()
                                    .foregroundColor(voteColor)
                                Text("\(viewStore.post.data.score)")
                                    .font(.system(size: 15, weight: .bold, design: .main))
                                    .bold()
                                    .foregroundColor(voteColor)
                                    .offset(y: viewStore.post.data.likes == nil ? 0 : -20)
                                    .opacity(viewStore.post.data.likes == nil ? 1 : 0)
                                    .scaleEffect(viewStore.post.data.likes == nil ? 1 : 4)
                                    .rotationEffect(Angle(degrees: viewStore.post.data.likes == nil ? 0 : -10), anchor: .center)
                            }
                            .onTapGesture(count: 2) {
                                viewStore.send(.downvoteCurrent)
                            }
                            .onTapGesture(count: 1) {
                                viewStore.send(.upvoteCurrent)
                            }
                            Text("r/\(viewStore.post.data.subreddit)")
                                .font(.system(size: 15, weight: .bold, design: .main))
                                .bold()
                                .foregroundColor(.main)
                            Text("u/\(viewStore.post.data.author)")
                                .font(.system(size: 10, weight: .bold, design: .main))
                                .bold()
                                .foregroundColor(.main)
                        }
                    }
                }
                .padding(30)
                .shadow(color: .black, radius: 10, x: 0, y: 10)
                .background(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [.black, .clear]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(0.5)
                )
            }
        }
    }
}
