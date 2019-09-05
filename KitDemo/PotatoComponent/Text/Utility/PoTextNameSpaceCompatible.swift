//
//  PoTextNameSpaceCompatible.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/22.
//  Copyright © 2019 黄中山. All rights reserved.
//

import Foundation

protocol NameSpaceCompatible {
    associatedtype ExtensionTargetType
    var po: NameSpaceWrapper<ExtensionTargetType> { get }
    static var po: NameSpaceWrapper<ExtensionTargetType>.Type { get }
}

extension NameSpaceCompatible {
    
    var po: NameSpaceWrapper<Self> {
        return NameSpaceWrapper<Self>(self)
    }
    
    static var po: NameSpaceWrapper<Self>.Type {
        return NameSpaceWrapper<Self>.self
    }
}

struct NameSpaceWrapper<Base> {
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}
