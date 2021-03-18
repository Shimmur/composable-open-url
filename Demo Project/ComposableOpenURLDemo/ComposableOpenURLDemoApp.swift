import ComposableArchitecture
import SwiftUI

@main
struct ComposableOpenURLDemoApp: App {
    var body: some Scene {
        WindowGroup {
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
