/* *************************************************************************************************
 PublicSuffixUpdaterTests.swift
  © 2020 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import XCTest
@testable import PublicSuffixUpdaterLibrary

final class PublicSuffixUpdaterTests: XCTestCase {
  func test_delegate() throws {
    let delegate = PublicSuffixList()
    let lines = try delegate.convert(delegate.sourceURLs.map({ try delegate.prepare(sourceURL: $0) }))
    XCTAssertTrue(lines.contains(String.Line("public static let positiveList: PublicSuffix.Node.Set = [", indentLevel: 1)!))
    XCTAssertTrue(lines.contains(String.Line("public static let negativeList: PublicSuffix.Node.Set = [", indentLevel: 1)!))
  }
}
