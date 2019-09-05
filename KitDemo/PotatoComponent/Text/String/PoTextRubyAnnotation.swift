//
//  PoTextRubyAnnotation.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/9/2.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

@available(iOS 8.0, *)
final class PoTextRubyAnnotation {
    
    // MARK: - Properties
    var alignment: CTRubyAlignment = .auto
    
    var overhang: CTRubyOverhang = .auto
    
    var sizeFactor: CGFloat = 0.5
    
    /// 目标文字的上面
    var textBefore: String?
    
    /// 目标文字的下面
    var textAfter: String?
    
    /// 实际效果无法理解，一般应该用不上
    var textInterCharacter: String?
    
    /// 目标文字的后面
    var textInline: String?
    
    var ctRubyAnnotation: CTRubyAnnotation {
        let count = Int(CTRubyPosition.count.rawValue)
        let textPt = UnsafeMutablePointer<Unmanaged<CFString>?>.allocate(capacity: count)
        textPt.initialize(repeating: nil, count: count)
        if textBefore != nil {
            textPt[Int(CTRubyPosition.before.rawValue)] = Unmanaged.passRetained((textBefore! as CFString))
        }
        if textAfter != nil {
            textPt[Int(CTRubyPosition.after.rawValue)] = Unmanaged.passRetained((textAfter! as CFString))
        }
        if textInterCharacter != nil {
            textPt[Int(CTRubyPosition.interCharacter.rawValue)] = Unmanaged.passRetained((textInterCharacter! as CFString))
        }
        if textInline != nil {
            textPt[Int(CTRubyPosition.inline.rawValue)] = Unmanaged.passRetained((textInline! as CFString))
        }
        let ruby = CTRubyAnnotationCreate(alignment, overhang, sizeFactor, textPt)
        textPt.deinitialize(count: count)
        textPt.deallocate()
        return ruby
    }
    
    init() { }
    
    init(ctRuby: CTRubyAnnotation) {
        self.alignment = CTRubyAnnotationGetAlignment(ctRuby)
        self.overhang = CTRubyAnnotationGetOverhang(ctRuby)
        self.sizeFactor = CTRubyAnnotationGetSizeFactor(ctRuby)
        self.textBefore = CTRubyAnnotationGetTextForPosition(ctRuby, .before) as String?
        self.textAfter = CTRubyAnnotationGetTextForPosition(ctRuby, .after) as String?
        self.textInterCharacter = CTRubyAnnotationGetTextForPosition(ctRuby, .interCharacter) as String?
        self.textInline = CTRubyAnnotationGetTextForPosition(ctRuby, .inline) as String?
    }
}
