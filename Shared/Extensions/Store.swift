//
//  Store.swift
//  RocketClient (iOS)
//
//  Created by Ethan John on 1/20/21.
//

import ComposableArchitecture

extension Store {
    convenience init<Environment>(reducer: Reducer<State, Action, Environment>, environment: Environment, initialState: (Environment) -> State) {
        self.init(initialState: initialState(environment), reducer: reducer, environment: environment)
    }
}
