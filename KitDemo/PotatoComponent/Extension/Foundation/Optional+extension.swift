//
//  Optional+extension.swift
//  KitDemo
//
//  Created by 黄山哥 on 2018/11/19.
//  Copyright © 2018 黄中山. All rights reserved.
//

import Foundation

// https://juejin.im/post/5bf2627ee51d45686a68a245

// MARK: - 判空
extension Optional {
    
    /// 是否为空
    var isNone: Bool {
        switch self {
        case .none:
            return true
        case .some:
            return false
        }
    }
    
    /// 是否有值
    var isSome: Bool {
        return !isNone
    }
}
