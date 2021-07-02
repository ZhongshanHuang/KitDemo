//
//  UIColor+extension.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/6/30.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

extension UIColor {
        
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        guard hex.count == 7 else { fatalError("Invalid formatter") }
        
        var value: UInt32 = 0
        Scanner(string: String(hex.dropFirst())).scanHexInt32(&value)

        let red = (value >> 16) & 0xFF
        let green = (value >> 8) & 0xFF
        let blue = value & 0xFF
        
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
    }
    
}
