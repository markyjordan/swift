// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: %target-swift-frontend -emit-module %t/Utils.swift \
// RUN:   -module-name Utils -swift-version 5 -I %t \
// RUN:   -package-name mypkg \
// RUN:   -enable-library-evolution \
// RUN:   -emit-module -emit-module-path %t/Utils.swiftmodule

// RUN: %target-swift-frontend -typecheck %t/ClientDefault.swift -I %t -swift-version 5 -package-name mypkg -verify

// RUN: %target-swift-frontend -typecheck %t/ClientOptimized.swift -I %t -swift-version 5 -package-name mypkg -package-bypass-resilience-optimization -verify

//--- Utils.swift

public enum PublicEnum {
  case one
  case two(Int)
}

@frozen
public enum FrozenPublicEnum {
  case one
  case two(Int)
}

package enum PkgEnum {
  case one
  case two(Int)
}

public struct PublicStruct {
  public var publicVar: Int
}

package enum PkgEnumWithPublicCase {
  case one
  case two(PublicStruct)
}

package enum PkgEnumWithExistentialCase {
  case one
  case two(any StringProtocol)
}

@usableFromInline
package enum UfiPkgEnum {
  case one
  case two(Int)
}

//--- ClientDefault.swift
import Utils

func f(_ arg: PkgEnum) -> Int {
  switch arg { // expected-warning {{switch covers known cases, but 'PkgEnum' may have additional unknown values}} {{none}} expected-note {{handle unknown values using "@unknown default"}}
  case .one:
    return 1
  case .two(let val):
    return 2 + val
  }
}

public func g(_ arg: PublicEnum) -> Int {
  switch arg { // expected-warning {{switch covers known cases, but 'PublicEnum' may have additional unknown values}} {{none}} expected-note {{handle unknown values using "@unknown default"}}
  case .one:
    return 1
  case .two(let val):
    return 2 + val
  }
}

public func h(_ arg: FrozenPublicEnum) -> Int {
  switch arg { // no-warning
  case .one:
    return 1
  case .two(let val):
    return 2 + val
  }
}

//--- ClientOptimized.swift
import Utils

// No warning with optimization to bypass resilience checks for package enums.
func f(_ arg: PkgEnum) -> Int {
  switch arg {
  case .one:
    return 1
  case .two(let val):
    return 2 + val
  }
}

// Warning still shows up for public enum as the optimization is targeted for package types.
public func g(_ arg: PublicEnum) -> Int {
  switch arg { // expected-warning {{switch covers known cases, but 'PublicEnum' may have additional unknown values}} {{none}} expected-note {{handle unknown values using "@unknown default"}}
  case .one:
    return 1
  case .two(let val):
    return 2 + val
  }
}

public func h(_ arg: FrozenPublicEnum) -> Int {
  switch arg { // no-warning
  case .one:
    return 1
  case .two(let val):
    return 2 + val
  }
}
