import XCTest

import PublicSuffixTests

var tests = [XCTestCaseEntry]()
tests += PublicSuffixTests.__allTests()

XCTMain(tests)
