import XCTest
@testable import ComposableOpenURL

final class ComposableOpenURLTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ComposableOpenURL().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
