//
//  PoTextRunDelegate.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/9/3.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

final class PoTextRunDelegate {
    let width: CGFloat
    let ascent: CGFloat
    let descent: CGFloat
    let userInfo: Dictionary<AnyHashable, Any>?
    
    var ctRunDelegate: CTRunDelegate? {
        var callBacks = CTRunDelegateCallbacks(version: kCTRunDelegateCurrentVersion, dealloc: { (rawPt) in
            Unmanaged<PoTextRunDelegate>.fromOpaque(rawPt).release()
        }, getAscent: { (rawPt) -> CGFloat in
            return Unmanaged<PoTextRunDelegate>.fromOpaque(rawPt).takeUnretainedValue().ascent
        }, getDescent: { (rawPt) -> CGFloat in
            return Unmanaged<PoTextRunDelegate>.fromOpaque(rawPt).takeUnretainedValue().descent
        }) { (rawPt) -> CGFloat in
            return Unmanaged<PoTextRunDelegate>.fromOpaque(rawPt).takeUnretainedValue().width
        }
        return CTRunDelegateCreate(&callBacks, Unmanaged.passRetained(self).toOpaque())
    }
    
    init(width: CGFloat, ascent: CGFloat, descent: CGFloat, userInfo: Dictionary<AnyHashable, Any>? = nil) {
        self.width = width
        self.ascent = ascent
        self.descent = descent
        self.userInfo = userInfo
    }
}
