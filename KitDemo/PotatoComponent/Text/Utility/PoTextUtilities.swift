//
//  PoTextUtilities.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/8/5.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

/*
 
 Unicode 字符集
 用21位表示
 分为17(2^5)个平面，每个平面65536(2^16)
 常用的字符放在基本平面(BMP) U+0000 ~ U+FFFF
 剩下的字符放在辅助平面(SMP) U+010000 ~ U+10FFFF
 
 UTF16
 
 code units(码元)
 code point(码点)
 代理对
 U+D800 ~ U+DFFF 是一个空段
 辅助平面的字符位共有 2^20 个，因此表示这些字符至少需要 20 个二进制位。UTF-16 将这 20 个二进制位分成两半，前 10 位映射在 U+D800 到 U+DBFF，称为高位（H），后 10 位映射在 U+DC00 到 U+DFFF，称为低位（L）。这意味着，一个辅助平面的字符，被拆成两个基本平面的字符表示。
 H = Math.floor((c-0x10000) / 0x400)+0xD800
 L = (c - 0x10000) % 0x400 + 0xDC00
 
 
 UTF8
 
 0000 0000 - 0000 007F    0xxxxxxx
 0000 0080 - 0000 07FF    110xxxxx 10xxxxxx
 0000 0800 - 0000 FFFF    1110xxxx 10xxxxxx 10xxxxxx
 0001 0000 - 0010 FFFF    11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
 
 */

private let scale = UIScreen.main.scale

struct PoTextUtilities {
    
    /// 判断字体是否包含emoji
    static func ctFontContainsColorBitmapGlyphs(_ ctFont: CTFont) -> Bool {
        return (CTFontGetSymbolicTraits(ctFont).rawValue & CTFontSymbolicTraits.traitColorGlyphs.rawValue) != 0
    }
    
    /// 判断某个glyph是否emoji
    static func ctGlyphIsEmoji(ctFont: CTFont, glyph: CGGlyph) -> Bool {
        // 判断字体是否包含emoji
        if ctFontContainsColorBitmapGlyphs(ctFont) {
            // glyph是否是emoji
            if CTFontCreatePathForGlyph(ctFont, glyph, nil) == nil {
                return true
            }
        }
        return false
    }
    
    /// Whether the character is 'line break char':
    /// U+000D (\\r or CR)
    /// U+2028 (Unicode line separator)
    /// U+000A (\\n or LF)
    /// U+2029 (Unicode paragraph separator)
    /// U+0085 (Unicode next line)
    static func isLinebreakChar(unichar: unichar) -> Bool {
        switch unichar {
        case 0x000A, 0x000D, 0x2028, 0x2029, 0x0085:
            return true
        default:
            return false
        }
    }
    
    /// Whether the string contains line break char
    static func isLineBreakString(_ str: NSString) -> Bool {
        if str.length == 1 {
            let c = str.character(at: 0)
            return isLinebreakChar(unichar: c)
        } else if str.length == 2 {
            let c0 = str.character(at: 0)
            let c1 = str.character(at: 1)
            return c0 == 0x000D && c1 == 0x000A
        }
        return false
    }
    
    /// If the string has a 'line break' suffix, return the 'line break' length.
    static func lineBreakTailLength(_ str: NSString) -> Int {
        if str.length >= 2 {
            let c2 = str.character(at: str.length - 1)
            if isLinebreakChar(unichar: c2) {
                let c1 = str.character(at: str.length - 2)
                if c1 == 13 && c2 == 10 {
                    return 2
                } else {
                    return 1
                }
            } else {
                return 0
            }
        } else if str.length == 1 {
            return isLinebreakChar(unichar: str.character(at: 0)) ? 1 : 0
        } else {
            return 0
        }
    }
    
    /// Converte UIDataDetectorTypes to NSTextCheckingTypes
    static func nsTextCheckingTypes(from types: UIDataDetectorTypes) -> NSTextCheckingTypes {
        let t: NSTextCheckingResult.CheckingType = NSTextCheckingResult.CheckingType(rawValue: 0)
        if types.contains(.phoneNumber) { _ = t.union(.phoneNumber) }
        if types.contains(.link) { _ = t.union(.link) }
        if types.contains(.address) { _ = t.union(.address) }
        if types.contains(.calendarEvent) { _ = t.union(.date) }
        return t.rawValue
    }
    
    static func emojiGetAscent(with fontSize: CGFloat) -> CGFloat {
        if fontSize < 16 {
            return 1.25 * fontSize
        } else if 16 <= fontSize && fontSize <= 24 {
            return 0.5 * fontSize + 12
        } else {
            return fontSize
        }
    }
    
    static func emojiGetDescent(with fontSize: CGFloat) -> CGFloat {
        if fontSize < 16 {
            return 0.390625 * fontSize
        } else if 16 <= fontSize && fontSize <= 24 {
            return 0.15625 * fontSize + 3.75
        } else {
            return 0.3125
        }
    }
    
    static func emojiGetGlyphBoundingRect(with fontSize: CGFloat) -> CGRect {
        var rect: CGRect = .zero
        rect.origin.x = 0.75
        let ascent = emojiGetAscent(with: fontSize)
        rect.size.width = ascent
        rect.size.height = ascent
        if fontSize < 16 {
            rect.origin.y = -0.2525 * fontSize
        } else if 16 <= fontSize && fontSize <= 24 {
            rect.origin.y = 0.1225 * fontSize - 6
        } else {
            rect.origin.y = -0.1275 * fontSize
        }
        return rect
    }
    
}

// MARK: - Pixel alignment

extension CGFloat {
    
    var toPiexl: CGFloat {
        return self * scale
    }
    
    var fromPixel: CGFloat {
        return self / scale
    }
    
    var pixelFloor: CGFloat {
        return floor(self * scale) / scale
    }
    
    var pixelRound: CGFloat {
        return Darwin.round(self * scale) / scale
    }
    
    var pixelCeil: CGFloat {
        return ceil(self * scale) / scale
    }
    
    var pixelHalf: CGFloat {
        return (floor(self * scale) + 0.5) / scale
    }
    
    /// convert degrees to radians
    var toRadians: CGFloat {
        return self * .pi / 180
    }
    
    /// convert radians to degrees
    var toDegrees: CGFloat {
        return self * 180 / .pi
    }
}

extension CGPoint {
    
    var pixelFloor: CGPoint {
        return CGPoint(x: floor(self.x * scale) / scale, y: floor(self.y * scale) / scale)
    }
    
    var pixelRound: CGPoint {
        return CGPoint(x: round(self.x * scale) / scale, y: round(self.y * scale) / scale)
    }
    
    var pixelCeil: CGPoint {
        return CGPoint(x: ceil(self.x * scale) / scale, y: ceil(self.y * scale) / scale)
    }

    
    var pixelHalf: CGPoint {
        return CGPoint(x: (floor(self.x * scale) + 0.5) / scale, y: (floor(self.y * scale) + 0.5) / scale)
    }
    
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt((point.x - self.x) * (point.x - self.x) + (point.y - self.y) * (point.y - self.y))
    }
    
    func distance(to rect: CGRect) -> CGFloat {
        let rect = rect.standardized
        if rect.contains(self) { return 0 }
        var distV: CGFloat = 0
        var distH: CGFloat = 0
        if self.y < rect.minY {
            distV = rect.minY - self.y
        } else if self.y > rect.maxY {
            distV = self.y - rect.maxY
        }
        
        if self.x < rect.minX {
            distH = rect.minX - self.x
        } else if self.x > rect.maxX {
            distH = self.x - rect.maxX
        }
        
        return max(distV, distH)
    }

}

extension CGSize {
    
    var pixelFloor: CGSize {
        return CGSize(width: floor(self.width * scale) / scale, height: floor(self.height * scale) / scale)
    }
    
    var pixelRound: CGSize {
        return CGSize(width: round(self.width * scale) / scale, height: round(self.height * scale) / scale)
    }
    
    var pixelCeil: CGSize {
        return CGSize(width: ceil(self.width * scale) / scale, height: ceil(self.height * scale) / scale)
    }
    
    var pixelHalf: CGSize {
        return CGSize(width: (floor(self.width * scale) + 0.5) / scale, height: (floor(self.height * scale) + 0.5) / scale)
    }
}

extension CGRect {
    
    var pixelFloor: CGRect {
        let origin = self.origin.pixelCeil
        let corner = CGPoint(x: self.maxX, y: self.maxY).pixelFloor
        var rect = CGRect(origin: origin, size: CGSize(width: corner.x - origin.x, height: corner.y - origin.y))
        if rect.width < 0 { rect.size.width = 0 }
        if rect.height < 0 { rect.size.height = 0 }
        return rect
    }
    
    var pixelRound: CGRect {
        let origin = self.origin.pixelRound
        let corner = CGPoint(x: self.maxX, y: self.maxY).pixelRound
        return CGRect(origin: origin, size: CGSize(width: corner.x - origin.x, height: corner.y - origin.y))
    }
    
    var pixelCeil: CGRect {
        let origin = self.origin.pixelFloor
        let corner = CGPoint(x: self.maxX, y: self.maxY).pixelCeil
        return CGRect(origin: origin, size: CGSize(width: corner.x - origin.x, height: corner.y - origin.y))
    }
    
    var pixelHalf: CGRect {
        let origin = self.origin.pixelHalf
        let corner = CGPoint(x: self.maxX, y: self.maxY).pixelHalf
        return CGRect(origin: origin, size: CGSize(width: corner.x - origin.x, height: corner.y - origin.y))
    }
    
    func fitWithContentMode(_ mode: UIView.ContentMode, in size: CGSize) -> CGRect {
        var stdSize = CGSize(width: (size.width < 0 ? -size.width : size.width),
                             height: (size.height < 0 ? -size.height : size.height))
        var stdRect = self.standardized
        let center = CGPoint(x: stdRect.midX, y: stdRect.midY)
        
        switch mode {
        case .scaleAspectFit, .scaleAspectFill:
            if stdRect.width < 0.01 || stdRect.height < 0.01 || stdSize.width < 0.01 || stdSize.height < 0.01 {
                stdRect.origin = center
                stdRect.size = .zero
            } else {
                var scale: CGFloat = 0
                if mode == .scaleAspectFit {
                    if stdSize.width / stdSize.height < stdRect.width / stdRect.height {
                        scale = stdRect.height / stdSize.height
                    } else {
                        scale = stdRect.size.width / stdSize.width
                    }
                } else {
                    if stdSize.width / stdSize.height < stdRect.width / stdRect.height {
                        scale = stdRect.size.width / stdSize.width
                    } else {
                        scale = stdRect.height / stdSize.height
                    }
                }
                stdSize.width *= scale
                stdSize.height *= scale
                stdRect.size = stdSize
                stdRect.origin = CGPoint(x: center.x - stdSize.width * 0.5, y: center.y - stdSize.height * 0.5)
            }
        case .center:
            stdRect.size = stdSize
            stdRect.origin = CGPoint(x: center.x - stdSize.width * 0.5, y: center.y - stdSize.height * 0.5)
        case .top:
            stdRect.origin.x = center.x - stdSize.width * 0.5
            stdRect.size = stdSize
        case .bottom:
            stdRect.origin.x = center.x - stdSize.width * 0.5
            stdRect.origin.y += stdRect.height - stdSize.height
            stdRect.size = stdSize
        case .left:
            stdRect.origin.y = center.y - stdSize.height * 0.5
            stdRect.size = stdSize
        case .right:
            stdRect.origin.y = center.y - stdSize.height * 0.5
            stdRect.origin.x += stdRect.width - stdSize.width
            stdRect.size = stdSize
        case .topLeft:
            stdRect.size = stdSize
        case .topRight:
            stdRect.origin.x += stdRect.width - stdSize.width
            stdRect.size = stdSize
        case .bottomLeft:
            stdRect.origin.y += stdRect.height - stdSize.height
            stdRect.size = stdSize
        case .bottomRight:
            stdRect.origin.x += stdRect.width - stdSize.width
            stdRect.origin.y += stdRect.height - stdSize.height
            stdRect.size = stdSize
        case .scaleToFill, .redraw:
            break
        @unknown default:
            fatalError("UIView.ContentMode: \(mode) has not implement!")
        }
        return stdRect
    }
    
    var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    var area: CGFloat {
        if self.isNull { return 0 }
        let rect = self.standardized
        return rect.width * rect.height
    }
}

extension UIEdgeInsets {
    
    var pixelFloor: UIEdgeInsets {
        return UIEdgeInsets(top: top.pixelFloor, left: left.pixelFloor, bottom: bottom.pixelFloor, right: right.pixelFloor)
    }
    
    var pixelCeil: UIEdgeInsets {
        return UIEdgeInsets(top: top.pixelCeil, left: left.pixelCeil, bottom: bottom.pixelCeil, right: right.pixelCeil)
    }
    
    func invert() -> UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
}

extension CFRange {
    
    static let zero: CFRange = CFRange(location: 0, length: 0)
    
    var nsRange: NSRange {
        return NSRange(location: self.location, length: self.length)
    }
}
