/* *************************************************************************************************
 PublicSuffixUpdater.swift
  © 2020,2022 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 ************************************************************************************************ */

import Foundation
import StringComposition
import yCodeUpdater

public final class PublicSuffixList: StringLinesCodeUpdaterDelegate {
  public typealias IntermediateDataType = StringLines
  
  public init() {}
  
  public var sourceURLs: Array<URL> {
    return [
      URL(string: "https://publicsuffix.org/list/public_suffix_list.dat")!,
    ]
  }
  
  public var destinationURL: URL {
    var url = URL(fileURLWithPath: #file)
    for _ in 0..<5 { url = url.deletingLastPathComponent() }
    url.appendPathComponent("Sources")
    url.appendPathComponent("PublicSuffix")
    url.appendPathComponent("PublicSuffixList.swift")
    return url
  }
  
  public func convert<S>(_ intermediates: S) throws -> StringLines where S: Sequence, S.Element == IntermediateDataContainer<IntermediateDataType> {
    var result = StringLines()
    
    do { // License
      result.append(contentsOf: [
        "// NOTICE: Original source code is licensed under Mozilla Public License Version 2.0 (MPL2.0)",
        "//         and, this file contains the source converted to Swift language.",
        "//         Subjecting to MPL 2.0, this FILE is also licensed under the same license.",
        "//         Please read comments of the original source file, and the license.)",
      ])
      result.appendEmptyLine()
      
      let licenseURL = URL(string: "https://www.mozilla.org/media/MPL/2.0/index.txt")!
      guard var license = String(data: content(of: licenseURL), encoding: .utf8).map({ StringLines($0, detectIndent: false) }) else {
        throw NSError(domain: "Failed to fetch Mozilla Public License Version 2.0.", code: -1)
      }
      result.append("/*")
      license.shiftRight()
      result.append(contentsOf: license)
      result.append("*/")
      result.appendEmptyLine()
    }
    
    // - MARK: Derive domains

    var positives: [String] = []
    var negatives: [String] = []
    for interm in intermediates {
      for line in interm.content {
        let payload = line.payload
        if payload.isEmpty || payload.hasPrefix("//") { continue }
        
        if payload.hasPrefix("!") {
          positives.append(String(payload.dropFirst()))
        } else {
          negatives.append(payload)
        }
      }
    }

    /// Sort list of reversed domains.
    ///
    /// For example,
    /// ```
    /// ["com", "foo", "bar"]
    /// ["com"]
    /// ["jp", "foo", "*"]
    /// ["jp", "foo", "bar"]
    /// ["jp", "foo", "baz"]
    /// ["jp", "foo"]
    /// ["jp"]
    /// ```
    func __sorter<C>(_ list0: C, _ list1: C) -> Bool where C: Collection, C.Index == Int, C.Element == String {
      let (n0, n1) = (list0.count, list1.count)
      assert(n0 > 0 && n1 > 0)
      for ii in 0..<min(n0, n1) {
        if list0[list0.startIndex + ii] < list1[list1.startIndex + ii] { return true }
        if list0[list0.startIndex + ii] > list1[list1.startIndex + ii] { return false }
      }
      assert(n0 != n1, "SAME LIST!?\n  - list0: \(list0.joined(separator: ","))\n  - list1: \(list1.joined(separator: ","))")
      return n0 > n1
    }
    func _sort(_ list: [String]) -> [[String]] {
      return list.map({ $0.split(separator: ".").reversed().map(String.init) }).sorted(by: __sorter)
    }
    
    
    /// What we want to get is like:
    /// ```
    /// private static let _negative_com_foo_bar: PublicSuffix.Node = .label("bar", next: [.termination])
    /// private static let _negative_com_foo: PublicSuffix.Node = .label("foo", next: [_negative_com_foo_bar])
    /// private static let _negative_com: PublicSuffix.Node = .label("com", next: [.termination, _negative_com_foo])
    /// private static let _negative_jp_foo_bar: PublicSuffix.Node = .label("bar", next: [.termination])
    /// private static let _negative_jp_foo_baz: PublicSuffix.Node = .label("baz", next: [.termination])
    /// private static let _negative_jp_foo: PublicSuffix.Node = .label("bar", next: [.any, .termination, _negative_jp_foo_bar, _negative_jp_foo_baz])
    /// private static let _negative_jp: PublicSuffix.Node = .label("baz", next: [.termination, _negative_foo])
    /// public static let negativeList: PublicSuffix.Node.Set = [_negative_com, _negative_jp]
    /// ```
    func _convert(_ list: [String], prefix: String) -> StringLines {
      var result = StringLines()

      // NOTE: Avoid the bug: https://github.com/apple/swift/issues/59865

      let sorted = _sort(list)
      var links: [[String]: Set<[String]>] = [:]
      var nonRoots: Set<[String]> = []
      
      let ANY = ["$A"]
      let TERMINATION = ["$T"]
      
      func __insert(root: [String], next: [String]) {
        if links.keys.contains(root) {
          links[root]!.insert(next)
        } else {
          links[root] = [next]
        }
        nonRoots.insert(next)
      }
      
      generate_links: for reversedDomain in sorted {
        precondition(!reversedDomain.isEmpty)
        
        let startDroppingCount: Int
        if reversedDomain.last! == "*" {
          __insert(root: .init(reversedDomain.dropLast()), next: ANY)
          startDroppingCount = 2
        } else {
          __insert(root: reversedDomain, next: TERMINATION)
          startDroppingCount = 1
        }
        for ii in startDroppingCount..<reversedDomain.count {
          __insert(root: reversedDomain.dropLast(ii), next: reversedDomain.dropLast(ii - 1))
        }
      }
      
      func __id(_ reversedDomain: [String]) -> String {
        if reversedDomain.count == 1 {
          if reversedDomain.first! == ANY.first! {
            return ".any"
          } else if reversedDomain.first! == TERMINATION.first! {
            return ".termination"
          }
        }
        return "_\(prefix)_" + reversedDomain.joined(separator: "_").replacingOccurrences(of: "-", with: "H")
      }
      
      let linkRoots = links.keys.sorted(by: __sorter)
      generate_code: for reversedDomain in linkRoots {
        precondition(reversedDomain.last! != "*")
        let next = links[reversedDomain]!.sorted(by: __sorter)
        let nextString = "[" + next.map({ __id($0) }).joined(separator: ", ")  + "]"
        result.append("private static let \(__id(reversedDomain)): PublicSuffix.Node = .label(\(reversedDomain.last!.debugDescription), next: \(nextString))")
      }
      
      result.append("public static let \(prefix)List: PublicSuffix.Node.Set = [")
      for reversedDomain in linkRoots {
        if nonRoots.contains(reversedDomain) { continue }
        result.append(String.Line("\(__id(reversedDomain)),", indentLevel: 1)!)
      }
      result.append("]")
      
      return result
    }
    
    var positiveLines = _convert(positives, prefix: "positive")
    result.append("extension PublicSuffix {")
    positiveLines.shiftRight()
    result.append(contentsOf: positiveLines)
    result.append("}")
    result.appendEmptyLine()
    
    var negativeLines = _convert(negatives, prefix: "negative")
    result.append("extension PublicSuffix {")
    negativeLines.shiftRight()
    result.append(contentsOf: negativeLines)
    result.append("}")
    
    return result
  }
}
