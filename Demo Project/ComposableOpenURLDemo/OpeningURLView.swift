//   Copyright 2021 Community.com, Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

import ComposableArchitecture
import ComposableOpenURL
import SwiftUI

private let readMe = """
  This file demonstrates how to open external URLs using state and a SwiftUI view modifier.

  SwiftUI and UIKit provide some simple tools for opening external URLs, such as the `Link`
  view and `UIApplication.shared.OpeningURL` and sometimes that is all you need for simple static
  links within your app.

  Sometimes however, you might need to trigger the opening of a URL as the result of some
  explicit action sent to the store, such as an action on an `AlertState` button or received
  from some `Effect`.

  The library comes with a utility to embed the functionality of opening URLs directly within
  your feature domain with minimal setup and allows you to trigger the opening of a URL with
  a simple state mutation, which also makes it really easy to test.
  """

// The state for this screen holds a bunch of values that will drive
struct OpeningURLState: Equatable {
    var urlToOpen: URL?
    var errorAlert: AlertState<OpeningURLAction>?
}

enum OpeningURLAction: Equatable {
    case tappedToOpen(URL?)
    case openAfterDelay(URL?, TimeInterval)
    case dismissErrorAlert
    case openURL(OpenURLViewAction)
}

struct OpeningURLEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

let openingURLReducer = Reducer<
    OpeningURLState, OpeningURLAction, OpeningURLEnvironment
> {
    state, action, environment in
    switch action {
    case let .tappedToOpen(url):
        state.urlToOpen = url
        return .none
    case let .openAfterDelay(url, delay):
        return Effect(value: url)
            .delay(for: .seconds(delay), scheduler: environment.mainQueue)
            .eraseToEffect()
            .map(OpeningURLAction.tappedToOpen)
    case .openURL(.openedURL(false)):
        state.errorAlert = .init(
            title: .init("URL Error"),
            message: .init("The URL failed to open."),
            dismissButton: .cancel()
        )
        return .none
    case .openURL(.urlNotSupported):
        state.errorAlert = .init(
            title: .init("URL Error"),
            message: .init("The URL is not supported and cannot be opened."),
            dismissButton: .cancel()
        )
        return .none
    case .dismissErrorAlert:
        state.errorAlert = nil
        return .none
    case .openURL:
        return .none
    }
}
.opensURL(
    state: \.urlToOpen,
    action: /OpeningURLAction.openURL
)

struct OpeningURLView: View {
    let store: Store<OpeningURLState, OpeningURLAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack(spacing: 20) {
                Button("Open Pointfree.co") {
                    viewStore.send(.tappedToOpen(URL(string: "https://pointfree.co")))
                }
                Button("Open TCA Github Repo") {
                    viewStore.send(.tappedToOpen(URL(string: "https://github.com/pointfreeco/swift-composable-architecture")))
                }
                Button("Open URL with delayed effect") {
                    viewStore.send(.openAfterDelay(URL(string: "http://example.com"), 2))
                }
                Button("Open unsupported URL") {
                    viewStore.send(.tappedToOpen(URL(string: "gopher://localhost:10000")))
                }
            }
        }
        .navigationBarTitle("Opening URLs")
        .alert(
            store.scope(state: \.errorAlert),
            dismiss: .dismissErrorAlert
        )
        .opensURL(
            store.scope(
                state: \.urlToOpen,
                action: OpeningURLAction.openURL
            )
        )
    }
}

struct OpeningURLView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OpeningURLView(
                store: Store(
                    initialState: OpeningURLState(),
                    reducer: openingURLReducer,
                    environment: OpeningURLEnvironment(
                        mainQueue: DispatchQueue.main.eraseToAnyScheduler()
                    )
                )
            )
        }
    }
}
