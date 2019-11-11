//
//  CGBitmapInfo+PoImageCoder.swift
//  KitDemo
//
//  Created by 黄中山 on 2019/11/11.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

extension CGBitmapInfo {
    
    static var byteOrder16Host: CGBitmapInfo {
        return CFByteOrderGetCurrent() == CFByteOrderLittleEndian.rawValue ? .byteOrder16Little : .byteOrder16Big
    }
    
    static var byteOrder32Host: CGBitmapInfo {
        return CFByteOrderGetCurrent() == CFByteOrderLittleEndian.rawValue ? .byteOrder32Little : .byteOrder32Big
    }
}
