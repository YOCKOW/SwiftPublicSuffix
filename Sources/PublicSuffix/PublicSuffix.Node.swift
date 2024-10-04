/***************************************************************************************************
 PublicSuffix.Node.swift
   © 2017-2020,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

extension PublicSuffix {
  /// Node of the tree that represents Public Suffix List.
  /// Each domain is reversed in the tree.
  ///
  ///
  /// Given the list:
  /// ```
  /// // Sample List
  /// jp
  /// foo.jp
  /// bar.jp
  /// *.foo.jp
  /// ```
  ///
  /// They will be converted to the tree like:
  /// ```Swift
  /// let jp: Node = .label("jp", next: [
  ///   .termination,
  ///   .label("foo", next: [.termination, .any]),
  ///   .label("bar", next: [.termination]),
  /// ])
  /// ```
  public enum Node: Sendable {
    public struct Set: ExpressibleByArrayLiteral, Sendable {
      public typealias ArrayLiteralElement = Node
      
      private struct _HashableNode: Hashable {
        let _node: Node
        
        static func ==(lhs: _HashableNode, rhs: _HashableNode) -> Bool {
          switch (lhs._node, rhs._node) {
          case (.termination, .termination), (.any, .any):
            return true
          case (.label(let lLabel, next:_), .label(let rLabel, next:_)):
            return lLabel == rLabel
          default:
            return false
          }
        }
        
        func hash(into hasher: inout Hasher) {
          switch self._node {
          case .label(let label, next: _):
            hasher.combine(label)
          case .any:
            hasher.combine("*")
          case .termination:
            hasher.combine(".")
          }
        }
        
        init(_ node: Node) {
          self._node = node
        }
        
        static let any: _HashableNode = .init(.any)
        static let termination: _HashableNode = .init(.termination)
      }
      
      private var _set: Swift.Set<_HashableNode>
      
      public init<S>(_ elements: S) where S: Sequence, S.Element == Node {
        self._set = .init(elements.map({ _HashableNode($0) }))
      }
      
      public init(arrayLiteral elements: Node...) {
        self.init(elements)
      }
      
      public func node<S>(of label: S) -> Node? where S: StringProtocol {
        // _HashableNode ignores "next set".
        let pseudoNode = _HashableNode(.label(label as? String ?? String(label), next: []))
        guard let index = self._set.firstIndex(of: pseudoNode) else { return nil }
        return self._set[index]._node
      }
      
      public func containsAnyLabelNode() -> Bool {
        return self._set.contains(.any)
      }
      
      public func containsTerminationNode() -> Bool {
        return self._set.contains(.termination)
      }
    }
    
    /// Some domain label.
    case label(String, next: Set)
    
    /// Any label can be in the next.
    case any
    
    /// No label exists in the next.
    case termination
  }
}
