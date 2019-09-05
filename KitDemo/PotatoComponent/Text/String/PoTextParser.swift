//
//  PoTextParser.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/9/4.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import Foundation

protocol PoTextParser {
    func parse(text: NSMutableAttributedString, selectedRange: NSRangePointer?) -> Bool
}
