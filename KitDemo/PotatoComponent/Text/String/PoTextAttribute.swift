//
//  PoTextAttribute.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/7/20.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit
/**
 The tap/long press action callback defined in PoText.
 
 @param containerView The text container view (such as Label/TextView).
 @param text          The whole text.
 @param range         The text range in `text` (if no range, the range.location is NSNotFound).
 @param rect          The text frame in `containerView` (if no data, the rect is CGRectNull).
 */
typealias PoTextAction = (_ containerView: UIView, _ text: NSAttributedString?, _ range: NSRange, _ rect: CGRect) -> Void

struct PoTextToken {
    static let attachment: String = String(UnicodeScalar(0xFFFC)!) // 空白占位符
    static let truncation: String = String(unicodeScalarLiteral: "\u{2026}") // 省略号…
}


extension NSAttributedString.Key {
    
    static let poBackedString     = NSAttributedString.Key(rawValue: "PoTextBackedString")
    static let poShadow           = NSAttributedString.Key(rawValue: "PoTextShadow")
    static let poInnerShadow      = NSAttributedString.Key(rawValue: "PoTextInnerShadow")
    static let poUnderline        = NSAttributedString.Key(rawValue: "PoTextUnderline")
    static let poStrikethrough    = NSAttributedString.Key(rawValue: "PoTextStrikethrough")
    static let poBorder           = NSAttributedString.Key(rawValue: "PoTextBorder")
    static let poBlockBorder      = NSAttributedString.Key(rawValue: "PoTextBlockBorder")
    static let poAttachment       = NSAttributedString.Key(rawValue: "PoTextAttachement")
    static let poHighlight        = NSAttributedString.Key(rawValue: "PoTextHighlight")
    static let poGlyphTransform   = NSAttributedString.Key(rawValue: "PoTextGlyphTransform")
    
    static let ctRunDelegate      = NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String)
    static let ctSuperscript      = NSAttributedString.Key(rawValue: kCTSuperscriptAttributeName as String)
    static let ctGlyphInfo        = NSAttributedString.Key(rawValue: kCTGlyphInfoAttributeName as String)
    static let ctRubyAnnotation   = NSAttributedString.Key(rawValue: kCTRubyAnnotationAttributeName as String)
    static let ctBaselineClass    = NSAttributedString.Key(rawValue: kCTBaselineClassAttributeName as String)
    static let ctBaselineInfo     = NSAttributedString.Key(rawValue: kCTBaselineInfoAttributeName as String)
    static let ctBaselineReferenceInfo   = NSAttributedString.Key(rawValue: kCTBaselineReferenceInfoAttributeName as String)
    
    static let allDiscontinuousAttributeKeys: [NSAttributedString.Key] = [.ctSuperscript, .ctRunDelegate, .poBackedString, .poAttachment, .ctRubyAnnotation, .attachment]
}



// MARK: - PoTextBinding

enum PoTextDirection {
    case none
    case top
    case left
    case bottom
    case right
}


// MARK: - PoTextLineStyle

struct PoTextLineStyle : OptionSet {
    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    // basic style (bitmask: 0xFF)
    static let styleMask: PoTextLineStyle = PoTextLineStyle(rawValue: 0xFF)
    static let single: PoTextLineStyle = PoTextLineStyle(rawValue: 0x01) //(──────)
    static let thick: PoTextLineStyle = PoTextLineStyle(rawValue: 0x02)  //(━━━━━━)
    static let double: PoTextLineStyle = PoTextLineStyle(rawValue: 0x09) //(══════)
    
    // style pattern (bitmask: 0xF00) must work with (single|double|thick) together
    static let patternMask = PoTextLineStyle(rawValue: 0xF00)
    static let patternDot = PoTextLineStyle(rawValue: 0x100)           //(‑ ‑ ‑ ‑ ‑)
    static let patternDash = PoTextLineStyle(rawValue: 0x200)          //(— — — — —)
    static let patternDashDot = PoTextLineStyle(rawValue: 0x300)       //(— ‑ — ‑ —)
    static let patternDashDotDot = PoTextLineStyle(rawValue: 0x400)    //(— ‑ ‑ — ‑)
    static let patternCircleDot = PoTextLineStyle(rawValue: 0x900)     //(•••••••••)
}


// MARK: - PoTextDecorationType

enum PoTextDecorationType {
    case underline
    case strikethrough
}


// MARK: - PoTextDecoration

/// 装饰线条的样式
final class PoTextDecoration {
    let style: PoTextLineStyle
    let width: CGFloat
    let color: UIColor
    let shadow: PoTextShadow?
    
    init(style: PoTextLineStyle = .single, width: CGFloat = 1, color: UIColor = .black, shadow: PoTextShadow? = nil) {
        self.style = style
        self.width = width
        self.color = color
        self.shadow = shadow
    }
}

// MARK: - PoTextBorder

class PoTextBorder: Equatable {
    var lineStyle: PoTextLineStyle = .single
    var strokeWidth: CGFloat = 0
    var strokeColor: UIColor?
    var lineJoin: CGLineJoin = .miter
    var insets: UIEdgeInsets = .zero
    var cornerRadius: CGFloat = 0
    var shadow: PoTextShadow?
    var fillColor: UIColor?
    
    init(lineStyle: PoTextLineStyle, lineWidth: CGFloat, strokeColor: UIColor, cornerRadius: CGFloat = 0, insets: UIEdgeInsets = .zero) {
        self.lineStyle = lineStyle
        self.strokeWidth = lineWidth
        self.strokeColor = strokeColor
        self.cornerRadius = cornerRadius
        self.insets = insets
    }
    
    init(fillColor: UIColor, cornerRadius: CGFloat = 0, insets: UIEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: -2)) {
        self.fillColor = fillColor
        self.cornerRadius = cornerRadius
        self.insets = insets
    }
    
    static func == (lhs: PoTextBorder, rhs: PoTextBorder) -> Bool {
        return lhs === rhs
    }
}

// MARK: - PoTextShadow

final class PoTextShadow {
    var color: UIColor = UIColor(white: 0, alpha: 0.333333)
    var offset: CGSize = .zero
    var blur: CGFloat = 0
    var blendMode: CGBlendMode = .normal
    var subShadow: PoTextShadow?
    
    var nsShadow: NSShadow {
        let shadow = NSShadow()
        shadow.shadowOffset = offset
        shadow.shadowBlurRadius = blur
        shadow.shadowColor = color
        return shadow
    }
    
    init(color: UIColor, offset: CGSize, blur: CGFloat) {
        self.color = color
        self.offset = offset
        self.blur = blur
    }
    
    init(nsShadow: NSShadow) {
        self.offset = nsShadow.shadowOffset
        self.blur = nsShadow.shadowBlurRadius
        if let shadowColor = nsShadow.shadowColor {
            if shadowColor is UIColor {
                self.color = (shadowColor as! UIColor)
            } else if CFGetTypeID(shadowColor as CFTypeRef) == CGColor.typeID {
                self.color = UIColor(cgColor: shadowColor as! CGColor)
            }
        }
    }
}

// MARK: - PoTextHighlight

final class PoTextHighlight: Equatable {

    private(set) var attributes: [NSAttributedString.Key: Any]!
    var userInfo: [AnyHashable: Any]?
    var tapAction: PoTextAction?
    var longPressAction: PoTextAction?
    
    var font: UIFont? {
        get { return attributes[.font] as? UIFont }
        set { setAttribute(.font, value: newValue) }
    }
    
    var foregroundColor: UIColor? {
        get { return attributes[.foregroundColor] as? UIColor }
        set { setAttribute(.foregroundColor, value: newValue) }
    }
    
    var strokeWidth: CGFloat? {
        get { return attributes[.strokeWidth] as? CGFloat }
        set { setAttribute(.strokeWidth, value: newValue) }
    }
    
    var strokeColor: UIColor? {
        get { return attributes[.strokeColor] as? UIColor }
        set { setAttribute(.strokeColor, value: newValue) }
    }
    
    var shadow: PoTextShadow? {
        get { return attributes[.poShadow] as? PoTextShadow }
        set { setAttribute(.poShadow, value: newValue) }
    }
    
    var innerShadow: PoTextShadow? {
        get { return attributes[.poInnerShadow] as? PoTextShadow }
        set { setAttribute(.poInnerShadow, value: newValue) }
    }
    
    var underline: PoTextDecoration? {
        get { return attributes[.poUnderline] as? PoTextDecoration }
        set { setAttribute(.poUnderline, value: newValue) }
    }
    
    var strikethrough: PoTextDecoration? {
        get { return attributes[.poStrikethrough] as? PoTextDecoration }
        set { setAttribute(.poStrikethrough, value: newValue) }
    }
    
    var border: PoTextBorder? {
        get { return attributes[.poBorder] as? PoTextBorder }
        set { setAttribute(.poBorder, value: newValue) }
    }
    
    var attachment: PoTextAttachment? {
        get { return attributes[.poAttachment] as? PoTextAttachment }
        set { setAttribute(.poAttachment, value: newValue) }
    }
    
    private func setAttribute(_ name: NSAttributedString.Key, value: Any?) {
        if attributes == nil { attributes = [:] }
        attributes[name] = value
    }
    
    init() {}
    
    init(attributes: [NSAttributedString.Key: Any]) {
        self.attributes = attributes
    }
    
    init(backgroundColor: UIColor) {
        let highlightBorder = PoTextBorder(fillColor: backgroundColor,
                                           cornerRadius: 3,
                                           insets: UIEdgeInsets(top: -2, left: -1, bottom: -2, right: -1))
        self.border = highlightBorder
    }
    
    static func == (lhs: PoTextHighlight, rhs: PoTextHighlight) -> Bool {
        return lhs === rhs
    }

}


// MARK: - PoTextBackedString

final class PoTextBackedString {
    let string: String?
    
    init(string: String) {
        self.string = string
    }
}

// MARK: - PoTextVerticalAlignment

enum PoTextVerticalAlignment {
    case top
    case center
    case bottom
}

