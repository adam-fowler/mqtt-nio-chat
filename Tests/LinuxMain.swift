import XCTest

import mqtt_nio_chatTests

var tests = [XCTestCaseEntry]()
tests += mqtt_nio_chatTests.allTests()
XCTMain(tests)
