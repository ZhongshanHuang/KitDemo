//
//  UIColor+extension.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/6/30.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

extension UIColor {
    
    // "#3e4g5h"
    convenience init(hex: String) {
        guard hex.count >= 7 else { fatalError("Invalid formatter") }
        
        var start = hex.index(after: hex.startIndex)
        var end = hex.index(start, offsetBy: 2)
        let redStr = String(hex[start..<end])
        
        start = end
        end = hex.index(start, offsetBy: 2)
        let greenStr = String(hex[start..<end])
        
        start = end
        end = hex.index(start, offsetBy: 2)
        let blueStr = String(hex[start..<end])
        
        var red: UInt32 = 0
        var green: UInt32 = 0
        var blue: UInt32 = 0
        var alpha: CGFloat = 1
        
        Scanner(string: redStr).scanHexInt32(&red)
        Scanner(string: greenStr).scanHexInt32(&green)
        Scanner(string: blueStr).scanHexInt32(&blue)
        
        if hex.count >= 9 {
            var alp: UInt32 = 0
            start = end
            end = hex.index(start, offsetBy: 2)
            let alphaStr = String(hex[start..<end])
            Scanner(string: alphaStr).scanHexInt32(&alp)
            alpha = CGFloat(alp) / 255
        }
        
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
    }
    
    
}
