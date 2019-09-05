//
//  PoTextParagraphStyleExtension.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/22.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

extension NSParagraphStyle: NameSpaceCompatible {}

extension NameSpaceWrapper where Base: NSParagraphStyle {
    
    static func style(with ctStyle: CTParagraphStyle) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        
        var lineSpacing: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .lineSpacingAdjustment, MemoryLayout<CGFloat>.stride, &lineSpacing) {
            style.lineSpacing = lineSpacing
        }
        
        var paragraphSpacing: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .paragraphSpacing, MemoryLayout<CGFloat>.stride, &paragraphSpacing) {
            style.paragraphSpacing = paragraphSpacing
        }
        
        var alignment: CTTextAlignment = .left
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .paragraphSpacing, MemoryLayout<CTTextAlignment>.stride, &alignment) {
            style.alignment = NSTextAlignment(alignment)
        }
        
        var firstLineHeadIndent: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .firstLineHeadIndent, MemoryLayout<CGFloat>.stride, &firstLineHeadIndent) {
            style.firstLineHeadIndent = firstLineHeadIndent
        }
        
        var headIndent: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .headIndent, MemoryLayout<CGFloat>.stride, &headIndent) {
            style.headIndent = headIndent
        }
        
        var tailIndent: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .tailIndent, MemoryLayout<CGFloat>.stride, &tailIndent) {
            style.tailIndent = tailIndent
        }
        
        var lineBreakMode: CTLineBreakMode = .byTruncatingTail
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .lineBreakMode, MemoryLayout<CTLineBreakMode>.stride, &lineBreakMode) {
            style.lineBreakMode = NSLineBreakMode(rawValue: Int(lineBreakMode.rawValue))!
        }
        
        var minimumLineHeight: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .minimumLineHeight, MemoryLayout<CGFloat>.stride, &minimumLineHeight) {
            style.minimumLineHeight = minimumLineHeight
        }
        
        var maximumLineHeight: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .maximumLineHeight, MemoryLayout<CGFloat>.stride, &maximumLineHeight) {
            style.maximumLineHeight = maximumLineHeight
        }
        
        var baseWritingDirection: CTWritingDirection = .leftToRight
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .maximumLineHeight, MemoryLayout<CTWritingDirection>.stride, &baseWritingDirection) {
            style.baseWritingDirection = NSWritingDirection(rawValue: Int(baseWritingDirection.rawValue))!
        }
        
        var lineHeightMultiple: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .lineHeightMultiple, MemoryLayout<CGFloat>.stride, &lineHeightMultiple) {
            style.lineHeightMultiple = lineHeightMultiple
        }
        
        var paragraphSpacingBefore: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .paragraphSpacingBefore, MemoryLayout<CGFloat>.stride, &paragraphSpacingBefore) {
            style.paragraphSpacingBefore = paragraphSpacingBefore
        }
        
        var tabStops = [CTTextTab]()
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .tabStops, MemoryLayout<Array<CTTextTab>>.stride, &tabStops) {
            var tabs = [NSTextTab]()
            for ctTab in tabStops {
                let tab = NSTextTab(textAlignment: NSTextAlignment(CTTextTabGetAlignment(ctTab)),
                                    location: CGFloat(CTTextTabGetLocation(ctTab)),
                                    options: (CTTextTabGetOptions(ctTab) as? [NSTextTab.OptionKey : Any]) ?? [:])
                
                tabs.append(tab)
            }
            style.tabStops = tabs
        }
        
        var defaultTabInterval: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .defaultTabInterval, MemoryLayout<CGFloat>.stride, &defaultTabInterval) {
            style.defaultTabInterval = defaultTabInterval
        }
        
        return style
    }
    
    var ctStyle: CTParagraphStyle {
        
        var sets = Array<CTParagraphStyleSetting>()
        
        var ctLineSpacing = base.lineSpacing
        let lineSpacingSet = CTParagraphStyleSetting(spec: .lineSpacingAdjustment, valueSize: MemoryLayout<CGFloat>.stride, value: &ctLineSpacing)
        sets.append(lineSpacingSet)
        
        var ctAlignment = CTTextAlignment(rawValue: UInt8(base.alignment.rawValue))
        let alignmentSet = CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.stride, value: &ctAlignment)
        sets.append(alignmentSet)
        
        var ctFirstLineheadIndent = base.firstLineHeadIndent
        let firstLineHeadIndentSet = CTParagraphStyleSetting(spec: .firstLineHeadIndent, valueSize: MemoryLayout<CGFloat>.stride, value: &ctFirstLineheadIndent)
        sets.append(firstLineHeadIndentSet)
        
        var ctHeadIndent = base.headIndent
        let headIndentSet = CTParagraphStyleSetting(spec: .headIndent, valueSize: MemoryLayout<CGFloat>.stride, value: &ctHeadIndent)
        sets.append(headIndentSet)
        
        var ctTailIndent = base.tailIndent
        let tailIndentSet = CTParagraphStyleSetting(spec: .tailIndent, valueSize: MemoryLayout<CGFloat>.stride, value: &ctTailIndent)
        sets.append(tailIndentSet)
        
        var ctLineBreakMode = CTLineBreakMode(rawValue: UInt8(base.lineBreakMode.rawValue))
        let lineBreakModeSet = CTParagraphStyleSetting(spec: .lineBreakMode, valueSize: MemoryLayout<CTLineBreakMode>.stride, value: &ctLineBreakMode)
        sets.append(lineBreakModeSet)
        
        var ctMinimumLineHeight = base.minimumLineHeight
        let minimumLineHeightSet = CTParagraphStyleSetting(spec: .minimumLineHeight, valueSize: MemoryLayout<CGFloat>.stride, value: &ctMinimumLineHeight)
        sets.append(minimumLineHeightSet)
        
        var ctMaximumLineHeight = base.maximumLineHeight
        let maximumLineHeightSet = CTParagraphStyleSetting(spec: .maximumLineHeight, valueSize: MemoryLayout<CGFloat>.stride, value: &ctMaximumLineHeight)
        sets.append(maximumLineHeightSet)
        
        var ctBaseWritingDirection = CTWritingDirection(rawValue: Int8(base.baseWritingDirection.rawValue))
        let baseWritingDirectionSet = CTParagraphStyleSetting(spec: .baseWritingDirection, valueSize: MemoryLayout<CTWritingDirection>.stride, value: &ctBaseWritingDirection)
        sets.append(baseWritingDirectionSet)
        
        var ctLineHeightMultiple = base.lineHeightMultiple
        let lineHeightMultipleSet = CTParagraphStyleSetting(spec: .lineHeightMultiple, valueSize: MemoryLayout<CGFloat>.stride, value: &ctLineHeightMultiple)
        sets.append(lineHeightMultipleSet)
        
        var ctParagraphSpacingBefore = base.paragraphSpacingBefore
        let paragraphSpacingBeforeSet = CTParagraphStyleSetting(spec: .paragraphSpacingBefore, valueSize: MemoryLayout<CGFloat>.stride, value: &ctParagraphSpacingBefore)
        sets.append(paragraphSpacingBeforeSet)
        
        var ctTabStops = [CTTextTab]()
        for tab in base.tabStops {
            let ctTab = CTTextTabCreate(CTTextAlignment(tab.alignment), Double(tab.location), tab.options as CFDictionary)
            ctTabStops.append(ctTab)
        }
        let tabStopsSet = CTParagraphStyleSetting(spec: .tabStops, valueSize: MemoryLayout<[CTTextTab]>.stride, value: &ctTabStops)
        sets.append(tabStopsSet)
        
        var ctDefaultTabInterval = base.defaultTabInterval
        let defaultTabIntervalSet = CTParagraphStyleSetting(spec: .defaultTabInterval, valueSize: MemoryLayout<CGFloat>.stride, value: &ctDefaultTabInterval)
        sets.append(defaultTabIntervalSet)
        
        return CTParagraphStyleCreate(&sets, sets.count)
    }
    
}
