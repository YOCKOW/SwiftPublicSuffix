/* *************************************************************************************************
 PublicSuffixTests.swift
   © 2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import PublicSuffix

final class PublicSuffixTests: XCTestCase {
  func test_nodeSet() {
    let set: PublicSuffix.Node.Set = [.termination, .label("label", next: [])]
    XCTAssertTrue(set.containsTerminationNode())
    XCTAssertNotNil(set.node(of: "label"))
    
    XCTAssertNil(set.node(of: "foo"))
    XCTAssertFalse(set.containsAnyLabelNode())
  }
}
