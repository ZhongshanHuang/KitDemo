//
//  PoTextLine.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/5/28.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

final class PoTextLine {
    
    var index: Int = 0 // line index
    var row: Int = 0 // line row
    
    private(set) var ctLine: CTLine                 // CoreTextLine
    private(set) var range: NSRange = NSRange()     // string range
    private(set) var bounds: CGRect = .zero         // bounds (ascent + descent)
    private(set) var ascent: CGFloat = 0            // line ascent
    private(set) var descent: CGFloat = 0           // line descent
    private(set) var leading: CGFloat = 0           // line leading (line gap)
    private(set) var lineWidth: CGFloat = 0         // line width
    private(set) var trailingWhitespaceWidth: CGFloat = 0
    
    private(set) var attachments: Array<PoTextAttachment>? // PoTextAttachment
    private(set) var attachmentRanges: ContiguousArray<NSRange>?
    private(set) var attachmentRects: ContiguousArray<CGRect>?
    
    var size: CGSize {
        return bounds.size
    }
    var width: CGFloat {
        return bounds.width
    }
    var height: CGFloat {
        return bounds.height
    }
    var top: CGFloat {
        return bounds.minY
    }
    var left: CGFloat {
        return bounds.minX
    }
    var bottom: CGFloat {
        return bounds.maxY
    }
    var right: CGFloat {
        return bounds.maxX
    }
    
    // baseline position
    var position: CGPoint = .zero {
        didSet {
            reloadBounds()
        }
    }
    
    private var _firstGlyphPos: CGFloat = 0 // first glyph position for baseline, typically 0.
    
    
    // MARK: - Inlitializers
    
    init(ctLine: CTLine, position: CGPoint) {
        self.position = position
        self.ctLine = ctLine
        setCTLine(ctLine)
    }
    
    private func setCTLine(_ ctLine: CTLine) {
        lineWidth = CGFloat(CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading))
        range = CTLineGetStringRange(ctLine).nsRange

        if CTLineGetGlyphCount(ctLine) > 0 {
            let runs = CTLineGetGlyphRuns(ctLine)
            let firstRun = unsafeBitCast(CFArrayGetValueAtIndex(runs, 0), to: CTRun.self)
            var point: CGPoint = .zero
            CTRunGetPositions(firstRun, CFRange(location: 0, length: 1), &point)
            _firstGlyphPos = point.x
        } else {
            _firstGlyphPos = 0
        }
        trailingWhitespaceWidth = CGFloat(CTLineGetTrailingWhitespaceWidth(ctLine))
        reloadBounds()
    }
    
    private func reloadBounds() {
        bounds = CGRect(x: position.x + _firstGlyphPos, y: position.y - ascent, width: lineWidth, height: ascent + descent)

        let runs = CTLineGetGlyphRuns(ctLine)
        let runCount = CFArrayGetCount(runs)
        if runCount == 0 { return }

        var attachments: Array<PoTextAttachment>!
        var attachmentRanges: ContiguousArray<NSRange>!
        var attachmentRects: ContiguousArray<CGRect>!
        
        for r in 0..<runCount {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), to: CTRun.self)
            let glyphCount = CTRunGetGlyphCount(run)
            if glyphCount == 0 { continue }
            let runAttrs = CTRunGetAttributes(run) as! Dictionary<NSAttributedString.Key, Any>
            if let attachment = runAttrs[.poAttachment] as? PoTextAttachment {
                var runPosition: CGPoint = .zero
                let cfRange = CFRange(location: 0, length: 1)
                CTRunGetPositions(run, cfRange, &runPosition)
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                var runWidth: CGFloat = 0
                var runTypoBounds: CGRect = .zero
                runWidth = CGFloat(CTRunGetTypographicBounds(run, cfRange, &ascent, &descent, &leading))
                runPosition.x += position.x
                runPosition.y = position.y - runPosition.y
                runTypoBounds = CGRect(x: runPosition.x, y: runPosition.y - ascent, width: runWidth, height: ascent + descent)
                let runRange = CTRunGetStringRange(run).nsRange
                if attachments == nil {
                    attachments = []
                    attachmentRanges = []
                    attachmentRects = []
                }
                attachments.append(attachment)
                attachmentRanges.append(runRange)
                attachmentRects.append(runTypoBounds)
            }
        }
        
        self.attachments = attachments
        self.attachmentRanges = attachmentRanges
        self.attachmentRects = attachmentRects
    }
}

// MARK: - Equatable

extension PoTextLine: Equatable {
    
    static func == (lhs: PoTextLine, rhs: PoTextLine) -> Bool {
        return lhs === rhs
    }
}

