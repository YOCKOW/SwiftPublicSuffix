/* *************************************************************************************************
 PublicSuffixUpdaterTests.swift
  © 2020,2026 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 ************************************************************************************************ */

@testable import PublicSuffixUpdaterLibrary
import StringComposition
import Testing
import yCodeUpdater

@Suite struct PublicSuffixUpdaterTests {
  @Test func test_delegate() async throws {
    let delegate = PublicSuffixList()
    var interms: [IntermediateDataContainer<StringLines>] = []
    for url in delegate.sourceURLs {
      interms.append(try await delegate.prepare(sourceURL: url))
    }
    let lines: StringLines = try await delegate.convert(interms)
    #expect(lines.contains(try #require(String.Line("public static let positiveList: PublicSuffix.Node.Set = [", indentLevel: 1))))
    #expect(lines.contains(try #require(String.Line("public static let negativeList: PublicSuffix.Node.Set = [", indentLevel: 1))))
  }
}
