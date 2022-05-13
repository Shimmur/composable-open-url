#if !os(macOS)
import XCTest
import ComposableOpenURL
import ComposableArchitecture

class OpenURLTests: XCTestCase {
    struct AppState: Equatable {
        var url: URL?
    }
    
    enum AppAction: Equatable {
        case tappedToOpen
        case openURL(OpenURLViewAction)
    }
    
    let store = TestStore(
        initialState: AppState(),
        reducer: Reducer<AppState, AppAction, Void> { state, action, _ in
            switch action {
            case .tappedToOpen:
                state.url = URL(string: "http://example.com")
                return .none
            case .openURL:
                return .none
            }
        }.opensURL(
            state: \.url,
            action: /AppAction.openURL
        ),
        environment: ()
    )
    
    func testOpeningSupportedURL() {
        store.send(.tappedToOpen) {
            $0.url = URL(string: "http://example.com")
        }
        store.send(.openURL(.openedURL(true))) {
            $0.url = nil
        }
    }
    
    func testOpeningUnsupportedURL() {
        store.send(.tappedToOpen) {
            $0.url = URL(string: "http://example.com")
        }
        store.send(.openURL(.urlNotSupported)) {
            $0.url = nil
        }
    }
    
    func testOpeningURLFails() {
        store.send(.tappedToOpen) {
            $0.url = URL(string: "http://example.com")
        }
        store.send(.openURL(.openedURL(true))) {
            $0.url = nil
        }
    }
}
#endif
