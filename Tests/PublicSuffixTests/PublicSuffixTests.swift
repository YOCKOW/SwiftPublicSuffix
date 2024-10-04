/* *************************************************************************************************
 PublicSuffixTests.swift
   © 2019,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import PublicSuffix

#if swift(>=6) && canImport(Testing)
import Testing

@Test("Node.Set Test") func nodeSetTest() {
  let set: PublicSuffix.Node.Set = [.termination, .label("label", next: [.termination])]
  #expect(set.containsTerminationNode())
  #expect(set.node(of: "label") != nil)

  #expect(set.node(of: "foo") == nil)
  #expect(!set.containsAnyLabelNode())
}

#else
final class PublicSuffixTests: XCTestCase {
  func test_nodeSet() {
    let set: PublicSuffix.Node.Set = [.termination, .label("label", next: [.termination])]
    XCTAssertTrue(set.containsTerminationNode())
    XCTAssertNotNil(set.node(of: "label"))
    
    XCTAssertNil(set.node(of: "foo"))
    XCTAssertFalse(set.containsAnyLabelNode())
  }
}
#endif
