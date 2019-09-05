//
//  CTView.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/6/4.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit


class CTView: UIView {
    
    var imgFrame: CGRect = .zero
    var ctFrame: CTFrame?
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        let attributesStr = NSMutableAttributedString(string: "我叫小土豆,现在100天，第一个六一儿童节。")
        attributesStr.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 20), range: NSRange(location: 0, length: 5))
        
        // 图片占位符
        let spaceStr = String(UnicodeScalar(0xFFFC)!)
        let placehold = NSMutableAttributedString(string: spaceStr)

        // 设置图片代理
        var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateCurrentVersion, dealloc: { (rawPt) in
            
        }, getAscent: { (rawPt) -> CGFloat in
            return 30
        }, getDescent: { (rawPt) -> CGFloat in
            return 10
        }) { (rawPt) -> CGFloat in
            return 40
        }
        
        let runDelegate = CTRunDelegateCreate(&callbacks, nil)
        CFAttributedStringSetAttribute(placehold, CFRange(location: 0, length: 1), kCTRunDelegateAttributeName, runDelegate)
        attributesStr.insert(placehold, at: 5)
        
        // 绘画的区间
        let path = UIBezierPath(rect: bounds)
        
        // 开始绘画文字
        let frameSetter = CTFramesetterCreateWithAttributedString(attributesStr)
        var frameAttrs = Dictionary<CFString, Any>()
//        var value = CTFrameProgression.rightToLeft.rawValue
//        frameAttrs[kCTFrameProgressionAttributeName] = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &value)
        var value2 = 5
        frameAttrs[kCTFramePathWidthAttributeName] = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &value2)
        
        context.saveGState()
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: attributesStr.length), path.cgPath, frameAttrs as CFDictionary)
        ctFrame = frame
        CTFrameDraw(frame, context)
        context.restoreGState()
        
        // 画图片
        let lines = CTFrameGetLines(frame)
        var lineOrigins = [CGPoint](repeating: .zero, count: CFArrayGetCount(lines))
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
        for i in 0..<CFArrayGetCount(lines) {
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, i), to: CTLine.self)
            let runs = CTLineGetGlyphRuns(line)

            for j in 0..<CFArrayGetCount(runs) {
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, j), to: CTRun.self)
                let runAttributes = CTRunGetAttributes(run)

                if CFDictionaryGetValue(runAttributes, Unmanaged.passUnretained(kCTRunDelegateAttributeName).toOpaque()) != nil {
                    var runAscent: CGFloat = 0
                    var runDescent: CGFloat = 0
                    var runLeading: CGFloat = 0
                    let runWidth = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &runAscent, &runDescent, &runLeading))
                    let lineOrigin = lineOrigins[i]
                    let runRect = CGRect(x: lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil), y: bounds.height - lineOrigin.y - runAscent, width: runWidth, height: runAscent + runDescent)
                    imgFrame = runRect
                    let image = UIImage(named: "mc")
                    image?.draw(in: runRect)
                }
            }
        }
        
    }
}




extension CTView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: self)
        if imgFrame.contains(location) {
            print("选中图片")
        } else {
            guard let ctFrame = ctFrame else { return }
            let lines = CTFrameGetLines(ctFrame)
            let lineCount = CFArrayGetCount(lines)
            var lineOrigins = [CGPoint](repeating: .zero, count: lineCount)
            CTFrameGetLineOrigins(ctFrame, CFRange(location: 0, length: 0), &lineOrigins)

            for i in 0..<lineCount {
                let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, i), to: CTLine.self)
                var lineAscent: CGFloat = 0
                var lineDescent: CGFloat = 0
                let linewidth = CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, nil)
                let lineFrame = CGRect(x: lineOrigins[i].x, y: bounds.height - lineOrigins[i].y - lineAscent, width: CGFloat(linewidth), height: lineAscent + lineDescent)
                
                if lineFrame.contains(location) {
                    print("选中了第\(i)行")
                    let runs = CTLineGetGlyphRuns(line)
                    let runCount = CFArrayGetCount(runs)
                    let lineRange = CTLineGetStringRange(line)
                    for r in 0..<runCount {
                        let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), to: CTRun.self)
                        let runOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
                        var runAscent: CGFloat = 0
                        var runDescent: CGFloat = 0
                        var runLeading: CGFloat = 0
                        let runWidth = CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &runAscent, &runDescent, &runLeading)
                        let runFrame = CGRect(x: lineOrigins[i].x + runOffset, y: bounds.height - lineOrigins[i].y - runAscent, width: CGFloat(runWidth), height: runAscent + runDescent)
                        if runFrame.contains(location) {
                            let glyphCount = CTRunGetGlyphCount(run)
                            let runRange = CTRunGetStringRange(run).location
                            for g in 0..<glyphCount {
                                let glyphRange = CFRange(location: runRange + g, length: 1)
                                let glyphOffset = CTLineGetOffsetForStringIndex(line, glyphRange.location, nil)
                                var glyphAscent: CGFloat = 0
                                var glyphDesent: CGFloat = 0
                                let glyphWidth = CTRunGetTypographicBounds(run, CFRange(location: g, length: 1), &glyphAscent, &glyphDesent, nil)
                                let glyphFrame = CGRect(x: lineOrigins[i].x + glyphOffset, y: bounds.height - lineOrigins[i].y - glyphAscent, width: CGFloat(glyphWidth), height: glyphAscent + glyphDesent)
                                print(glyphFrame)
                                if glyphFrame.contains(location) {
                                    print("选中了第\(glyphRange.location - lineRange.location)个字符")
                                    return
                                }
                            }
                            return
                        }
                        
                    }
                    return
                }
                
                
            }
            
        }
    }
    
}

