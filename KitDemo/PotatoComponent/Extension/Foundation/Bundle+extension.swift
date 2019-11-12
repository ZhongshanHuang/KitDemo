//
//  Bundle+extension.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/5/18.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

extension Bundle {
    
    static var preferredScales: [Int] = {
        var scales: [Int]
        let screenScale = UIScreen.main.scale
        if screenScale <= 1 {
            scales = [1, 2, 3]
        } else if screenScale <= 2 {
            scales = [2, 3, 1]
        } else {
            scales = [3, 2, 1]
        }
        return scales
    }()
}
