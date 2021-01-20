//
//  AuthenticationView.swift
//  Shared
//
//  Created by Ethan John on 1/18/21.
//

import Combine
import ComposableArchitecture
import SwiftUI

struct AuthenticationView: View {
    let store: Store<AuthenticationState, AuthenticationAction>
    var slide: AnyTransition {
        AnyTransition.asymmetric(
            insertion: AnyTransition.move(edge: .trailing).combined(with: AnyTransition.opacity.animation(.default)),
            removal: AnyTransition.move(edge: .leading).combined(with: AnyTransition.opacity.animation(.default))
        )
    }
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                switch viewStore.authState {
                case .authenticated:
                    EmptyView()
                case .showSuccess:
                    VStack {
                        Text("We're in!")
                            .font(.system(size: 70, weight: .bold, design: .rounded))
                            .bold()
                            .lineLimit(nil)
                            .foregroundColor(.main)
                    }
                    .transition(slide)
                    .animation(.default)
                case .error:
                    VStack {
                        Text("Something went wrong!")
                            .font(.system(size: 70, weight: .bold, design: .rounded))
                            .bold()
                            .lineLimit(nil)
                            .foregroundColor(.main)
                        Spacer()
                        RocketButton(action: {
                            viewStore.send(.openAuthWindow)
                        }) {
                            HStack {
                                Text("Try Again")
                                    .localStyle(.largeTitle, color: .main)
                                    .bold()
                                Spacer()
                                    .frame(width: 10)
                            }
                        }
                    }
                    .transition(slide)
                    .animation(.default)
                case .loading:
                    VStack {
                        Text("Sign in using your browser")
                            .font(.system(size: 70, weight: .bold, design: .rounded))
                            .bold()
                            .lineLimit(nil)
                            .foregroundColor(.main)
                        Spacer()
                        RocketButton(action: {
                            viewStore.send(.openAuthWindow)
                        }) {
                            HStack {
                                Text("Not Working?")
                                    .localStyle(.largeTitle, color: .main)
                                    .bold()
                                Spacer()
                                    .frame(width: 10)
                            }
                        }
                    }
                    .transition(slide)
                    .animation(.default)
                case .waitingOnUser:
                    VStack {
                        Spacer()
                        Text("Let's set things up!\n\nSign in using your browser")
                            .font(.system(size: 70, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.main)
                            .frame(maxWidth: .infinity)
                        Spacer()
                        RocketButton(action: {
                            viewStore.send(.openAuthWindow)
                        }) {
                            HStack {
                                Text("Sign In")
                                    .localStyle(.largeTitle, color: .main)
                                    .bold()
                            }
                        }
                        Spacer()
                    }
                    .transition(slide)
                    .animation(.default)
                }
            }
            .onOpenURL { viewStore.send(.authUrlResponse($0)) }
            .padding(20)
        }
    }
}
