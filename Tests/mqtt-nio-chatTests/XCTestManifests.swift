import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(mqtt_nio_chatTests.allTests),
    ]
}
#endif
