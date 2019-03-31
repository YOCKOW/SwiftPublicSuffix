/***************************************************************************************************
 PublicSuffix.Node.swift
   © 2017-2019 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 **************************************************************************************************/

extension PublicSuffix {
  
  /**
   
   # PublicSuffix.Node
   
   Node of the tree that represents Public Suffix List.
   
   */
  public enum Node: Hashable {
    case termination
    case any
    case label(String, next:Set<Node>)
    
    /// Note: In case that both `lhs` and `rhs` are `.label`, only their `String`s are compared.
    public static func ==(lhs:Node, rhs:Node) -> Bool {
      switch (lhs, rhs) {
      case (.termination, .termination): return true
      case (.any, .any): return true
      case (.label(let lLabel, next:_), .label(let rLabel, next:_)) where lLabel == rLabel: return true
      default: return false
      }
    }
    
    public func hash(into hasher:inout Hasher) {
      switch self {
      case .termination: hasher.combine(0)
      case .any: hasher.combine(Int.max)
      case .label(let label, next:_): hasher.combine(label)
      }
    }
  }
}
