# ComposableOpenURL

[![CI](https://github.com/Shimmur/composable-open-url/actions/workflows/ci.yml/badge.svg)](https://github.com/Shimmur/composable-open-url/actions/workflows/ci.yml)

## State-driven URL opening for The Composable Architecture

ComposableOpenURL is a standalone component designed to be used with the [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

It comprises of a high-level reducer and a SwiftUI view modifier that you can use to embed state-driven URL opening behaviour in your own app's feature domains.

## What’s the problem this solves?

There are a number of ways to open external URLs. UIKit provides `UIApplication.shared.open` and iOS 14/macOS provides `OpenURLAction` which can be accessed from the SwiftUI Environment using the `\.openURL` environment key. In addition to this, on macOS 11/iOS 14 etc. there is the SwiftUI `Link` component.

For very simple use cases where you just want to display a link to some external URL then `Link` (or a `Button` if you need to support older platforms) is absolutely fine and probably what you need in a lot of cases. You can’t easily write an automated test for it but that might be an acceptable trade-off if you’re literally just opening some fixed external URL.

Sometimes however, you want to be able to trigger the opening of a URL as a result of some store action - this could be an action you explicitly send from your view which triggers the URL opening (perhaps alongside some other behaviour), or it could be an action sent from a button in an alert or action sheet (using TCA’s `AlertState` and `ActionSheetState` components). It could also be an action sent as the result of an `Effect`. The URL could be dynamic, or computed based on some other part of your state. It could just be the case that you want to test the behaviour.

In these cases it would be really useful to trigger an external URL opening from your reducer itself.

## An effect-based approach

One way to implement this is to treat the opening of an external URL as an `Effect`. This is probably a reasonable approach as it does feel like a side-effect. You could probably implement it something like this:

```swift
struct FeatureEnvironment {
  var openURL: (URL) -> Effect<Never, Never>
}

enum FeatureAction {
  case tappedOpenURLButton
}

let featureReducer = Reducer<FeatureState, FeatureAction, FeatureEnvironment> { state, action environment in
  switch action {
  case .tappedOpenURLButton:
    return environment
      .openURL("http://example.com")
      .fireAndForget()  
  }
}
```

Whilst this fairly straightforward and not a lot of code, it does have some downsides:

* You need to pass around the `openURL` dependency to every feature that needs to be able to open a URL (you could potentially address this using the `SystemEnvironment` idea in the TCA examples folder but its still a fair amount of boilerplate).
* Testing fire-and-forget effects is not the most ergonomic and often requires some kind of mock dependency with some mutable local state that you assert on in a `.do` block, e.g.:

```swift
var openedURL: URL?

let store = TestStore(
  initialState: ...,
  reducer: ...,
  environment: FeatureEnvironment(
    openURL: { url in openedURL = url }
  )
)

store.assert(
  .send(.tappedOpenURLButton),
  .do { _ in
    XCTAssertEqual(.some("http://example.com"), openedURL)
  }
)
```

For these reasons, inspired by the existing `TextState`, `AlertState` and `ActionSheetState` components this library takes a more state-base approach.

## State-based URL opening

The way this component works is around a feature domain based on a single value of type `URL?` - the idea is that you have some URL property in your feature domain that you set to a value you need opening and it just opens. Conceptually, the feature is saying “this is the URL that should be opened” and the actual effect of opening it in whatever external application should handle it is handled entirely in the view layer, using a SwiftUI view modifier, as a result of the state change.

There are a number of advantages to this approach:

* Minimal boilerplate - just three lines of code to integrate the URL opening domain into your feature domain, and a single SwiftUI view modifier to attach the URL opening behaviour to your view.
* Opening a URL is a one-line state mutation and you don’t even need to take care of setting it back to `nil` again once the URL has been opened as the component handles it for you.
* Easy to test - its just a state mutation so you can test this like any other state mutation using `TestStore`.
* You can directly hook into the OpenURL actions in your own feature reducer if you need to perform some additional logic or handle URLs that cannot be opened.

So with all this said, what does it actually look like? Lets adapt the previous example to use the new component.

Firstly you need to embed the URL opening domain in your feature domain:

```swift
import ComposableArchitecture
import ComposableOpenURL

struct FeatureState {
  var urlToOpen: URL? // 1. An optional URL property
}

enum FeatureAction {
  case tappedOpenURLButton
  case openURL(OpenURLViewAction) // 2. Embed the component domain actions
}

let featureReducer = Reducer<FeatureState, FeatureAction, Void> { state, action, _ in
  switch action {
  case .tappedOpenURLButton:
    state.urlToOpen = URL(string: "http://example.com") // 3. Set the URL when you want to open it
  }
}
.opensURL( // 4. Attach the component's high-level reducer
  \FeatureState.urlToOpen,
  action: /FeatureAction.openURL
)
```

Next, you need to attach the view modifier to our view amd hand it a store scoped to the URL state that you will want to open:

```swift
struct FeatureView: View {
  let store: Store<FeatureState, FeatureAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      Button("Open URL") {
        viewStore.send(.tappedOpenURLButton)
      }
    }
    .opensURL(
      store.scope(
        state: \.urlToOpen,
        action: FeatureAction.openURL
      )
    )
  }
}
```

And that’s it!

You can test this behaviour, including simulating the URL actually being opened, without the need for any mocks:

```swift
class FeatureTests: XCTestCase {
  func testOpeningURL() {
    let store = TestStore(
      initialState: FeatureState(),
      reducer: featureReducer,
      environment: ()
    )

    store.assert(
      .send(.tappedOpenURLButton) {
        $0.urlToOpen = "http://example.com"
      },
      .send(.openURL(.openedURL)) {
        $0.urlToOpen = nil
      }
    )
  }
}
```

No mocks, no dependencies, no mutable local state and no raw assertions in `.do` blocks.

## Copyright and License

This library was developed out of the work on our app here at [Community.com](http://community.com) and is made available under the [Apache 2.0 license](LICENSE).

```
Copyright 2021 Community.com, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
```
