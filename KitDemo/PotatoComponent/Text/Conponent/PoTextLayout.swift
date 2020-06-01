//
//  PoTextLayout.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/7/20.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

private typealias AttributesDictionary = Dictionary<NSAttributedString.Key, Any>

// MARK: - PoTextLinePositionModifier

protocol PoTextLinePositionModifier: class, NSCopying {
    func modifyLines(_ lines: inout Array<PoTextLine>, from text: NSAttributedString, in container: PoTextContainer)
}


// MARK: - PoTextLinePositionSimpleModifier

final class PoTextLinePositionSimpleModifier: PoTextLinePositionModifier, NSCopying {

    /// The fixed line height
    var fixedLineHeight: CGFloat = 0

    /// PoTextLinePositionModifier
    func modifyLines(_ lines: inout Array<PoTextLine>, from text: NSAttributedString, in container: PoTextContainer) {
        for line in lines {
            line.position.y = CGFloat(line.row) * fixedLineHeight + fixedLineHeight * 0.9 + container.insets.top
        }
    }

    /// NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let one = PoTextLinePositionSimpleModifier()
        one.fixedLineHeight = fixedLineHeight
        return one
    }
}


/**
 example:
 ┌──────────────────────────┐<------ head
 │           line           |
 └──────────────────────────┘<------ foot
 */

extension PoTextLayout {
    
    struct RowEdge {
        var head: CGFloat
        var foot: CGFloat
    }
}

/**
 example: (layout with a circle exclusion path)
 
 ┌──────────────────────────┐  <------ container
 │ [--------Line0--------]  │  <- Row0
 │ [--------Line1--------]  │  <- Row1
 │ [-Line2-]     [-Line3-]  │  <- Row2
 │ [-Line4]       [Line5-]  │  <- Row3
 │ [-Line6-]     [-Line7-]  │  <- Row4
 │ [--------Line8--------]  │  <- Row5
 │ [--------Line9--------]  │  <- Row6
 └──────────────────────────┘
 */

final class PoTextLayout {
    
    // MAKR: - Properties

    /// The text container
    private(set) var container: PoTextContainer

    /// The full text
    private(set) var text: NSAttributedString

    /// CTFrameSetter
    private(set) var ctFrameSetter: CTFramesetter

    /// CTFrame
    private(set) var ctFrame: CTFrame
    
    /// Array of PoTextLine, no truncated
    private(set) lazy var lines: Array<PoTextLine> = []

    /// PoTextLine with truncated token, or nil
    private(set) var truncatedLine: PoTextLine?

    /// Arrat of PoTextAttachment
    private(set) var attachments: Array<PoTextAttachment>?

    /// Array of NSRange
    private(set) var attachmentRanges: ContiguousArray<NSRange>?

    /// Array of CGRect
    private(set) var attachmentRects: ContiguousArray<CGRect>?

    /// Set of Attachment (UIImage/UIView/CALayer)
    private(set) var attachmentContentsSet: Set<NSObject>?

    /// Number of rows
    private(set) var rowCount: Int = -1

    /// Visible text range
    private(set) var visibleRange: NSRange = NSRange(location: NSNotFound, length: 0)

    /// Bounding rect (glyphs)
    private(set) var textBoundingRect: CGRect = .zero

    /// Bounding size (glyphs and insets, ceil to pixel)
    private(set) var textBoundingSize: CGSize = .zero
    
    /// Has highlight attibute
    private(set) var isContainsHighlight: Bool = false

    /// Has block border attribute
    private(set) var isNeedDrawBlockBorder: Bool = false

    /// Has Border attribute
    private(set) var isNeedDrawBorder: Bool = false
    
    /// Has shadow attribute
    private(set) var isNeedDrawShadow: Bool = false

    /// Has underline attribute
    private(set) var isNeedDrawUnderline: Bool = false

    /// Has visible Text
    private(set) var isNeedDrawText: Bool = false

    /// Has attachment attribute
    private(set) var isNeedDrawAttachment: Bool = false

    /// Has inner shadow attribute
    private(set) var isNeedDrawInnerShadow: Bool = false

    /// Has strikethrough attribute
    private(set) var isNeedDrawStrickethrough: Bool = false
    
    /// 每一row第一个line的index
    private lazy var lineRowsIndex: ContiguousArray<Int> = []
    
    // top-left origin 每个row的上边距和下边距
    private lazy var lineRowsEdge: ContiguousArray<RowEdge> = []


    // MARK: - Initializers

    convenience init?(containerSize: CGSize, text: NSAttributedString) {
        let container = PoTextContainer(size: containerSize)
        self.init(container: container, text: text)
    }
    
    init?(container: PoTextContainer, text: NSAttributedString) {
        if text.length == 0 { return nil }
        
        self.container = container
        self.text = text
        
        var cgPath: CGPath
        var cgPathBox: CGRect = .zero
        var rowMaySeparated: Bool = false
        var isNeedTruncation: Bool = false
        let maximumNuberOfRows: Int = container.maximumNumberOfRows
        
        // set cgPath and cgPathBox
        if container.exclusionPaths == nil || container.exclusionPaths?.isEmpty == true { // 没有exclusionPath
            if container.path == nil {
                if container.size.width <= 0 || container.size.height <= 0 { return nil }

                var rect = CGRect(origin: .zero, size: container.size)
                rect = rect.inset(by: container.insets)
                rect = rect.standardized
                cgPathBox = rect
                rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
                cgPath = CGPath(rect: rect, transform: nil)
            } else if container.path?.cgPath.isRect(&cgPathBox) == true {
                let rect = cgPathBox.applying(CGAffineTransform(scaleX: 1, y: -1))
                cgPath = CGPath(rect: rect, transform: nil)
            } else {
                return nil
            }
        } else { // 存在exclusionPath
            rowMaySeparated = true
            var path: CGMutablePath!
            if container.path != nil {
                path = container.path?.cgPath.mutableCopy()
            } else {
                var rect = CGRect(origin: .zero, size: container.size)
                rect = rect.inset(by: container.insets)
                let rectPath = CGPath(rect: rect, transform: nil)
                path = rectPath.mutableCopy()
            }
            
            for exclusionPath in container.exclusionPaths! {
                path.addPath(exclusionPath.cgPath)
            }
            
            cgPathBox = path.boundingBoxOfPath
            var trans = CGAffineTransform(scaleX: 1, y: -1)
            path = path.mutableCopy(using: &trans)
            cgPath = path
        }
        
        
        // frame setter config
        var frameAttrs = Dictionary<CFString, CFNumber>()
        if container.isPathFillEvenOdd == false { // evenOdd is the default behavior
            var value = CTFramePathFillRule.windingNumber.rawValue
            frameAttrs[kCTFramePathFillRuleAttributeName] = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &value)
        }
        if container.pathLineWidth > 0 {
            var value = container.pathLineWidth // 0 width is the default behavior
            frameAttrs[kCTFramePathWidthAttributeName] = CFNumberCreate(kCFAllocatorDefault, .cgFloatType, &value)
        }
        
        // create CoreText objects
        ctFrameSetter = CTFramesetterCreateWithAttributedString(text)
        ctFrame = CTFramesetterCreateFrame(ctFrameSetter, CFRange(location: 0, length: text.length), cgPath, frameAttrs as CFDictionary)
        let ctLines = CTFrameGetLines(ctFrame)
        let lineCount = CFArrayGetCount(ctLines)
        var lineOrigins = Array(repeating: CGPoint.zero, count: lineCount)
        CTFrameGetLineOrigins(ctFrame, CFRange(location: 0, length: lineCount), &lineOrigins)

        var rowIdx = -1
        var lastRect: CGRect = CGRect(x: 0, y: -.greatestFiniteMagnitude, width: 0, height: 0)
        var lastPosition: CGPoint = CGPoint(x: 0, y: -.greatestFiniteMagnitude)
        // calculate line frame
        var currentLineIdx = 0
        for i in 0..<lineCount {
            let ctLine = unsafeBitCast(CFArrayGetValueAtIndex(ctLines, i), to: CTLine.self)
            let ctRuns = CTLineGetGlyphRuns(ctLine)
            if CFArrayGetCount(ctRuns) == 0 { continue }
            
            // CoreText coordinate system
            let ctLineOrigin = lineOrigins[i]
            
            // UIKit coordinate system
            let position = CGPoint(x: cgPathBox.minX + ctLineOrigin.x, y: cgPathBox.minY + cgPathBox.height - ctLineOrigin.y)
            
            let line = PoTextLine(ctLine: ctLine, position: position)
            let rect = line.bounds
            
            var isNewRow = true
            if rowMaySeparated && abs(position.x - lastPosition.x) < .ulpOfOne {
                if rect.height > lastRect.height {
                    if rect.minY < lastPosition.y && lastPosition.y < rect.maxY { isNewRow = false }
                } else {
                    if lastRect.minY < position.y && position.y < lastRect.maxY { isNewRow = false }
                }
            }
            
            if isNewRow { rowIdx += 1 }
            lastRect = rect
            lastPosition = position
            
            line.index = currentLineIdx
            line.row = rowIdx
            lines.append(line)
            currentLineIdx += 1
            
            if i == 0 {
                textBoundingRect = rect
            } else {
                if maximumNuberOfRows == 0 || rowIdx < maximumNuberOfRows {
                    textBoundingRect = textBoundingRect.union(rect)
                }
            }
        }
        rowCount = rowIdx + 1
        
        
        if rowCount > 0 {
            // 裁剪多余的line（当实际的行大于所设置的最大行时）
            if maximumNuberOfRows > 0 {
                if rowCount > maximumNuberOfRows {
                    isNeedTruncation = true
                    rowCount = maximumNuberOfRows
                    repeat {
                        guard let line = lines.last else { break }
                        if line.row < rowCount { break }
                        _ = lines.removeLast()
                    } while true
                }
            }
            
            // 当画板面积比较小，画不下所有的字符串时也应该截断
            if !isNeedTruncation, let lastLine = lines.last {
                if lastLine.range.location + lastLine.range.length < text.length { isNeedTruncation = true }
            }
            
            // give user a chance to modify the line's position
            if container.linePositionModifyer != nil {
                container.linePositionModifyer?.modifyLines(&lines, from: text, in: container)
                textBoundingRect = .zero
                for i in 0..<lines.count {
                    let line = lines[i]
                    if i == 0 {
                        textBoundingRect = line.bounds
                    } else {
                        textBoundingRect = textBoundingRect.union(line.bounds)
                    }
                }
            }
            
            lineRowsEdge = ContiguousArray<RowEdge>(repeating: RowEdge(head: 0, foot: 0), count: lines.count)
            lineRowsIndex = ContiguousArray<Int>(repeating: 0, count: lines.count)
            var lastRowIdx: Int = -1
            var lastHead: CGFloat = 0
            var lastFoot: CGFloat = 0
            for i in 0..<lines.count {
                let line = lines[i]
                let rect = line.bounds
                if line.row != lastRowIdx { // new row
                    if lastRowIdx >= 0 {
                        lineRowsEdge[lastRowIdx] = RowEdge(head: lastHead, foot: lastFoot)
                    }
                    lastRowIdx = line.row
                    lineRowsIndex[lastRowIdx] = i
                    lastHead = rect.minY
                    lastFoot = lastHead + rect.height
                } else { // not change row
                    lastHead = min(lastHead, rect.minY)
                    lastFoot = max(lastFoot, rect.minY + rect.height)
                }
            }
            lineRowsEdge[lastRowIdx] = RowEdge(head: lastHead, foot: lastFoot)
            
            for i in 1..<rowCount {
                let v0 = lineRowsEdge[i - 1]
                let v1 = lineRowsEdge[i]
                let value = (v0.foot + v1.head) * 0.5
                lineRowsEdge[i - 1].foot = value
                lineRowsEdge[i].head = value
            }
        }
        
        
        // calculate bouding size
        var rect: CGRect = textBoundingRect
        if container.path != nil {
            if container.pathLineWidth > 0 {
                let inset = container.pathLineWidth / 2
                rect = rect.insetBy(dx: -inset, dy: -inset)
            }
        } else {
            rect = rect.inset(by: container.insets.invert())
        }
        rect = rect.standardized
        var size = rect.size
        size.width += rect.minX
        size.height += rect.minY
        if size.width < 0 { size.width = 0 }
        if size.height < 0 { size.height = 0 }
        size.width = ceil(size.width)
        size.height = ceil(size.height)
        textBoundingSize = size
        
        
        // calculate visible range
        visibleRange = CTFrameGetVisibleStringRange(ctFrame).nsRange
        
        
        // truncation
        var truncationToken: NSAttributedString!
        if isNeedTruncation {
            let lastLine = lines.last!
            let lastRange = lastLine.range
            visibleRange.length = lastRange.location + lastRange.length - visibleRange.location
            
            // create truncated line
            if container.truncationType != .none {
                var truncationTokenLine: CTLine
                if container.truncationToken != nil { // 设置了省略的样式
                    truncationToken = container.truncationToken!
                } else { // 否则根据最后一个run设置省略的样式
                    let runs = CTLineGetGlyphRuns(lastLine.ctLine)
                    let runCount = CFArrayGetCount(runs)
                    var runAttrs: AttributesDictionary
                    let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runCount-1), to: CTRun.self)
                    runAttrs = CTRunGetAttributes(run) as! AttributesDictionary
                    for key in NSAttributedString.Key.allDiscontinuousAttributeKeys {
                        runAttrs.removeValue(forKey: key)
                    }
                    
                    var fontSize: CGFloat = 12
                    if let font = runAttrs[.font] as? UIFont {
                        fontSize = font.pointSize
                    }
                    runAttrs[.font] = UIFont.systemFont(ofSize: fontSize * 0.9)
                    
                    truncationToken = NSAttributedString(string: PoTextToken.truncation, attributes: runAttrs)
                }
                truncationTokenLine = CTLineCreateWithAttributedString(truncationToken)
                
                var type: CTLineTruncationType = .end
                if container.truncationType == .head {
                    type = .start
                } else if container.truncationType == .middle {
                    type = .middle
                }
                let lastLineText = NSMutableAttributedString(attributedString: text.attributedSubstring(from: lastLine.range))
                lastLineText.append(truncationToken)
                let ctLastLineExtend = CTLineCreateWithAttributedString(lastLineText)
                var truncationWidth = lastLine.width
                var cgPathRect = CGRect.zero
                if cgPath.isRect(&cgPathRect) {
                    truncationWidth = cgPathRect.width
                }
                if let ctTruncatedLine = CTLineCreateTruncatedLine(ctLastLineExtend, Double(truncationWidth), type, truncationTokenLine) {
                    truncatedLine = PoTextLine(ctLine: ctTruncatedLine, position: lastLine.position)
                    truncatedLine?.index = lastLine.index
                    truncatedLine?.row = lastLine.row
                }
            }
        }
        
        if visibleRange.length > 0 {
            isNeedDrawText = true
            
            let block: (AttributesDictionary, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void = { (attrs, range, stop) in
                if attrs[.poHighlight] != nil { self.isContainsHighlight = true }
                if attrs[.poAttachment] != nil { self.isNeedDrawAttachment = true }
                if attrs[.poShadow] != nil || attrs[.shadow] != nil { self.isNeedDrawShadow = true }
                if attrs[.poInnerShadow] != nil { self.isNeedDrawInnerShadow = true }
                if attrs[.poUnderline] != nil { self.isNeedDrawUnderline = true }
                if attrs[.poStrikethrough] != nil { self.isNeedDrawStrickethrough = true }
                if attrs[.poBorder] != nil { self.isNeedDrawBorder = true }
                if attrs[.poBlockBorder] != nil { self.isNeedDrawBlockBorder = true }
            }
            text.enumerateAttributes(in: visibleRange,
                                     options: .longestEffectiveRangeNotRequired,
                                     using: block)
            if truncationToken != nil {
                truncationToken.enumerateAttributes(in: NSRange(location: 0, length: truncationToken.length),
                                                    options: .longestEffectiveRangeNotRequired,
                                                    using: block)
            }
            
            for var line in lines {
                if truncatedLine != nil && line.index == truncatedLine!.index { line = truncatedLine! }
                if line.attachments?.isEmpty == false {
                    if attachments == nil {
                        attachments = []
                        attachmentRanges = []
                        attachmentRects = []
                        attachmentContentsSet = []
                    }
                    
                    attachments?.append(contentsOf: line.attachments!)
                    attachmentRanges?.append(contentsOf: line.attachmentRanges!)
                    attachmentRects?.append(contentsOf: line.attachmentRects!)
                    for attachment in line.attachments! {
                        attachmentContentsSet?.insert(attachment.content)
                    }
                }
            }
        }
        
    }

    
    // MARK: - Methods - [query infomation from text layout]
    
    /// The first line index for row.
    ///
    /// - Parameter row: row
    /// - Returns: the first line index for row, or NSNotFound when row not exist.
    func lineIndexForRow(_ row: Int) -> Int {
        if 0 <= row && row < rowCount {
            return lineRowsIndex[row]
        }
        return NSNotFound
    }

    
    /// The number of lines for row
    ///
    /// - Parameter row: row
    /// - Returns: the number of lines for row, or NSNotFound when row not exist.
    func lineCountForRow(_ row: Int) -> Int {
        if 0 <= row && row < rowCount {
            if row == rowCount - 1 {
                return lines.count - lineRowsIndex[row]
            } else {
                return lineRowsIndex[row + 1] - lineRowsIndex[row]
            }
        }
        return NSNotFound
    }

    
    /// Line in which row.
    ///
    /// - Parameter index: line index
    /// - Returns: row index, or NSNotFound when line not exist.
    func rowIndexForLineIndex(_ index: Int) -> Int {
        if 0 <= index && index < lines.count {
            return lines[index].row
        }
        return NSNotFound
    }

    
    /// The line index for a specified point
    ///
    /// - Parameter point: point
    /// - Returns: line index, or NSNotFound when the line not exist.
    func lineIndexForPoint(_ point: CGPoint) -> Int {
        if lines.count == 0 { return NSNotFound }
        
        let rowIdx = _rowIndexForEdge(point.y)
        if rowIdx == NSNotFound { return NSNotFound }
        
        let startLineIdx = lineRowsIndex[rowIdx]
        let endLineIdx = (rowIdx == rowCount - 1) ? lines.count - 1 : lineRowsIndex[rowIdx + 1] - 1
        
        for i in startLineIdx...endLineIdx {
            let bounds = lines[i].bounds
            if bounds.contains(point) {
                return i
            }
        }
        return NSNotFound
    }

    
    /// The line index closest to a specified point
    ///
    /// - Parameter point: point
    /// - Returns: closest line index, or NSNotFound when there has not line.
    func closestLineIndexForPoint(_ point: CGPoint) -> Int {
        if lines.count == 0 { return NSNotFound }
        
        let rowIdx = _closestRowIndexForEdge(point.y)
        let startLineIdx = lineRowsIndex[rowIdx]
        let endLineIdx = (rowIdx == rowCount - 1) ? lines.count - 1 : lineRowsIndex[rowIdx + 1] - 1
        if startLineIdx == endLineIdx { return startLineIdx }
        
        var minDistance = CGFloat.greatestFiniteMagnitude
        var minIdx = startLineIdx
        for i in startLineIdx...endLineIdx {
            let bounds = lines[i].bounds
            if bounds.minX <= point.x && point.x <= bounds.maxX { return i }
            var distance: CGFloat = 0
            if point.x < bounds.minX {
                distance = bounds.minX - point.x
            } else {
                distance = point.x - (bounds.maxX)
            }
            
            if distance < minDistance {
                minDistance = distance
                minIdx = i
            }
        }
        return minIdx
    }

    
    /// The offset in container for a text position in a specified line
    ///
    /// - Parameters:
    ///   - position: text position in full text.
    ///   - lineIndex: line index
    /// - Returns: text position's offset, or CGFloat.greatestFiniteMagnitude when parameters not match.
    func offsetForTextPosition(_ position: Int, lineIndex: Int) -> CGFloat {
        if 0 <= lineIndex && lineIndex < lines.count {
            let line = lines[lineIndex]
            if position < line.range.location || position > line.range.location + line.range.length {
                return .greatestFiniteMagnitude
            }
            let offset = CTLineGetOffsetForStringIndex(line.ctLine, position, nil)
            return line.position.x + offset
        }
        return .greatestFiniteMagnitude
    }
    
    
    /// The text position for a point in a specified line
    ///
    /// - Parameters:
    ///   - point: point
    ///   - lineIndex: line index
    /// - Returns: text position in full text, or NSNotFound when the line not exist.
    func textPositionForPoint(_ point: CGPoint, lineIndex: Int) -> Int {
        if 0 <= lineIndex && lineIndex <= lines.count {
            let line = lines[lineIndex]
            var onePoint = point
            onePoint.x -= line.position.x
            onePoint.y = 0
            return CTLineGetStringIndexForPosition(line.ctLine, onePoint)
        }
        return NSNotFound
    }
    
    
    /// The text position for a point
    ///
    /// - Parameter point: point
    /// - Returns: text position in full text, or NSNotFound when the line not exist.
    func textPositionForPoint(_ point: CGPoint) -> Int {
        let lineIdx = lineIndexForPoint(point)
        if lineIdx == NSNotFound { return NSNotFound }
        
        let line = lines[lineIdx]
        var aPoint = point
        aPoint.x -= line.position.x
        aPoint.y = 0
        return CTLineGetStringIndexForPosition(line.ctLine, aPoint)
    }
    
    /// The closest text position to a specified point
    func closestPositionToPoint(_ point: CGPoint) -> PoTextPosition? {
        // When call CTLineGetStringIndexForPosition() on ligature such as 'fi',
        // and the point `hit` the glyph's left edge, it may get the ligature inside offset.
        // I don't know why, maybe it's a bug of CoreText. Try to avoid it.
        var onePoint = point
        onePoint.x += 0.00001234
        
        let lineIndex = closestLineIndexForPoint(onePoint)
        if lineIndex == NSNotFound { return nil }
        
        let line = lines[lineIndex]
        var position = textPositionForPoint(onePoint, lineIndex: lineIndex)
        if position == NSNotFound {
            position = line.range.location
        }
        if position <= visibleRange.location {
            return PoTextPosition(offset: visibleRange.location, affinity: .forward)
        } else if position >= visibleRange.location + visibleRange.length {
            return PoTextPosition(offset: visibleRange.location + visibleRange.length, affinity: .backward)
        }
        
        var finalAffinity = UITextStorageDirection.forward
        var finalAffinityDetected = false
        
        // detect whether the line is a linebreak token
        if line.range.length <= 2 {
            let str = (text.string as NSString).substring(with: line.range) as NSString
            if PoTextUtilities.isLineBreakString(str) {
                return PoTextPosition(offset: line.range.location)
            }
        }
        
        // above whole text frame
        if lineIndex == 0 && point.y < line.top {
            position = 0
            finalAffinity = .forward
            finalAffinityDetected = true
        }
        
        // below whole text frame
        if lineIndex == lines.count - 1 && point.y > line.bottom {
            position = line.range.location + line.range.length
            finalAffinity = .backward
            finalAffinityDetected = true
        }
        
        // There must be at least one non-linebreak char,
        // ignore the linebreak characters at line end if exists.
        if position >= line.range.location + line.range.length - 1 {
            if position > line.range.location {
                let nsString = (text.string as NSString)
                let c1 = nsString.character(at: position - 1)
                if PoTextUtilities.isLinebreakChar(unichar: c1) {
                    position -= 1
                    if position > line.range.location {
                        let c0 = nsString.character(at: position - 1)
                        if PoTextUtilities.isLinebreakChar(unichar: c0) {
                            position -= 1
                        }
                    }
                }
            }
        }
        
        if position == line.range.location {
            return PoTextPosition(offset: position)
        }
        
        if position == line.range.location + line.range.length {
            return PoTextPosition(offset: position, affinity: .backward)
        }
        
        _insideComposedCharacterSequences(line, position: position) { (left, right, pre, next) in
            position = abs(left - point.x) < abs(right - point.x) ? pre : next
        }
        
        _insideEmoji(line, position: position) { (left, right, pre, next) in
            position = abs(left - point.x) < abs(right - point.x) ? pre : next
        }
        
        if position < visibleRange.location {
            position = visibleRange.location
        } else if position > visibleRange.location + visibleRange.length {
            position = visibleRange.location + visibleRange.length
        }
        
        if !finalAffinityDetected {
            let ofs = offsetForTextPosition(position, lineIndex: lineIndex)
            if ofs != .greatestFiniteMagnitude {
                let RTL = _isRightToLeftInLine(line, at: point)
                if position >= line.range.location + line.range.length {
                    finalAffinity = RTL ? .forward : .backward
                } else if position <= line.range.location {
                    finalAffinity = RTL ? .backward : .forward
                } else {
                    finalAffinity = (ofs < point.x && !RTL) ? .forward : .backward
                }
            }
        }
        
        return PoTextPosition(offset: position, affinity: finalAffinity)
    }
    
    
    /// Return the new position when moving selection grabber in text view
    func positionForPoint(_ point: CGPoint, oldPosition: PoTextPosition, otherPosition: PoTextPosition) -> PoTextPosition {
        guard let newPosition = closestPositionToPoint(point) else { return oldPosition }
        if newPosition.compare(otherPosition) == oldPosition.compare(otherPosition) && newPosition.offset != otherPosition.offset {
            return newPosition
        }
        
        let lineIdx = lineIndexForPosition(otherPosition)
        if lineIdx == NSNotFound { return oldPosition }
        
        let line = lines[lineIdx]
        let rowEdge = lineRowsEdge[line.row]
        var onePoint = point
        onePoint.y = (rowEdge.head + rowEdge.foot) * 0.5
        if let newPos = closestPositionToPoint(onePoint) {
            if newPos.compare(otherPosition) == oldPosition.compare(otherPosition) && newPos.offset != otherPosition.offset {
                return newPos
            }
        }
        
        if oldPosition.compare(otherPosition) == .orderedAscending { // search backward
            if let range = textRangeByExtendingPosition(otherPosition, direction: .left, offset: 1) {
                return range.start
            }
        } else {
            if let range = textRangeByExtendingPosition(otherPosition, direction: .right, offset: 1) {
                return range.end
            }
        }
        return oldPosition
    }

    
    /// Return the character or range of characters that is at a given point in the container.
    func textRangeAtPoint(_ point: CGPoint) -> PoTextRange? {
        let lineIdx = lineIndexForPoint(point)
        if lineIdx == NSNotFound { return nil }
        
        let textPosition = textPositionForPoint(point, lineIndex: lineIdx)
        if textPosition == NSNotFound { return nil }
        
        guard let pos = closestPositionToPoint(point) else { return nil }
        
        let RTL = _isRightToLeftInLine(lines[lineIdx], at: point)
        let rect = caretRectForPosition(pos)
        if rect.isNull == true { return nil }
        
        let direction: UITextLayoutDirection = (rect.minX >= point.x && RTL == false) ? .up : .down
        return textRangeByExtendingPosition(pos, direction: direction, offset: 1)
    }

    
    /// Return the closest character or range of characters that is at a given point in the container
    func closestTextRangeAtPoint(_ point: CGPoint) -> PoTextRange? {
        guard let pos = closestPositionToPoint(point) else { return nil }
        
        let lineIdx = lineIndexForPosition(pos)
        if lineIdx == NSNotFound { return nil }
        
        let line = lines[lineIdx]
        let RTL = _isRightToLeftInLine(line, at: point)
        let rect = caretRectForPosition(pos)
        if rect.isNull { return nil }
        
        var layoutDirection: UITextLayoutDirection = .right
        if pos.offset >= line.range.location + line.range.length {
            if RTL {
                layoutDirection = .right
            } else {
                layoutDirection = .left
            }
        } else if pos.offset <= line.range.location {
            if RTL {
                layoutDirection = .left
            } else {
                layoutDirection = .right
            }
        } else {
            if rect.minX >= point.x && RTL == false {
                layoutDirection = .left
            } else {
                layoutDirection = .right
            }
        }
        
        return textRangeByExtendingPosition(pos, direction: layoutDirection, offset: 1)
    }

    
    /// If the position is inside an emoji, composed character sequences, line break '\\r\\n'
    /// or custom binding range, then returns the range by extend the position. Otherwise,
    /// returns a zero length range from the position.
    func textRangeByExtendingPosition(_ position: PoTextPosition) -> PoTextRange? {
        let visibleStart = visibleRange.location
        let visibleEnd = visibleRange.location + visibleRange.length
        
        if position.offset < visibleStart || position.offset > visibleEnd { return nil }
        
        // head or tail, returns immediately
        if position.offset == visibleStart {
            return PoTextRange(range: NSRange(location: position.offset, length: 0))
        } else if position.offset == visibleEnd {
            return PoTextRange(range: NSRange(location: position.offset, length: 0), affinity: .backward)
        }
        
        // inside emoji or composed character sequences
        let lineIndex = lineIndexForPosition(position)
        if lineIndex != NSNotFound {
            var _prev = 0
            var _next = 0
            var emoji = false
            var seq = false
            
            let line = lines[lineIndex]
            emoji = _insideEmoji(line, position: position.offset, block: { (_, _, pre, next) in
                _prev = pre
                _next = next
            })
            
            if emoji == false {
                seq = _insideComposedCharacterSequences(line, position: position.offset, block: { (_, _, pre, next) in
                    _prev = pre
                    _next = next
                })
            }
            
            if emoji || seq {
                return PoTextRange(range: NSRange(location: _prev, length: _next - _prev))
            }
        }
        
        // inside linebreak '\r\n'
        if position.offset > visibleStart && position.offset < visibleEnd {
            let nsString = text.string as NSString
            let c0 = nsString.character(at: position.offset - 1)
            if c0 == 0x0D { // '\r'
                let c1 = nsString.character(at: position.offset)
                if c1 == 0x0A { // '\n'
                    return PoTextRange(start: PoTextPosition(offset: position.offset - 1),
                                       end: PoTextPosition(offset: position.offset + 1))
                }
            }
            
            if PoTextUtilities.isLinebreakChar(unichar: c0) && position.affinity == .backward {
                let str = nsString.substring(to: position.offset) as NSString
                let len = PoTextUtilities.lineBreakTailLength(str)
                return PoTextRange(start: PoTextPosition(offset: position.offset - len),
                                   end: PoTextPosition(offset: position.offset))
            }
        }
        
        return PoTextRange(range: NSRange(location: position.offset, length: 0), affinity: position.affinity)
    }
    
    /// Return a text range at a given offset in a specified direction from another
    /// text position to its farthest extent in a certain direction of layout
    func textRangeByExtendingPosition(_ position: PoTextPosition, direction: UITextLayoutDirection, offset: Int) -> PoTextRange? {
        var offset = offset
        let visibleStart = visibleRange.location
        let visibleEnd = visibleRange.location + visibleRange.length
        
        if position.offset < visibleStart || position.offset > visibleEnd { return nil }
        if offset == 0 { return textRangeByExtendingPosition(position) }
        var isForwardMove = direction == .down || direction == .right
        let isVerticalMove = direction == .up || direction == .down
        
        if offset < 0 {
            isForwardMove = !isForwardMove
            offset = -offset
        }
        
        // head or tail, returns immediately
        if !isForwardMove && position.offset == visibleStart {
            return PoTextRange(range: NSRange(location: visibleStart, length: 0))
        } else if isForwardMove && position.offset == visibleEnd {
            return PoTextRange(range: NSRange(location: visibleEnd, length: 0), affinity: .backward)
        }
        
        // extend from position
        guard let fromRange = textRangeByExtendingPosition(position) else { return nil }
        let allForward = PoTextRange(start: fromRange.start, end: PoTextPosition(offset: visibleEnd))
        let allBackward = PoTextRange(start: PoTextPosition(offset: visibleStart), end: fromRange.end)
        
        if isVerticalMove { // up/down in text layout
            let lineIdx = lineIndexForPosition(position)
            if lineIdx == NSNotFound { return nil }
            
            let line = lines[lineIdx]
            let moveToRowIdx = line.row + (isForwardMove ? offset : -offset)
            if moveToRowIdx < 0 {
                return allBackward
            } else if moveToRowIdx >= rowCount {
                return allForward
            }
            
            let ofs = offsetForTextPosition(position.offset, lineIndex: lineIdx)
            if ofs == .greatestFiniteMagnitude { return nil }
            
            let moveToLineFirstIdx = lineIndexForRow(moveToRowIdx)
            let moveToLineCount = lineCountForRow(moveToRowIdx)
            if moveToLineFirstIdx == NSNotFound || moveToLineCount == NSNotFound || moveToLineCount == 0 { return nil }
            
            var mostLeft = CGFloat.greatestFiniteMagnitude
            var mostRight = CGFloat.greatestFiniteMagnitude
            var mostLeftLine: PoTextLine?
            var mostRightLine: PoTextLine?
            var insideIdx = NSNotFound
            for i in 0..<moveToLineCount {
                let lineIndex = moveToLineFirstIdx + i
                let line = lines[lineIndex]
                if line.left < ofs && ofs <= line.right {
                    insideIdx = lineIndex
                    break
                }
                if line.left < mostLeft {
                    mostLeft = line.left
                    mostLeftLine = line
                }
                if line.right > mostRight {
                    mostRight = line.right
                    mostRightLine = line
                }
            }
            var isAfinityEdge = false
            if insideIdx == NSNotFound {
                if ofs <= mostLeft {
                    insideIdx = mostLeftLine!.index
                } else {
                    insideIdx = mostRightLine!.index
                }
                isAfinityEdge = true
            }
            let insideLine = lines[insideIdx]
            let pos = textPositionForPoint(CGPoint(x: ofs, y: insideLine.position.y), lineIndex: insideIdx)
            if pos == NSNotFound { return nil }
            var extPos: PoTextPosition
            if isAfinityEdge {
                if pos == insideLine.range.location + insideLine.range.length {
                    let subStr = (text.string as NSString).substring(with: insideLine.range) as NSString
                    let lineBreakLen = PoTextUtilities.lineBreakTailLength(subStr)
                    extPos = PoTextPosition(offset: pos - lineBreakLen)
                } else {
                    extPos = PoTextPosition(offset: pos)
                }
            } else {
                extPos = PoTextPosition(offset: pos)
            }
            guard let ext = textRangeByExtendingPosition(extPos) else { return nil }
            if isForwardMove {
                return PoTextRange(start: fromRange.start, end: ext.end)
            } else {
                return PoTextRange(start: ext.start, end: fromRange.end)
            }
            
        } else { // left/right in text layout
            let toPosition = PoTextPosition(offset: position.offset + (isForwardMove ? offset : -offset))
            if toPosition.offset <= visibleStart {
                return allBackward
            } else if toPosition.offset >= visibleEnd {
                return allForward
            }
            
            guard let toRange = textRangeByExtendingPosition(toPosition) else { return nil }
            let start = min(fromRange.start.offset, toRange.start.offset)
            let end = max(fromRange.end.offset, toRange.end.offset)
            return PoTextRange(range: NSRange(location: start, length: end - start))
        }
    }

    /// Return the line index for a given text postion
    func lineIndexForPosition(_ position: PoTextPosition) -> Int {
        if lines.count == 0 { return NSNotFound }
        let location = position.offset
        var low = 0
        var high = lines.count - 1
        var mid = 0
        if position.affinity == .backward {
            while low <= high {
                mid = (low + high) / 2
                let range = lines[mid].range
                if range.location < location && location <= range.location + range.length {
                    return mid
                }
                if location <= range.location {
                    high = mid - 1
                } else {
                    low = mid + 1
                }
            }
        } else {
            while low <= high {
                mid = (low + high) / 2
                let range = lines[mid].range
                if range.location <= location && location < range.location + range.length {
                    return mid
                }
                if location < range.location {
                    high = mid - 1
                } else {
                    low = mid + 1
                }
            }
        }
        return NSNotFound
    }

    
    /// Return the baseline position for a given text position
    func linePositionForPosition(_ position: PoTextPosition) -> CGPoint {
        let lineIdx = lineIndexForPosition(position)
        if lineIdx == NSNotFound { return .zero }
        
        let line = lines[lineIdx]
        let offset = offsetForTextPosition(position.offset, lineIndex: lineIdx)
        if offset == .greatestFiniteMagnitude { return .zero }
        
        return CGPoint(x: offset, y: line.position.y)
    }

    
    /// Return a rectangle used to draw the caret at a given insertion point
    func caretRectForPosition(_ position: PoTextPosition) -> CGRect {
        let lineIdx = lineIndexForPosition(position)
        if lineIdx == NSNotFound { return .null }
        
        let line = lines[lineIdx]
        let offset = offsetForTextPosition(position.offset, lineIndex: lineIdx)
        if offset == .greatestFiniteMagnitude { return .null }
        
        return CGRect(x: offset, y: line.bounds.minY, width: 0, height: line.height)
    }

    
    /// Return the first rectangle that encloses a range of text in the layout
    func firstRectForRange(_ range: PoTextRange) -> CGRect {
        let range = _correctedRangeWithEdge(range)
        
        let startLineIdx = lineIndexForPosition(range.start)
        let endLineIdx = lineIndexForPosition(range.end)
        
        if startLineIdx == NSNotFound || endLineIdx == NSNotFound { return .null }
        if startLineIdx > endLineIdx { return .null }
        
        let startLine = lines[startLineIdx]
        let endLine = lines[endLineIdx]
        var lineArray = [PoTextLine]()
        for i in startLineIdx...endLineIdx {
            let line = lines[i]
            if line.row != startLine.row { break }
            lineArray.append(line)
        }
        
        if lineArray.count == 1 {
            var left = offsetForTextPosition(range.start.offset, lineIndex: startLineIdx)
            var right: CGFloat = 0
            if startLine == endLine {
                right = offsetForTextPosition(range.end.offset, lineIndex: startLineIdx)
            } else {
                right = startLine.right
            }
            if left == .greatestFiniteMagnitude || right == .greatestFiniteMagnitude { return .null }
            if left > right {
                let tmp = left
                left = right
                right = tmp
            }
            return CGRect(x: left, y: startLine.top, width: right - left, height: startLine.height)
        } else {
            var left = offsetForTextPosition(range.start.offset, lineIndex: startLineIdx)
            var right = startLine.right
            if left == .greatestFiniteMagnitude || right == .greatestFiniteMagnitude { return .null }
            if left > right {
                let tmp = left
                left = right
                right = tmp
            }
            var rect = CGRect(x: left, y: startLine.top, width: right - left, height: startLine.height)
            for i in 1..<lines.count {
                let line = lines[i]
                rect = rect.union(line.bounds)
            }
            return rect
        }
    }
    
    
    /// Return the rectangle union that encloses a range of text in the layout
    func rectForRange(_ range: PoTextRange) -> CGRect {
        let rects = selectionRectsForRange(range)
        if rects.count == 0 { return .null }
        var rectUnion = rects[0].rect
        for i in 1..<rects.count {
            let rect = rects[i]
            rectUnion = rectUnion.union(rect.rect)
        }
        return rectUnion
    }
    
    
    /// Return an array of selection rects corresponding to the range of text
    /// The start and end rect can be used to show grabber
    func selectionRectsForRange(_ range: PoTextRange) -> [PoTextSelectionRect] {
        let oneRange = _correctedRangeWithEdge(range)
        
        var rects = [PoTextSelectionRect]()
        var startLineIdx = lineIndexForPosition(oneRange.start)
        var  endLineIdx = lineIndexForPosition(oneRange.end)
        if startLineIdx == NSNotFound || endLineIdx == NSNotFound { return rects }
        if startLineIdx > endLineIdx {
            let tem = startLineIdx
            startLineIdx = endLineIdx
            endLineIdx = tem
        }
        let startLine = lines[startLineIdx]
        let endLine = lines[endLineIdx]
        var offsetStart = offsetForTextPosition(oneRange.start.offset, lineIndex: startLineIdx)
        var offsetEnd = offsetForTextPosition(oneRange.end.offset, lineIndex: endLineIdx)
        
        let start = PoTextSelectionRect()
        start.rect = CGRect(x: offsetStart, y: startLine.top, width: 0, height: startLine.height)
        start.containsStart = true
        rects.append(start)
        
        let end = PoTextSelectionRect()
        end.rect = CGRect(x: offsetEnd, y: endLine.top, width: 0, height: endLine.height)
        end.containsEnd = true
        rects.append(end)
        
        if startLine.row == endLine.row { // same row
            if offsetStart > offsetEnd {
                let tmp = offsetStart
                offsetStart = offsetEnd
                offsetEnd = tmp
            }
            let rect = PoTextSelectionRect()
            rect.rect = CGRect(x: offsetStart, y: startLine.top, width: offsetEnd - offsetStart, height: max(startLine.height, endLine.height))
            rects.append(rect)
        } else { // more than one row
            
            // start line select rect
            let topRect = PoTextSelectionRect()
            let topOffset = offsetForTextPosition(oneRange.start.offset, lineIndex: startLineIdx)
            let topRun = _runForLine(startLine, position: oneRange.start)
            if topRun != nil && CTRunGetStatus(topRun!) == .rightToLeft {
                let y = container.path == nil ? container.insets.top : startLine.top
                topRect.rect = CGRect(x: startLine.left, y:  y, width: startLine.width, height: startLine.height)
                topRect.writingDirection = .rightToLeft
            } else {
                let width = container.path == nil ? container.size.width - container.insets.right : startLine.top
                topRect.rect = CGRect(x: topOffset, y: startLine.top, width: width, height: startLine.height)
            }
            rects.append(topRect)
            
            // end line select rect
            let bottomRect = PoTextSelectionRect()
            let bottomOffset = offsetForTextPosition(oneRange.end.offset, lineIndex: endLineIdx)
            let bottomRun = _runForLine(endLine, position: oneRange.end)
            if bottomRun != nil && CTRunGetStatus(bottomRun!) == .rightToLeft {
                let width = container.path == nil ? container.size.width - container.insets.right : endLine.right
                bottomRect.rect = CGRect(x: bottomOffset, y: endLine.top, width: width, height: endLine.height)
                bottomRect.writingDirection = .rightToLeft
            } else {
                let x = container.path == nil ? container.insets.left : endLine.left
                bottomRect.rect = CGRect(x: x, y: endLine.top, width: bottomOffset - x, height: endLine.height)
            }
            rects.append(bottomRect)
            
            if endLineIdx - startLineIdx >= 2 {
                var r = CGRect.zero
                var startLineDetected = false
                for i in (startLineIdx + 1)..<endLineIdx {
                    let line = lines[i]
                    if line.row == startLine.row || line.row == endLine.row { continue }
                    if !startLineDetected {
                        r = line.bounds
                        startLineDetected = true
                    } else {
                        r = r.union(line.bounds)
                    }
                    
                    if startLineDetected {
                        if container.path == nil {
                            r.origin.x = container.insets.left
                            r.size.width = container.size.width - container.insets.right - container.insets.left
                        }
                        r.origin.y = topRect.rect.maxY
                        r.size.height = bottomRect.rect.minY - r.minY
                    }
                    
                    let rect = PoTextSelectionRect()
                    rect.rect = r
                    rects.append(rect)
                }
            } else {
                var r0 = topRect.rect
                var r1 = bottomRect.rect
                let mid = (r0.maxY + r1.minY) * 0.5
                r0.size.height = mid - r0.minY
                let r1ofs = r1.minY - mid
                r1.origin.y -= r1ofs
                r1.size.height += r1ofs
                topRect.rect = r0
                bottomRect.rect = r1
            }
        }
        
        return rects
    }
    
    
    /// Return an array of selection rects corresponding to the range of text
    func selectionRectsWithoutStartAndEndForRange(_ range: PoTextRange) -> [PoTextSelectionRect] {
        var rects = selectionRectsForRange(range)
        rects.removeAll { (rect) -> Bool in
            return rect.containsStart || rect.containsEnd
        }
        return rects
    }
    
    
    /// Return the start and end selection rects corresponding to the range of text
    func selectionRectsWithOnlyStartAndEndForRange(_ range: PoTextRange) -> [PoTextSelectionRect] {
        var rects = selectionRectsForRange(range)
        rects.removeAll { (rect) -> Bool in
            return !rect.containsStart && !rect.containsEnd
        }
        return rects
    }
    
    
    /// Get the row index with 'edge' distance.
    private func _rowIndexForEdge(_ edge: CGFloat) -> Int {
        if rowCount == 0 { return NSNotFound }
        
        var low = 0
        var high = rowCount - 1
        var mid = 0
        var rowIdx = NSNotFound
        while low <= high {
            mid = (low + high) / 2
            let oneEdge = lineRowsEdge[mid]
            if oneEdge.head <= edge && edge <= oneEdge.foot {
                rowIdx = mid
                break
            }
            if edge < oneEdge.head {
                high = mid - 1
            } else {
                low = mid + 1
            }
        }
        return rowIdx
    }
    
    
    /// Get the closest row index with 'edge' distance.
    private func _closestRowIndexForEdge(_ edge: CGFloat) -> Int {
        if rowCount == 0 { return NSNotFound }
        
        var rowIdx = _rowIndexForEdge(edge)
        if rowIdx == NSNotFound {
            if edge < lineRowsEdge[0].head {
                rowIdx = 0
            } else {
                rowIdx = rowCount - 1
            }
        }
        return rowIdx
    }
    
    
    /// Get a CTRun from a line position
    private func _runForLine(_ line: PoTextLine, position: PoTextPosition) -> CTRun? {
        let runs = CTLineGetGlyphRuns(line.ctLine)
        let runCount = CFArrayGetCount(runs)
        for i in 0..<runCount {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, i), to: CTRun.self)
            let range = CTRunGetStringRange(run)
            if position.affinity == .backward {
                if range.location < position.offset && position.offset <= range.location + range.length {
                    return run
                }
            } else {
                if range.location <= position.offset && position.offset < range.location + range.length {
                    return run
                }
            }
        }
        return nil
    }
    
    
    /// Whether the position is inside a composed character sequence
    ///
    /// - Parameters:
    ///   - line: The text line
    ///   - position: The text position in whole text
    ///   - block: The block to be executed before return Ture
    ///          left: left x offset
    ///          right: right x offset
    ///          prev: left position
    ///          next: right position
    /// - Returns:  ture or false
    @discardableResult
    private func _insideComposedCharacterSequences(_ line: PoTextLine, position: Int, block: ((CGFloat, CGFloat, Int, Int) -> Void)?) -> Bool {
        let range = line.range
        if range.length == 0 { return false }
        
        var inside: Bool = false
        var prev: Int = 0
        var next: Int = 0
        (text.string as NSString).enumerateSubstrings(in: range, options: .byComposedCharacterSequences) { (substr, substrRange, encloseingRange, stop) in
            prev = substrRange.location
            next = substrRange.location + substrRange.length
            if prev == position || next == position {
                stop.pointee = true
            }
            if prev < position && position < next {
                inside = true
                stop.pointee = true
            }
        }
        if inside {
            let left = offsetForTextPosition(prev, lineIndex: line.index)
            let right = offsetForTextPosition(next, lineIndex: line.index)
            block?(left, right, prev, next)
        }
        return inside
    }
    
    
    /// Whether the position is inside an emoji (such as National Flag Emoji).
    @discardableResult
    private func _insideEmoji(_ line: PoTextLine, position: Int, block: ((CGFloat, CGFloat, Int, Int) -> Void)?) -> Bool {
        let runs = CTLineGetGlyphRuns(line.ctLine)
        let runCount = CFArrayGetCount(runs)
        for i in 0..<runCount {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, i), to: CTRun.self)
            let glyphCount = CTRunGetGlyphCount(run)
            if glyphCount == 0 { continue }
            let range = CTRunGetStringRange(run)
            if range.length <= 1 { continue }
            if position <= range.location || position >= range.location + range.length { continue }

            let runAttrs = CTRunGetAttributes(run) as! AttributesDictionary
            if let font = runAttrs[.font] as? UIFont {
                if PoTextUtilities.ctFontContainsColorBitmapGlyphs(font as CTFont) { continue }
            }
            
            // Here's Emoji runs (larger than 1 unichar), and position is inside the range.
            var indices = Array<CFIndex>(repeating: 0, count: glyphCount)
            CTRunGetStringIndices(run, CFRange(location: 0, length: glyphCount), &indices)
            for g in 0..<glyphCount {
                let prev = indices[g]
                let next = (g + 1 < glyphCount) ? indices[g + 1] : range.location + range.length
                if position == prev { break } // Emoji edge
                if prev < position && position < next {  // inside an emoji (such as National Flag Emoji)
                    var pos = CGPoint.zero
                    var adv = CGSize.zero
                    CTRunGetPositions(run, CFRange(location: g, length: 1), &pos)
                    CTRunGetAdvances(run, CFRange(location: g, length: 1), &adv)
                    block?(line.position.x + pos.x, line.position.x + pos.x + adv.width, prev, next)
                    return true
                }
            }
        }
        return false
    }
    
    
    /// Whether the write direction is RTL at the specified point
    ///
    /// - Parameters:
    ///   - line: The text line
    ///   - point: The Point in layout
    /// - Returns: true if RTL
    private func _isRightToLeftInLine(_ line: PoTextLine, at point: CGPoint) -> Bool {
        var RTL = false
        let runs = CTLineGetGlyphRuns(line.ctLine)
        let runCount = CFArrayGetCount(runs)
        for r in 0..<runCount {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), to: CTRun.self)
            var glyphPosition = CGPoint.zero
            CTRunGetPositions(run, CFRange(location: 0, length: 1), &glyphPosition)
            var runX = glyphPosition.x
            runX += line.position.x
            let runWidth = CTRunGetTypographicBounds(run, CFRange.zero, nil, nil, nil)
            if runX <= point.x && point.x <= runX + CGFloat(runWidth) {
                if CTRunGetStatus(run) == .rightToLeft {
                    RTL = true
                }
                break
            }
        }
        return RTL
    }
    
    /// Correct the range's edge
    private func _correctedRangeWithEdge(_ range: PoTextRange) -> PoTextRange {
        var result = range
        let visibleRange = self.visibleRange
        var start = range.start
        var end = range.end
        
        if start.offset == visibleRange.location && start.affinity == .backward {
            start = PoTextPosition(offset: start.offset, affinity: .forward)
        }
        
        if end.offset == visibleRange.location + visibleRange.length && start.affinity == .forward {
            end = PoTextPosition(offset: end.offset, affinity: .backward)
        }
        
        if start != range.start || end != range.end {
            result = PoTextRange(start: start, end: end)
        }
        return result
    }

    // MARK: - Methods - [draw text layout]

    /**
     Draw the layout and show the attachments.

     @discussion If the `view` parameter is not nil, then the attachment views will
     add to this `view`, and if the `layer` parameter is not nil, then the attachment
     layers will add to this `layer`.

     @warning This method should be called on main thread if `view` or `layer` parameter
     is not nil and there's UIView or CALayer attachments in layout.
     Otherwise, it can be called on any thread.

     @param context The draw context. Pass nil to avoid text and image drawing.
     @param size    The context size.
     @param point   The point at which to draw the layout.
     @param view    The attachment views will add to this view.
     @param layer   The attachment layers will add to this layer.
     @param debug   The debug option. Pass nil to avoid debug drawing.
     @param cancel  The cancel checker block. It will be called in drawing progress.
     If it returns YES, the further draw progress will be canceled.
     Pass nil to ignore this feature.
     */
    func draw(in context: CGContext?, point: CGPoint, size: CGSize, view: UIView?, layer: CALayer?, cancel: (() -> Bool)? = nil) {
        autoreleasepool { () -> Void in
            if isNeedDrawBlockBorder && context != nil {
                if cancel?() == true { return }
                _drawBlockBorder(in: context!, layout: self, point: point, size: size, cancel: cancel)
            }
            
            if isNeedDrawBorder && context != nil {
                if cancel?() == true { return }
                _drawBorder(in: context!, layout: self, point: point, size: size, cancel: cancel)
            }
            
            if isNeedDrawShadow && context != nil {
                if cancel?() == true { return }
                _drawShadow(in: context!, layout: self, point: point, size: size, cancel: cancel)
            }
            
            if isNeedDrawUnderline && context != nil {
                if cancel?() == true { return }
                _drawDecoration(in: context!, layout: self, type: .underline, point: point, size: size, cancel: cancel)
            }
            
            if isNeedDrawText && context != nil {
                if cancel?() == true { return }
                _drawText(in: context!, layout: self, point: point, size: size, cancel: cancel)
            }
            
            if isNeedDrawAttachment && (context != nil || view != nil || layer != nil) {
                if cancel?() == true { return }
                _drawAttachment(in: context, layout: self, point: point, size: size, targetView: view, targetLayer: layer, cancel: cancel)
            }
            
            if isNeedDrawInnerShadow && context != nil {
                if cancel?() == true { return }
                _drawInnerShadow(in: context!, layout: self, point: point, size: size, cancel: cancel)
            }
            
            if isNeedDrawStrickethrough && context != nil {
                if cancel?() == true { return }
                _drawDecoration(in: context!, layout: self, type: .strikethrough, point: point, size: size, cancel: cancel)
            }
        }
    }

    /**
     Draw the layout text and image (without view or layer attachments).

     @discussion This method is thread safe and can be called on any thread.

     @param context The draw context. Pass nil to avoid text and image drawing.
     @param size    The context size.
     @param debug   The debug option. Pass nil to avoid debug drawing.
     */
    func draw(in context: CGContext?, size: CGSize) {
        draw(in: context, point: .zero, size: size, view: nil, layer: nil)
    }

    /**
     Show view and layer attachments.

     @warning This method must be called on main thread.

     @param view  The attachment views will add to this view.
     @param layer The attachment layers will add to this layer.
     */
    func addAttachmentTo(_ view: UIView?, layer: CALayer?) {
        assert(Thread.isMainThread, "This method must be called on the main thread.")
        draw(in: nil, point: .zero, size: .zero, view: view, layer: layer)
    }

    /**
     Remove attachment views and layers from their super container.

     @warning This method must be called on main thread.
     */
    func removeAttachmentFromViewAndLayer() {
        assert(Thread.isMainThread, "This method must be called on the main thread.")
        if let attachments = attachments {
            for attachment in attachments {
                if attachment.content is UIView {
                    (attachment.content as? UIView)?.removeFromSuperview()
                } else if attachment.content is CALayer {
                    (attachment.content as? CALayer)?.removeFromSuperlayer()
                }
            }
        }
    }
    
    
}


// MARK: - Private draw methods

/// 获取line中最大的xHeight、underlinePosition、underlineThickness
private func _getRunsMaxMetric(runs: CFArray, xHeight: inout CGFloat, underlinePosition: inout CGFloat, underlineThickness: inout CGFloat) {
    var maxXHeight: CGFloat = 0
    var maxUnderlinePosition: CGFloat = 0
    var maxUnderlineThickness: CGFloat = 0
    
    let runCount = CFArrayGetCount(runs)

    for i in 0..<runCount {
        let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, i), to: CTRun.self)
        let runAttrs = CTRunGetAttributes(run) as! AttributesDictionary
        
        if let value = runAttrs[.font] {
            let font = value as! CTFont
            let tmpXHeight = CTFontGetXHeight(font)
            if tmpXHeight > maxXHeight { maxXHeight = tmpXHeight }
            let tmpUnderlinePosition = CTFontGetUnderlinePosition(font)
            if tmpUnderlinePosition > maxUnderlinePosition { maxUnderlinePosition = tmpUnderlinePosition }
            let tmpunderlineThickness = CTFontGetUnderlineThickness(font)
            if tmpunderlineThickness > maxUnderlineThickness { maxUnderlineThickness = tmpunderlineThickness }
        }
    }

    xHeight = maxXHeight
    underlinePosition = maxUnderlinePosition
    underlineThickness = maxUnderlineThickness
}


private func _drawText(in context: CGContext, layout: PoTextLayout, point: CGPoint, size: CGSize, cancel: (() -> Bool)? = nil) {
    context.saveGState()
    defer { context.restoreGState() }
    
    context.translateBy(x: point.x, y: point.y)
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)
    
    for var line in layout.lines {
        if layout.truncatedLine != nil && layout.truncatedLine!.index == line.index { line = layout.truncatedLine! }
        let posX = line.position.x
        let posY = size.height - line.position.y
        let runs = CTLineGetGlyphRuns(line.ctLine)
        let runCount = CFArrayGetCount(runs)
        for r in 0..<runCount {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), to: CTRun.self)
            context.textMatrix = .identity
            context.textPosition = CGPoint(x: posX, y: posY)
            _drawRun(in: context, line: line, run: run, size: size)
        }
        if cancel?() == true { break }
    }
}


private func _drawRun(in context: CGContext, line: PoTextLine, run: CTRun, size: CGSize) {
    let runTextMatrix = CTRunGetTextMatrix(run)
    let runTextMatrixIsID = runTextMatrix.isIdentity
    
    let runAttrs = CTRunGetAttributes(run) as! AttributesDictionary
    
    if let glyphTransform = runAttrs[.poGlyphTransform] as? CGAffineTransform {
        guard let runFont = runAttrs[.font] as? UIFont else { return }
        let ctFont = runFont as CTFont
        
        let glyphCount = CTRunGetGlyphCount(run)
        if glyphCount <= 0 { return }
        
        var glyphs = Array<CGGlyph>(repeating: CGGlyph.max, count: glyphCount)
        var glyphPositions = Array<CGPoint>(repeating: CGPoint.zero, count: glyphCount)
        CTRunGetGlyphs(run, CFRange.zero, &glyphs)
        CTRunGetPositions(run, CFRange.zero, &glyphPositions)
        
        var fillColor = runAttrs[.foregroundColor] as? UIColor
        if fillColor == nil { fillColor = UIColor.black }
        let strokeWidth = runAttrs[.strokeWidth] as? Float
        
        do {
            context.saveGState()
            defer { context.restoreGState() }
            context.setFillColor(fillColor!.cgColor)
            if let strokeWidth = strokeWidth, strokeWidth != 0 {
                var strokeColor = runAttrs[.strokeColor] as? UIColor
                if strokeColor == nil { strokeColor = fillColor }
                context.setStrokeColor(strokeColor!.cgColor)
                context.setLineWidth(CTFontGetSize(ctFont) * CGFloat(abs(strokeWidth)) * 0.01)
                if strokeWidth > 0 {
                    context.setTextDrawingMode(.stroke)
                } else {
                    context.setTextDrawingMode(.fill)
                }
            } else {
                context.setTextDrawingMode(.fill)
            }
            
            var runStrIdx = Array<CFIndex>(repeating: 0, count: glyphCount + 1)
            CTRunGetStringIndices(run, CFRange.zero, &runStrIdx)
            let runstrRange = CTRunGetStringRange(run)
            runStrIdx[glyphCount] = runstrRange.location + runstrRange.length
            var glyphAdvances = Array<CGSize>(repeating: .zero, count: glyphCount)
            CTRunGetAdvances(run, CFRange.zero, &glyphAdvances)
            var zeroPoint = CGPoint.zero
            
            for g in 0..<glyphCount {
                do {
                    context.saveGState()
                    defer { context.restoreGState() }
                    context.textMatrix = glyphTransform
                    context.textPosition = CGPoint(x: line.position.x + glyphPositions[g].x,
                                                   y: size.height - (line.position.y + glyphPositions[g].y))
                    if PoTextUtilities.ctFontContainsColorBitmapGlyphs(ctFont) {
                        CTFontDrawGlyphs(ctFont, &glyphs[g], &zeroPoint, 1, context)
                    } else {
                        context.setFont(CTFontCopyGraphicsFont(ctFont, nil))
                        context.setFontSize(CTFontGetSize(ctFont))
                        context.showGlyphs([glyphs[g]], at: [zeroPoint])
                    }
                }
            }
        }
        
    } else {
        if runTextMatrixIsID == false {
            context.saveGState()
            context.textMatrix = context.textMatrix.concatenating(runTextMatrix)
        }
        CTRunDraw(run, context, CFRange.zero)
        if runTextMatrixIsID == false { context.restoreGState() }
    }
}

/// 当前行有任意run包含了.poBlockBorder属性，则整行都被填充（连续的行合并）
private func _drawBlockBorder(in context: CGContext, layout: PoTextLayout, point: CGPoint, size: CGSize, cancel: (() -> Bool)? = nil) {
    context.saveGState()
    defer { context.restoreGState() }
    context.translateBy(x: point.x, y: point.y)
    
    let lineCount = layout.lines.count
    var l = 0
    while l < lineCount {
        defer { l += 1 }
        if cancel?() == true { break }
        
        var line = layout.lines[l]
        if layout.truncatedLine != nil && layout.truncatedLine!.index == line.index { line = layout.truncatedLine! }
        
        let runs = CTLineGetGlyphRuns(line.ctLine)
        let runCount = CFArrayGetCount(runs)
        for r in 0..<runCount {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), to: CTRun.self)
            let glyphCount = CTRunGetGlyphCount(run)
            if glyphCount == 0 { continue }
            let runAttrs = CTRunGetAttributes(run) as! AttributesDictionary
            guard let border = runAttrs[.poBlockBorder] as? PoTextBorder else { continue }
            
            var unionRect = CGRect.zero
            let lineStartIdx = layout.lineIndexForRow(line.row)
            var lineContinueIdx = lineStartIdx
            var lineContinueRow = line.row
            repeat {
                let one = layout.lines[lineContinueIdx]
                if lineContinueIdx == lineStartIdx {
                    unionRect = one.bounds
                } else {
                    unionRect = unionRect.union(one.bounds)
                }
                if lineContinueIdx + 1 >= layout.lines.count { break }
                let next = layout.lines[lineContinueIdx + 1]
                if next.row != lineContinueRow {
                    if let nextBorder = layout.text.po.attribute(.poBlockBorder, at: next.range.location) as? PoTextBorder, nextBorder == border {
                        lineContinueRow += 1
                    } else {
                        break
                    }
                }
                lineContinueIdx += 1
            } while true
            
            let insets = layout.container.insets
            unionRect.origin.x = insets.left
            unionRect.size.width = layout.container.size.width - insets.left - insets.right
            _drawBorderRects(in: context, border: border, size: size, rects: [unionRect])
            
            l = lineContinueIdx
            break
        }
    }
}

/// 任意包含.poBorder的run被填充（同一line合并）
private func _drawBorder(in context: CGContext, layout: PoTextLayout, point: CGPoint, size: CGSize, cancel: (() -> Bool)? = nil) {
    context.saveGState()
    defer { context.restoreGState() }
    
    context.translateBy(x: point.x, y: point.y)
    let attrsName: NSAttributedString.Key = .poBorder
    
    let lineCount = layout.lines.count
    var shouldEndSearching = false // 停止寻找
    var hasChangedLine = false // 寻找run时是否换行了
    var l = 0
    var r = 0
    while l < lineCount {
        if cancel?() == true { break }
        
        var line = layout.lines[l]
        if layout.truncatedLine != nil && layout.truncatedLine!.index == line.index { line = layout.truncatedLine! }
        
        let runs = CTLineGetGlyphRuns(line.ctLine)
        let runCount = CFArrayGetCount(runs)
        hasChangedLine = false
        
        while r < runCount && !hasChangedLine {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), to: CTRun.self)
            let runAtrrs = CTRunGetAttributes(run) as! AttributesDictionary
            guard let border = runAtrrs[attrsName] as? PoTextBorder else { r += 1; continue }
            
            var runRects = [CGRect]() // 存储需要画的rect，同一行的rect需要合并
            var runPosition = CGPoint.zero
            CTRunGetPositions(run, CFRange(location: 0, length: 1), &runPosition)
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            let runWidth = CGFloat(CTRunGetTypographicBounds(run, CFRange.zero, &ascent, &descent, nil))
            let rect = CGRect(x: line.position.x + runPosition.x, y: line.position.y - ascent, width: runWidth, height: ascent + descent)
            runRects.append(rect)
            
            shouldEndSearching = false
            var iL = (r == runCount - 1) ? l + 1 : l
            let copyL = l // l可能会在下面改变，保留一份副本
            while iL < lineCount {
                var iLine: PoTextLine
                let iRuns: CFArray
                let iRunCount: Int
                var rr = 0
                var isSameLine = false
                
                if iL == copyL {
                    iLine = line
                    iRuns = runs
                    iRunCount = runCount
                    rr = r + 1
                    isSameLine = true
                } else {
                    iLine = layout.lines[iL]
                    if layout.truncatedLine != nil && layout.truncatedLine!.index == iLine.index { iLine = layout.truncatedLine! }
                    iRuns = CTLineGetGlyphRuns(iLine.ctLine)
                    iRunCount = CFArrayGetCount(iRuns)
                    hasChangedLine = true
                }
                
                while rr < iRunCount {
                    let iRun = unsafeBitCast(CFArrayGetValueAtIndex(iRuns, rr), to: CTRun.self)
                    let iRunAtrrs = CTRunGetAttributes(iRun) as! AttributesDictionary
                    
                    if let iBorder = iRunAtrrs[attrsName] as? PoTextBorder { // 找到下一个border
                        if iBorder == border { // 下一个border是一致的
                            var iRunPosition = CGPoint.zero
                            CTRunGetPositions(iRun, CFRange(location: 0, length: 1), &iRunPosition)
                            var iAscent: CGFloat = 0
                            var iDescent: CGFloat = 0
                            let iRunWidth = CGFloat(CTRunGetTypographicBounds(iRun, CFRange.zero, &iAscent, &iDescent, nil))
                            let iRect = CGRect(x: iLine.position.x + iRunPosition.x, y: iLine.position.y - iAscent, width: iRunWidth, height: iAscent + iDescent)
                            if (isSameLine) {
                                runRects[runRects.count - 1] = runRects.last!.union(iRect)
                            } else {
                                runRects.append(iRect)
                            }
                        } else { // 下一个border不一致
                            r = rr
                            shouldEndSearching = true
                            break
                        }
                    } else { // 没有找到下一个border
                        r = rr + 1
                        shouldEndSearching = true
                        break
                    }
                    
                    rr += 1
                    r = rr
                    isSameLine = true
                }
                
                if shouldEndSearching { l = iL; break }
                iL += 1
                l = iL
            }
            
            _drawBorderRects(in: context, border: border, size: size, rects: runRects)
            if !shouldEndSearching { r += 1 }
        }
        if !shouldEndSearching {
            l += 1; r = 0
        } else {
            shouldEndSearching = false
        }
    }
}

private func _drawBorderRects(in context: CGContext, border: PoTextBorder, size: CGSize, rects: [CGRect]) {
    if rects.count == 0 { return }
    
    var isShadowWork = false
    if let shadow = border.shadow {
        isShadowWork = true
        context.saveGState()
        context.setShadow(offset: shadow.offset, blur: shadow.blur, color: shadow.color.cgColor)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
    }
    
    var paths = [CGPath]()
    for var rect in rects {
        rect = rect.inset(by: border.insets)
        rect = rect.pixelRound
        let path = CGPath(roundedRect: rect, cornerWidth: border.cornerRadius, cornerHeight: border.cornerRadius, transform: nil)
        paths.append(path)
    }
    
    if let fillColor = border.fillColor {
        context.saveGState()
        context.setFillColor(fillColor.cgColor)
        for path in paths {
            context.addPath(path)
        }
        context.fillPath()
        context.restoreGState()
    }
    
    // 只有style的时候才画线，单独设置pattern不进行绘画
    if border.strokeColor != nil && (border.lineStyle.rawValue & PoTextLineStyle.styleMask.rawValue) > 0 && border.strokeWidth > 0 {
        
        //------------------------- single line -------------------------//
        context.saveGState()
        for path in paths {
            var bounds = path.boundingBoxOfPath.union(CGRect(origin: .zero, size: size))
            bounds = bounds.insetBy(dx: -2 * border.strokeWidth, dy: -2 * border.strokeWidth)
            context.addRect(bounds)
            context.addPath(path)
            context.clip(using: .evenOdd)
        }
        border.strokeColor?.setStroke()
        context.setLineWidth(border.strokeWidth)
        context.setLineCap(.butt)
        context.setLineJoin(.miter)
        
        if (border.lineStyle.rawValue & PoTextLineStyle.patternMask.rawValue) > 0 {
            _setLinePattern(in: context, style: border.lineStyle, width: border.strokeWidth, phase: 0)
        }
        
        var inset = -border.strokeWidth * 0.5
        if (border.lineStyle.rawValue & PoTextLineStyle.styleMask.rawValue) == PoTextLineStyle.thick.rawValue {
            inset *= 2
            context.setLineWidth(border.strokeWidth * 2)
        }
        var radiusDelta = -inset
        if border.cornerRadius <= 0 {
            radiusDelta = 0
        }
        context.setLineJoin(border.lineJoin)
        for var rect in rects {
            rect = rect.inset(by: border.insets)
            rect = rect.insetBy(dx: inset, dy: inset)
            let corner = border.cornerRadius + radiusDelta
            let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
            context.addPath(path)
        }
        context.strokePath()
        context.restoreGState()
        
        //------------------------- second line -------------------------//
        if (border.lineStyle.rawValue & PoTextLineStyle.styleMask.rawValue) == PoTextLineStyle.double.rawValue {
            context.saveGState()
            var inset = -border.strokeWidth * 2
            for var rect in rects {
                rect = rect.inset(by: border.insets)
                rect = rect.insetBy(dx: inset, dy: inset)
                let corner = border.cornerRadius + 2 * border.strokeWidth
                let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
                var bounds = path.boundingBoxOfPath.union(CGRect(origin: .zero, size: size))
                bounds = bounds.insetBy(dx: -2 * border.strokeWidth, dy: -2 * border.strokeWidth)
                context.addRect(bounds)
                context.addPath(path)
                context.clip(using: .evenOdd)
            }
            context.setStrokeColor(border.strokeColor!.cgColor)
            context.setLineWidth(border.strokeWidth)
            _setLinePattern(in: context, style: border.lineStyle, width: border.strokeWidth, phase: 0)
            context.setLineJoin(border.lineJoin)
            inset = -border.strokeWidth * 2.5
            radiusDelta = border.strokeWidth * 2
            if border.cornerRadius <= 0 {
                radiusDelta = 0
            }
            for var rect in rects {
                rect = rect.inset(by: border.insets)
                rect = rect.insetBy(dx: inset, dy: inset)
                let corner = border.cornerRadius + radiusDelta
                let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
                context.addPath(path)
            }
            context.strokePath()
            context.restoreGState()
        }
    }
    
    if isShadowWork {
        context.endTransparencyLayer()
        context.restoreGState()
    }
}


private func _setLinePattern(in context: CGContext, style: PoTextLineStyle, width: CGFloat, phase: CGFloat) {
    let dash: CGFloat = 12
    let dot: CGFloat = 5
    let space: CGFloat = 3
    var lengths = [CGFloat]()
    let pattern = style.rawValue & PoTextLineStyle.patternMask.rawValue
    
    if pattern == PoTextLineStyle.patternDot.rawValue {
        lengths = [width * dot, width * space]
    } else if pattern == PoTextLineStyle.patternDash.rawValue {
        lengths = [width * dash, width * space]
    } else if pattern == PoTextLineStyle.patternDashDot.rawValue {
        lengths = [width * dash, width * space, width * dot, width * space]
    } else if pattern == PoTextLineStyle.patternDashDotDot.rawValue {
        lengths = [width * dash, width * space,width * dot, width * space, width * dot, width * space]
    } else if pattern == PoTextLineStyle.patternCircleDot.rawValue {
        lengths = [width * 0, width * space]
        context.setLineCap(.round)
        context.setLineJoin(.round)
    }
    
    context.setLineDash(phase: phase, lengths: lengths)
}


private func _drawLineStyle(in context: CGContext, style: PoTextLineStyle, position: CGPoint, length: CGFloat, lineWidth: CGFloat, color: CGColor) {
    let styleBase = style.rawValue & PoTextLineStyle.styleMask.rawValue
    guard styleBase > 0 else { return }
    
    context.saveGState()
    defer { context.restoreGState() }
    
    let x1: CGFloat = position.x.pixelRound
    let x2: CGFloat = (position.x + length).pixelRound
    var y: CGFloat = 0
    let w: CGFloat = (styleBase == PoTextLineStyle.thick.rawValue) ? lineWidth * 2 : lineWidth
    
    let linePixel = w.pixelRound
    if abs(linePixel - floor(linePixel)) < 0.1 {
        let iPixel = Int(linePixel)
        if iPixel == 0 || (iPixel % 2 != 0) { // odd line pixel
            y = position.y.pixelHalf
        } else {
            y = position.y.pixelFloor
        }
    } else {
        y = position.y
    }
    
    context.setStrokeColor(color)
    context.setLineWidth(w)
    context.setLineCap(.butt)
    context.setLineJoin(.miter)
    
    // line pattern
    if (style.rawValue & PoTextLineStyle.patternMask.rawValue) > 0 {
        _setLinePattern(in: context, style: style, width: w, phase: position.x)
    }
    
    // line style
    if styleBase == PoTextLineStyle.single.rawValue {
        context.move(to: CGPoint(x: x1, y: y))
        context.addLine(to: CGPoint(x: x2, y: y))
        context.strokePath()
    } else if styleBase == PoTextLineStyle.thick.rawValue {
        context.move(to: CGPoint(x: x1, y: y))
        context.addLine(to: CGPoint(x: x2, y: y))
        context.strokePath()
    } else if styleBase == PoTextLineStyle.double.rawValue {
        context.move(to: CGPoint(x: x1, y: y - w))
        context.addLine(to: CGPoint(x: x2, y: y - w))
        context.strokePath()
        
        context.move(to: CGPoint(x: x1, y: y + w * 2))
        context.addLine(to: CGPoint(x: x2, y: y + w * 2))
        context.strokePath()
    }
}


private func _drawDecoration(in context: CGContext, layout: PoTextLayout, type: PoTextDecorationType, point: CGPoint, size: CGSize, cancel: (() -> Bool)? = nil) {
    context.saveGState()
    defer { context.restoreGState() }
    context.translateBy(x: point.x, y: point.y)
    var attrsName: NSAttributedString.Key
    if type == .underline {
        attrsName = .poUnderline
    } else {
        attrsName = .poStrikethrough
    }
    let lineCount = layout.lines.count
    for l in 0..<lineCount {
        if cancel?() == true { break }
        
        var line = layout.lines[l]
        if layout.truncatedLine != nil && layout.truncatedLine!.index == line.index { line = layout.truncatedLine! }
        let runs = CTLineGetGlyphRuns(line.ctLine)
        let runCount = CFArrayGetCount(runs)
        
        for r in 0..<runCount {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), to: CTRun.self)
            
            let runAttrs = CTRunGetAttributes(run) as! AttributesDictionary
            guard let attrs = runAttrs[attrsName] as? PoTextDecoration else { continue }
            
            let runRange = CTRunGetStringRange(run)
            let runStr = (layout.text.string as NSString).substring(with: runRange.nsRange) as NSString
            if PoTextUtilities.isLineBreakString(runStr) { continue }
            var position = CGPoint.zero
            let width = CGFloat(CTRunGetTypographicBounds(run, .zero, nil, nil, nil))
            
            var xHeight: CGFloat = 0
            var underlinePosition: CGFloat = 0
            var lineThickness: CGFloat = 0
            _getRunsMaxMetric(runs: runs, xHeight: &xHeight, underlinePosition: &underlinePosition, underlineThickness: &lineThickness)
            var runPosition: CGPoint = .zero
            CTRunGetPositions(run, CFRange(location: 0, length: 1), &runPosition)
            
            if type == .underline {
                position.y = line.position.y - underlinePosition + attrs.width
            } else {
                position.y = line.position.y - xHeight / 2
            }
            position.x = line.position.x + runPosition.x
            
            let thickness = attrs.width != 0 ? attrs.width : lineThickness
            var shadow = attrs.shadow
            if shadow != nil {
                let offsetAlterX = size.width + 0xFFFF
                var offset = shadow!.offset
                offset.width -= offsetAlterX
                repeat {
                    context.saveGState()
                    defer { context.restoreGState() }
                    
                    context.setShadow(offset: offset, blur: shadow!.blur, color: shadow?.color.cgColor)
                    context.setBlendMode(shadow!.blendMode)
                    context.translateBy(x: offsetAlterX, y: 0)
                    _drawLineStyle(in: context, style: attrs.style, position: position, length: width, lineWidth: thickness, color: attrs.color.cgColor)
                    shadow = shadow?.subShadow
                } while shadow != nil
            } else {
                _drawLineStyle(in: context, style: attrs.style, position: position, length: width, lineWidth: thickness, color: attrs.color.cgColor)
            }

        }
    }
}


private func _drawAttachment(in context: CGContext?, layout: PoTextLayout, point: CGPoint, size: CGSize, targetView: UIView?, targetLayer: CALayer?, cancel: (() -> Bool)? = nil) {
    guard let attachments = layout.attachments else { return }
    
    for (index, attachment) in attachments.enumerated() {
        if cancel?() == true { break }
        var rect = layout.attachmentRects![index]
        
        var image: UIImage? = nil
        var view: UIView? = nil
        var layer: CALayer? = nil
        if attachment.content is UIImage {
            image = attachment.content as? UIImage
        } else if attachment.content is UIView {
            view = attachment.content as? UIView
        } else if attachment.content is CALayer {
            layer = attachment.content as? CALayer
        }
        
        if image == nil && view == nil && layer == nil { continue }
        if image != nil && context == nil { continue }
        if view != nil && targetView == nil { continue }
        if layer != nil && targetLayer == nil { continue }
        
        let size = image != nil ? image!.size : view != nil ? view!.frame.size : layer!.frame.size
        rect = rect.fitWithContentMode(attachment.contentMode, in: size)
        rect = rect.pixelRound
        rect = rect.standardized
        rect.origin.x += point.x
        rect.origin.y += point.y
        
        if let cgImage = image?.cgImage {
            context!.saveGState()
            context!.translateBy(x: 0, y: rect.maxY + rect.minY)
            context!.scaleBy(x: 1, y: -1)
            context!.draw(cgImage, in: rect)
            context!.restoreGState()
        } else if let aview = view {
            aview.frame = rect
            targetView?.addSubview(aview)
        } else if let alayer = layer {
            alayer.frame = rect
            targetLayer?.addSublayer(alayer)
        }
    }
}


private func _drawShadow(in context: CGContext, layout: PoTextLayout, point: CGPoint, size: CGSize, cancel: (() -> Bool)? = nil) {
    context.saveGState()
    defer { context.restoreGState() }
    context.translateBy(x: point.x, y: point.y)
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)
    
    let offsetAlterX = size.width + 0xFFFF
    for var line in layout.lines {
        if cancel?() == true { break }
        if layout.truncatedLine != nil && layout.truncatedLine!.index == line.index { line = layout.truncatedLine! }
        
        let linePosX = line.position.x
        let linePosY = size.height - line.position.y
        let runs = CTLineGetGlyphRuns(line.ctLine)
        let runCount = CFArrayGetCount(runs)
        for r in 0..<runCount {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), to: CTRun.self)
            context.textMatrix = .identity
            context.textPosition = CGPoint(x: linePosX, y: linePosY)
            let runAttrs = CTRunGetAttributes(run) as! AttributesDictionary
            var shadow: PoTextShadow? = runAttrs[.poShadow] as? PoTextShadow
            var nsShadow: PoTextShadow? = nil
            if let oneShadow = runAttrs[.shadow] as? NSShadow {
                nsShadow = PoTextShadow(nsShadow: oneShadow)
                nsShadow?.subShadow = shadow
                shadow = nsShadow
            }
            
            while shadow != nil {
                var offset = shadow!.offset
                offset.width -= offsetAlterX
                context.saveGState()
                defer { context.restoreGState() }
                context.setShadow(offset: offset, blur: shadow!.blur, color: shadow?.color.cgColor)
                context.setBlendMode(shadow!.blendMode)
                context.translateBy(x: offsetAlterX, y: 0)
                _drawRun(in: context, line: line, run: run, size: size)
                shadow = shadow?.subShadow
            }
            
        }
    }
}

private func _drawInnerShadow(in context: CGContext, layout: PoTextLayout, point: CGPoint, size: CGSize, cancel: (() -> Bool)? = nil) {
    context.saveGState()
    defer { context.restoreGState() }
    context.translateBy(x: point.x, y: point.y)
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)
    
    for var line in layout.lines {
        if cancel?() == true { break }
        if layout.truncatedLine != nil && layout.truncatedLine!.index == line.index { line = layout.truncatedLine! }
        
        let linePosX = line.position.x
        let linePosY = size.height - line.position.y
        let runs = CTLineGetGlyphRuns(line.ctLine)
        let runCount = CFArrayGetCount(runs)
        for r in 0..<runCount {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, r), to: CTRun.self)
            if CTRunGetGlyphCount(run) == 0 { continue }
            context.textMatrix = .identity
            context.textPosition = CGPoint(x: linePosX, y: linePosY)
            let runAttrs = CTRunGetAttributes(run) as! AttributesDictionary
            var shadow = runAttrs[.poInnerShadow] as? PoTextShadow
            
            while shadow != nil {
                var runPosition: CGPoint  = .zero
                CTRunGetPositions(run, CFRange(location: 0, length: 1), &runPosition)
                var runImageBounds = CTRunGetImageBounds(run, context, CFRange.zero)
                runImageBounds.origin.x += runPosition.x
                if runImageBounds.width < 0.1 || runImageBounds.height < 0.1 { break }
                
                if runAttrs[.poGlyphTransform] != nil {
                    runImageBounds = CGRect(origin: .zero, size: size)
                }
                
                context.saveGState()
                defer { context.restoreGState() }
                context.setBlendMode(shadow!.blendMode)
                context.setShadow(offset: .zero, blur: 0, color: nil)
                context.setAlpha(shadow!.color.cgColor.alpha)
                context.clip(to: runImageBounds)
                
                do {
                    context.beginTransparencyLayer(auxiliaryInfo: nil)
                    defer { context.endTransparencyLayer() }
                    let opaqueShadowColor = shadow!.color.withAlphaComponent(1)
                    context.setShadow(offset: shadow!.offset, blur: shadow!.blur, color: opaqueShadowColor.cgColor)
                    context.setFillColor(opaqueShadowColor.cgColor)
                    context.setBlendMode(.sourceOut)
                    do {
                        context.beginTransparencyLayer(auxiliaryInfo: nil)
                        defer { context.endTransparencyLayer() }
                        context.fill(runImageBounds)
                        context.setBlendMode(.destinationIn)
                        do {
                            context.beginTransparencyLayer(auxiliaryInfo: nil)
                            defer { context.endTransparencyLayer() }
                            _drawRun(in: context, line: line, run: run, size: size)
                        }
                    }
                }
                
                shadow = shadow?.subShadow
            }
            
        }

    }
}
