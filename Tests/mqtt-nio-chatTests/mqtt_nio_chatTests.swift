import XCTest
@testable import mqtt_nio_chat

final class mqtt_nio_chatTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(mqtt_nio_chat().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
