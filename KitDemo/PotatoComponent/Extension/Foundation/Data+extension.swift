//
//  Data+extension.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/5/20.
//  Copyright © 2019 黄中山. All rights reserved.
//

import Foundation

// MARK: - String isEmpty
extension Optional where Wrapped == Data {

    var isEmpty: Bool {
        switch self {
        case .some(let value):
            return value.isEmpty
        case .none:
            return true
        }
    }
}

