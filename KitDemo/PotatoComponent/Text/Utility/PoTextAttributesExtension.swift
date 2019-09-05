//
//  PoTextAttributesExtension.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/22.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

extension NSAttributedString: NameSpaceCompatible {}

extension NameSpaceWrapper where Base: NSAttributedString {
    
    /* ======================================================================================================================= */
    
    var attributes: Dictionary<NSAttributedString.Key, Any>? {
        return attributes(at: 0)
    }
    
    func attributes(at index: Int) -> Dictionary<NSAttributedString.Key, Any>? {
        if base.length == 0 || index >= base.length { return nil }
        return base.attributes(at: index, effectiveRange: nil)
    }
    
    func attribute(_ attrName: NSAttributedString.Key, at index: Int) -> Any? {
        if base.length == 0 || index >= base.length { return nil }
        return base.attribute(attrName, at: index, effectiveRange: nil)
    }
    
    /* ======================================================================================================================= */
    
    // MARK: - font
    var font: UIFont? {
        return font(at: 0)
    }
    
    func font(at index: Int) -> UIFont? {
        return attribute(.font, at: index) as? UIFont
    }
    
    // MARK: - kern
    var kern: CGFloat {
        return kern(at: 0)
    }
    
    func kern(at index: Int) -> CGFloat {
        return (attribute(.kern, at: index) as? CGFloat) ?? 0
    }
    
    // MARK: - foregroundColor
    var foregroundColor: UIColor? {
        return foregroundColor(at: 0)
    }
    
    func foregroundColor(at index: Int) -> UIColor? {
        return attribute(.foregroundColor, at: index) as? UIColor
    }
    
    // MARK: - backgroundColor
    var backgroundColor: UIColor? {
        return backgroundColor(at: 0)
    }
    
    func backgroundColor(at index: Int) -> UIColor? {
        return attribute(.backgroundColor, at: index) as? UIColor
    }
    
    // MARK: - strokeWidth
    var strokeWidth: CGFloat {
        return strokeWidth(at: 0)
    }
    
    func strokeWidth(at index: Int) -> CGFloat {
        return (attribute(.strokeWidth, at: index) as? CGFloat) ?? 0
    }
    
    // MARK: - strokeColor
    var strokeColor: UIColor? {
        return strokeColor(at: 0)
    }
    
    func strokeColor(at index: Int) -> UIColor? {
        return attribute(.strokeColor, at: index) as? UIColor
    }
    
    // MARK: - shadow
    var shadow: NSShadow? {
        return shadow(at: 0)
    }
    
    func shadow(at index: Int) -> NSShadow? {
        return attribute(.shadow, at: index) as? NSShadow
    }
    
    // MARK: - strikethroughStyle
    var strikethroughStyle: NSUnderlineStyle? {
        return strikethroughStyle(at: 0)
    }
    
    func strikethroughStyle(at index: Int) -> NSUnderlineStyle? {
        if let rawValue = attribute(.strikethroughStyle, at: index) as? Int {
            return NSUnderlineStyle(rawValue: rawValue)
        }
        return nil
    }
    
    // MARK: - strikethroughColor
    var strikethroughColor: UIColor? {
        return strikethroughColor(at: 0)
    }
    
    func strikethroughColor(at index: Int) -> UIColor? {
        return attribute(.strikethroughColor, at: index) as? UIColor
    }
    
    // MARK: - underlineStyle
    var underlineStyle: NSUnderlineStyle? {
        return underlineStyle(at: 0)
    }
    
    func underlineStyle(at index: Int) -> NSUnderlineStyle? {
        if let rawValue =  attribute(.underlineStyle, at: index) as? Int {
            return NSUnderlineStyle(rawValue: rawValue)
        }
        return nil
    }
    
    // MARK: - underlineColor
    var underlineColor: UIColor? {
        return underlineColor(at: 0)
    }
    
    func underlineColor(at index: Int) -> UIColor? {
        return attribute(.underlineColor, at: index) as? UIColor
    }
    
    // MARK: - ligature
    var ligature: Int {
        return ligature(at: 0)
    }
    
    func ligature(at index: Int) -> Int {
        return (attribute(.ligature, at: index) as? Int) ?? 1
    }
    
    // MARK: - textEffect - 文字效果
    var textEffect: NSAttributedString.TextEffectStyle? {
        return textEffect(at: 0)
    }
    
    func textEffect(at index: Int) -> NSAttributedString.TextEffectStyle? {
        return attribute(.textEffect, at: index) as? NSAttributedString.TextEffectStyle
    }
    
    // MAKR: - obliqueness - 倾斜度
    var obliqueness: CGFloat {
        return obliqueness(at: 0)
    }
    
    func obliqueness(at index: Int) -> CGFloat {
        return (attribute(.obliqueness, at: index) as? CGFloat) ?? 0
    }
    
    // MARK: - expansion - 横向拉伸
    var expansion: CGFloat {
        return expansion(at: 0)
    }
    
    func expansion(at index: Int) -> CGFloat {
        return (attribute(.expansion, at: index) as? CGFloat) ?? 0
    }
    
    // MAKR: - baselineOffset
    var baselineOffset: CGFloat {
        return baselineOffset(at: 0)
    }
    
    func baselineOffset(at index: Int) -> CGFloat {
        return (attribute(.baselineOffset, at: index) as? CGFloat) ?? 0
    }
    
    // MARK: - verticalGlyphForm - ios 无效
    var verticalGlyphForm: Int {
        return verticalGlyphForm(at: 0)
    }
    
    func verticalGlyphForm(at index: Int) -> Int {
        return (attribute(.verticalGlyphForm, at: index) as? Int) ?? 0
    }
    
    // MARK: - writingDirection
    var writingDirection: [Int]? {
        return writingDirection(at: 0)
    }
    
    func writingDirection(at index: Int) -> [Int]? {
        return attribute(.writingDirection, at: index) as? [Int]
    }
    
    // MARK: - paragraphStyle
    var paragraphStyle: NSParagraphStyle? {
        return paragraphStyle(at: 0)
    }
    
    func paragraphStyle(at index: Int) -> NSParagraphStyle? {
        return attribute(.paragraphStyle, at: index) as? NSParagraphStyle
    }
    
    // MARK: - alignment
    var alignment: NSTextAlignment {
        if let style = paragraphStyle {
            return style.alignment
        }
        return NSParagraphStyle.default.alignment
    }
    
    func alignment(at index: Int) -> NSTextAlignment {
        if let style = paragraphStyle(at: index) {
            return style.alignment
        }
        return NSParagraphStyle.default.alignment
    }
    
    // MARK: - lineBreakMode
    var lineBreakMode: NSLineBreakMode {
        if let style = paragraphStyle {
            return style.lineBreakMode
        }
        return NSParagraphStyle.default.lineBreakMode
    }
    
    func lineBreakMode(at index: Int) -> NSLineBreakMode {
        if let style = paragraphStyle(at: index) {
            return style.lineBreakMode
        }
        return NSParagraphStyle.default.lineBreakMode
    }
    
    // MARK: - lineSpacing
    var lineSpacing: CGFloat {
        if let style = paragraphStyle {
            return style.lineSpacing
        }
        return NSParagraphStyle.default.lineSpacing
    }
    
    func lineSpacing(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.lineSpacing
        }
        return NSParagraphStyle.default.lineSpacing
    }
    
    // MARK: - paragraphSpacing
    var paragraphSpacing: CGFloat {
        if let style = paragraphStyle {
            return style.paragraphSpacing
        }
        return NSParagraphStyle.default.paragraphSpacing
    }
    
    func paragraphSpacing(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.paragraphSpacing
        }
        return NSParagraphStyle.default.paragraphSpacing
    }
    
    // MARK: - paragraphSpacingBefore
    var paragraphSpacingBefore: CGFloat {
        if let style = paragraphStyle {
            return style.paragraphSpacingBefore
        }
        return NSParagraphStyle.default.paragraphSpacingBefore
    }
    
    func paragraphSpacingBefore(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.paragraphSpacingBefore
        }
        return NSParagraphStyle.default.paragraphSpacingBefore
    }
    
    // MARK: - firstLineHeadIndent
    var firstLineHeadIndent: CGFloat {
        if let style = paragraphStyle {
            return style.firstLineHeadIndent
        }
        return NSParagraphStyle.default.firstLineHeadIndent
    }
    
    func firstLineHeadIndent(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.firstLineHeadIndent
        }
        return NSParagraphStyle.default.firstLineHeadIndent
    }
    
    // MARK: - headIndent
    var headIndent: CGFloat {
        if let style = paragraphStyle {
            return style.headIndent
        }
        return NSParagraphStyle.default.headIndent
    }
    
    func headIndent(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.headIndent
        }
        return NSParagraphStyle.default.headIndent
    }
    
    // MARK: - tailIndent
    var tailIndent: CGFloat {
        if let style = paragraphStyle {
            return style.tailIndent
        }
        return NSParagraphStyle.default.tailIndent
    }
    
    func tailIndent(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.tailIndent
        }
        return NSParagraphStyle.default.tailIndent
    }
    
    // MARK: - minimumLineHeight
    var minimumLineHeight: CGFloat {
        if let style = paragraphStyle {
            return style.minimumLineHeight
        }
        return NSParagraphStyle.default.minimumLineHeight
    }
    
    func minimumLineHeight(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.minimumLineHeight
        }
        return NSParagraphStyle.default.minimumLineHeight
    }
    
    // MARK: - maximumLineHeight
    var maximumLineHeight: CGFloat {
        if let style = paragraphStyle {
            return style.maximumLineHeight
        }
        return NSParagraphStyle.default.maximumLineHeight
    }
    
    func maximumLineHeight(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.maximumLineHeight
        }
        return NSParagraphStyle.default.maximumLineHeight
    }
    
    // MARK: - lineHeightMultiple
    var lineHeightMultiple: CGFloat {
        if let style = paragraphStyle {
            return style.lineHeightMultiple
        }
        return NSParagraphStyle.default.lineHeightMultiple
    }
    
    func lineHeightMultiple(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.lineHeightMultiple
        }
        return NSParagraphStyle.default.lineHeightMultiple
    }
    
    // MARK: - baseWritingDirection
    var baseWritingDirection: NSWritingDirection {
        if let style = paragraphStyle {
            return style.baseWritingDirection
        }
        return NSParagraphStyle.default.baseWritingDirection
    }
    
    func baseWritingDirection(at index: Int) -> NSWritingDirection {
        if let style = paragraphStyle(at: index) {
            return style.baseWritingDirection
        }
        return NSParagraphStyle.default.baseWritingDirection
    }
    
    // MARK: - hyphenationFactor
    var hyphenationFactor: Float { // 断字 - ct没有
        if let style = paragraphStyle {
            return style.hyphenationFactor
        }
        return NSParagraphStyle.default.hyphenationFactor
    }
    
    func hyphenationFactor(at index: Int) -> Float {
        if let style = paragraphStyle(at: index) {
            return style.hyphenationFactor
        }
        return NSParagraphStyle.default.hyphenationFactor
    }
    
    // MARK: - defaultTabInterval
    var defaultTabInterval: CGFloat {
        if let style = paragraphStyle {
            return style.defaultTabInterval
        }
        return NSParagraphStyle.default.defaultTabInterval
    }
    
    func defaultTabInterval(at index: Int) -> CGFloat {
        if let style = paragraphStyle(at: index) {
            return style.defaultTabInterval
        }
        return NSParagraphStyle.default.defaultTabInterval
    }
    
    // MARK: - tabStops
    var tabStops: [NSTextTab] {
        if let style = paragraphStyle {
            return style.tabStops
        }
        return NSParagraphStyle.default.tabStops
    }
    
    func tabStops(at index: Int) -> [NSTextTab] {
        if let style = paragraphStyle(at: index) {
            return style.tabStops
        }
        return NSParagraphStyle.default.tabStops
    }
    
    // MARK: - textShadow
    var textShadow: PoTextShadow? {
        return textShadow(at: 0)
    }
    
    func textShadow(at index: Int) -> PoTextShadow? {
        return attribute(.poShadow, at: index) as? PoTextShadow
    }
    
    // MARK: - textInnerShadow
    var textInnerShadow: PoTextShadow? {
        return textShadow(at: 0)
    }
    
    func textInnerShadow(at index: Int) -> PoTextShadow? {
        return attribute(.poInnerShadow, at: index) as? PoTextShadow
    }
    
    // MARK: - textHighlight
    var textHighlight: PoTextHighlight? {
        return textHighlight(at: 0)
    }
    
    func textHighlight(at index: Int) -> PoTextHighlight? {
        return attribute(.poHighlight, at: index) as? PoTextHighlight
    }
    
    // MARK: - textUnderline
    var textUnderline: PoTextDecoration? {
        return textUnderline(at: 0)
    }
    
    func textUnderline(at index: Int) -> PoTextDecoration? {
        return attribute(.poUnderline, at: index) as? PoTextDecoration
    }
    
    // MARK: - textStrikethrough
    var textStrikethrough: PoTextDecoration? {
        return textStrikethrough(at: 0)
    }
    
    func textStrikethrough(at index: Int) -> PoTextDecoration? {
        return attribute(.poStrikethrough, at: index) as? PoTextDecoration
    }
    
    // MARK: - textBorder
    var textBorder: PoTextBorder? {
        return textBorder(at: 0)
    }
    
    func textBorder(at index: Int) -> PoTextBorder? {
        return attribute(.poBorder, at: index) as? PoTextBorder
    }
    
    // MARK: - textBlockBorder
    var textBlockBorder: PoTextBorder? {
        return textBlockBorder(at: 0)
    }
    
    func textBlockBorder(at index: Int) -> PoTextBorder? {
        return attribute(.poBlockBorder, at: index) as? PoTextBorder
    }
    
    // MARK: - textGlyphTransform
    var textGlyphTransform: CGAffineTransform {
        return textGlyphTransform(at: 0)
    }
    
    func textGlyphTransform(at index: Int) -> CGAffineTransform {
        if let transform = attribute(.poGlyphTransform, at: index) as? CGAffineTransform {
            return transform
        }
        return CGAffineTransform.identity
    }
    
    // MARK: - Help methods
    
    func plainText(for range: NSRange) -> String? {
        if range.location == NSNotFound || range.length == NSNotFound { return nil }
        var result = ""
        if range.length == 0 { return result }
        
        let string = (base.string as NSString)
        base.enumerateAttribute(.poBackedString, in: range, options: []) { (value, range, _) in
            if let backed = value as? PoTextBackedString, let str = backed.string {
                result.append(str)
            } else {
                result.append(string.substring(with: range))
            }
        }
        return result
    }
    
    func isSharedAttributesInAllRange() -> Bool {
        var isShared = true
        var firstAttrs: [NSAttributedString.Key: Any] = [:]
        base.enumerateAttributes(in: NSRange(location: 0, length: base.length),
                                 options: .longestEffectiveRangeNotRequired,
                                 using: { (attrs, range, stop) in
                                    if range.location == 0 {
                                        firstAttrs = attrs
                                    } else {
                                        if firstAttrs.count != attrs.count {
                                            isShared = false
                                            stop.pointee = true
                                        }
                                    }
        })
        return isShared
    }
    
}

extension NameSpaceWrapper where Base: NSMutableAttributedString {
    
    /* ======================================================================================================================= */
    
    func configure(_ make: (NameSpaceWrapper) -> Void) {
        make(self)
    }
    
    func setAttribute(_ attrName: NSAttributedString.Key, value: Any?) {
        setAttribute(attrName, value: value, range: NSRange(location: 0, length: base.length))
    }
    
    func setAttribute(_ attrName: NSAttributedString.Key, value: Any?, range: NSRange) {
        if let value = value {
            base.addAttribute(attrName, value: value, range: range)
        } else {
            base.removeAttribute(attrName, range: range)
        }
    }
    
    func setAttributes(_ attrs: Dictionary<NSAttributedString.Key, Any>) {
        // 此方法会删除之前所有的attrs，然后add新的
        base.setAttributes(attrs, range: NSRange(location: 0, length: base.length))
    }
    
    func removeAttributes(in range: NSRange)  {
        base.setAttributes(nil, range: range)
    }
    
    /* ======================================================================================================================= */
    
    // MARK: - font
    var font: UIFont? {
        get { return font(at: 0) }
        nonmutating set { setFont(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 字体
    func setFont(_ font: UIFont?, range: NSRange) {
        setAttribute(.font, value: font, range: range)
    }
    
    // MARK: - kern
    var kern: CGFloat? {
        get { return kern(at: 0) }
        nonmutating set { setKern(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 文字间隔(负数缩紧，正数散开)
    func setKern(_ kern: CGFloat?, range: NSRange) {
        setAttribute(.kern, value: kern, range: range)
    }

    //MARK: - foregroundColor
    var foregroundColor: UIColor? {
        get { return foregroundColor(at: 0) }
        nonmutating set { setForegroundColor(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 文字颜色
    func setForegroundColor(_ color: UIColor?, range: NSRange) {
        setAttribute(.foregroundColor, value: color, range: range)
    }

    // MARK: - backgroundColor
    @available(*, deprecated, message:"PoLabel不支持, 请使用textBorder替代")
    var backgroundColor: UIColor? {
        get { return backgroundColor(at: 0) }
        nonmutating set { setBackgroundColor(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 背景颜色
    @available(*, deprecated, message:"PoLabel不支持, 请使用textBorder替代")
    func setBackgroundColor(_ color: UIColor?, range: NSRange) {
        setAttribute(.backgroundColor, value: color, range: range)
    }

    // MARK: - strokeWidth
    var strokeWidth: CGFloat? {
        get { return strokeWidth(at: 0) }
        nonmutating set { setStrokeWidth(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 文字的外面的线宽 (正数会变成空心字，负数会加宽文字的线条)
    func setStrokeWidth(_ width: CGFloat?, range: NSRange) {
        setAttribute(.strokeWidth, value: width, range: range)
    }

    // MARK: - strokeColor
    var strokeColor: UIColor? {
        get { return strokeColor(at: 0) }
        nonmutating set { setStrokeColor(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    // 文字颜色，与strokeWidth一同设置才生效
    func setStrokeColor(_ color: UIColor?, range: NSRange) {
        setAttribute(.strokeColor, value: color, range: range)
    }

    // MARK: - shadow
    var shadow: NSShadow? {
        get { return shadow(at: 0) }
        nonmutating set { setShadow(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 文字阴影
    func setShadow(_ shadow: NSShadow?, range: NSRange) {
        setAttribute(.shadow, value: shadow, range: range)
    }

    // MARK: - strikethroughStyle 
    @available(*, deprecated, message:"PoLabel不支持, 请使用textStrikethrough替代")
    var strikethroughStyle: NSUnderlineStyle? {
        get { return strikethroughStyle(at: 0) }
        nonmutating set { setStrikethroughStyle(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 删除线(线条从文字中间水平贯穿)
    @available(*, deprecated, message:"PoLabel不支持, 请使用textStrikethrough替代")
    func setStrikethroughStyle(_ style: NSUnderlineStyle?, range: NSRange) {
        setAttribute(.strikethroughStyle, value: style?.rawValue, range: range)
    }

    // MARK: - strikethroughColor
    @available(*, deprecated, message:"PoLabel不支持, 请使用textStrikethrough替代")
    var strikethroughColor: UIColor? {
        get { return strikethroughColor(at: 0) }
        nonmutating set { setStrikethroughColor(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 删除线的颜色
    @available(*, deprecated, message:"PoLabel不支持, 请使用textStrikethrough替代")
    func setStrikethroughColor(_ color: UIColor?, range: NSRange) {
        setAttribute(.strikethroughColor, value: color, range: range)
    }

    // MARK: - underlineStyle
    var underlineStyle: NSUnderlineStyle? {
        get { return underlineStyle(at: 0) }
        nonmutating set { setUnderlineStyle(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 下划线
    func setUnderlineStyle(_ style: NSUnderlineStyle?, range: NSRange) {
        setAttribute(.underlineStyle, value: style?.rawValue, range: range)
    }

    // MARK: - underlineColor
    var underlineColor: UIColor? {
        get { return underlineColor(at: 0) }
        nonmutating set { setUnderlineColor(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 下划线的颜色
    func setUnderlineColor(_ color: UIColor?, range: NSRange) {
        setAttribute(.underlineColor, value: color, range: range)
    }
    
    // MARK: - ligature
    var ligature: Int? {
        get { return ligature(at: 0) }
        nonmutating set { setLigature(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 连体字符，0:不生效，1:使用默认的连体字符。(只有某些字体才支持)
    func setLigature(_ ligature: Int?, range: NSRange) {
        setAttribute(.ligature, value: ligature, range: range)
    }

    // MARK: - textEffect
    @available(*, deprecated, message:"PoLabel不支持")
    var textEffect: NSAttributedString.TextEffectStyle? {
        get { return textEffect(at: 0) }
        nonmutating set { setTextEffect(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 凸版印刷效果, NSAttributedString.TextEffectStyle.letterpressStyle
    @available(*, deprecated, message:"PoLabel不支持")
    func setTextEffect(_ textEffect: NSAttributedString.TextEffectStyle?, range: NSRange) {
        setAttribute(.textEffect, value: textEffect, range: range)
    }

    // MARK: - obliqueness
    @available(*, deprecated, message:"PoLabel不支持")
    var obliqueness: CGFloat? {
        get { return obliqueness(at: 0) }
        nonmutating set { setObliqueness(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 文字倾斜(正数：右倾斜，负数：左倾斜)
    @available(*, deprecated, message:"PoLabel不支持")
    func setObliqueness(_ obliqueness: CGFloat?, range: NSRange) {
        setAttribute(.obliqueness, value: obliqueness, range: range)
    }

    // MARK: - expansion
    @available(*, deprecated, message:"PoLabel不支持")
    var expansion: CGFloat? {
        get { return expansion(at: 0) }
        nonmutating set { setExpansion(expansion: newValue, range: NSRange(location: 0, length: base.length)) }
    }

    /// 字体的横向拉伸(正数：拉伸，负数：压缩)
    @available(*, deprecated, message:"PoLabel不支持")
    func setExpansion( expansion: CGFloat?, range: NSRange) {
        setAttribute(.expansion, value: expansion, range: range)
    }

    // MARK: - baselineOffset
    var baselineOffset: CGFloat? {
        get { return baselineOffset(at: 0) }
        nonmutating set { setBaselineOffset(newValue, range: NSRange(location: 0, length: base.length)) }
    }

    /// 基线偏移量(正数:向上偏移，负数:向下偏移)
    func setBaselineOffset(_ offset: CGFloat?, range: NSRange) {
        setAttribute(.baselineOffset, value: offset, range: range)
    }

    // MARK: - verticalGlyphForm - ios 无效
    @available(*, deprecated, message:"PoLabel不支持")
    var verticalGlyphForm: Int? {
        get { return verticalGlyphForm(at: 0) }
        nonmutating set { setVerticalGlyphForm(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 设置文字排版方向，0表示横排文本，1表示竖排文本 在iOS中只支持0
    @available(*, deprecated, message:"PoLabel不支持")
    func setVerticalGlyphForm(_ form: Int?, range: NSRange) {
        setAttribute(.verticalGlyphForm, value: form, range: range)
    }

    // MARK: - writingDirection
    var writingDirection: [Int]? {
        get { return writingDirection(at: 0) }
        nonmutating set { setWritingDirection(newValue, range: NSRange(location: 0, length: base.length)) }
    }

    /// 文字书写方向
    func setWritingDirection(_ direction: [Int]?, range: NSRange) {
        setAttribute(.writingDirection, value: direction, range: range)
    }

    // MARK: - paragraphStyle
    var paragraphStyle: NSParagraphStyle? {
        get { return paragraphStyle(at: 0) }
        nonmutating set { setParagraphStyle(newValue, range: NSRange(location: 0, length: base.length)) }
    }

    /// 段落样式
    func setParagraphStyle(_ style: NSParagraphStyle?, range: NSRange) {
        setAttribute(.paragraphStyle, value: style, range: range)
    }

    // MARK: - alignment
    var alignment: NSTextAlignment {
        get { return alignment(at: 0) }
        nonmutating set { setAlignment(newValue, range: NSRange(location: 0, length: base.length)) }
    }

    /// 文字对齐方向
    func setAlignment(_ alignment: NSTextAlignment, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.alignment == alignment { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.alignment == alignment { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.alignment = alignment
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - baseWritingDirection
    var baseWritingDirection: NSWritingDirection {
        get { return baseWritingDirection(at: 0) }
        nonmutating set { setBaseWritingDirection(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 文字书写方向(与alignment效果类似)
    func setBaseWritingDirection(_ direction: NSWritingDirection, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.baseWritingDirection == direction { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.baseWritingDirection == direction { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.baseWritingDirection = direction
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - lineSpacing
    var lineSpacing: CGFloat {
        get { return lineSpacing(at: 0) }
        nonmutating set { setLineSpacing(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 行间距
    func setLineSpacing(_ spacing: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.lineSpacing == spacing { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.lineSpacing == spacing { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.lineSpacing = spacing
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - paragraphSpacing
    var paragraphSpacing: CGFloat {
        get { return paragraphSpacing(at: 0) }
        nonmutating set { setParagraphSpacing(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 本段的尾部与下一段头部的距离(文章以\r or \n or \r\n分割段落)(好像与paragraphSpacingBefore没什么区别)
    func setParagraphSpacing(_ spacing: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.paragraphSpacing == spacing { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.paragraphSpacing == spacing { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.paragraphSpacing = spacing
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - paragraphSpacingBefore
    var paragraphSpacingBefore: CGFloat {
        get { return paragraphSpacingBefore(at: 0) }
        nonmutating set { setParagraphSpacingBefore(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 本段的头部与上一段尾部的距离(好像与paragraphSpacing没什么区别)
    func setParagraphSpacingBefore(_ spacing: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.paragraphSpacingBefore == spacing { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.paragraphSpacingBefore == spacing { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.paragraphSpacingBefore = spacing
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - firstLineHeadIndent
    var firstLineHeadIndent: CGFloat {
        get { return firstLineHeadIndent(at: 0) }
        nonmutating set { setFirstLineHeadIndent(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 每个段落第一行的缩进
    func setFirstLineHeadIndent(_ indent: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.firstLineHeadIndent == indent { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.firstLineHeadIndent == indent { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.firstLineHeadIndent = indent
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - headIndent
    var headIndent: CGFloat {
        get { return headIndent(at: 0) }
        nonmutating set { setHeadIndent(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 首行除外的整体缩进(正数向右边缩进，s负数向左边缩进)
    func setHeadIndent(_ indent: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.headIndent == indent { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.headIndent == indent { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.headIndent = indent
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - tailIndent
    var tailIndent: CGFloat {
        get { return tailIndent(at: 0) }
        nonmutating set { setTailIndent(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 尾部缩进(负数向左边缩进，正数表示文字整体的宽度)
    func setTailIndent(_ indent: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.tailIndent == indent { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.tailIndent == indent { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.tailIndent = indent
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - lineBreakMode
    var lineBreakMode: NSLineBreakMode {
        get { return lineBreakMode(at: 0) }
        nonmutating set { setLineBreakMode(newValue, range: NSRange(location: 0, length: base.length)) }
    }

    /// 文字截断模式
    func setLineBreakMode(_ mode: NSLineBreakMode, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.lineBreakMode == mode { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.lineBreakMode == mode { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.lineBreakMode = mode
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - minimumLineHeight
    var minimumLineHeight: CGFloat {
        get { return minimumLineHeight(at: 0) }
        nonmutating set { setMinimumLineHeight(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 最小行高
    func setMinimumLineHeight(_ height: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.minimumLineHeight == height { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.minimumLineHeight == height { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.minimumLineHeight = height
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - maximumLineHeight
    var maximumLineHeight: CGFloat {
        get { return maximumLineHeight(at: 0) }
        nonmutating set { setMaximumLineHeight(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 最大行高
    func setMaximumLineHeight(_ height: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.maximumLineHeight == height { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.maximumLineHeight == height { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.maximumLineHeight = height
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - lineHeightMultiple
    var lineHeightMultiple: CGFloat {
        get { return lineHeightMultiple(at: 0) }
        nonmutating set { setLineHeightMultiple(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    /// 行高相乘系数
    func setLineHeightMultiple(_ multiple: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.lineHeightMultiple == multiple { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.lineHeightMultiple == multiple { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.lineHeightMultiple = multiple
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - hyphenationFactor
    var hyphenationFactor: Float {
        get { return hyphenationFactor(at: 0) }
        nonmutating set { setHyphenationFactor(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    func setHyphenationFactor(_ factor: Float, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.hyphenationFactor == factor { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.hyphenationFactor == factor { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.hyphenationFactor = factor
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - defaultTabInterval
    var defaultTabInterval: CGFloat {
        get { return defaultTabInterval(at: 0) }
        nonmutating set { setDefaultTabInterval(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    func setDefaultTabInterval(_ interval: CGFloat, range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.defaultTabInterval == interval { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.defaultTabInterval == interval { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.defaultTabInterval = interval
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - tabStops
    var tabStops: [NSTextTab] {
        get { return tabStops(at: 0) }
        nonmutating set { setTabStops(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    func setTabStops(_ tabStops: [NSTextTab], range: NSRange) {
        base.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, subRange, _) in
            var paragraphStyle: NSMutableParagraphStyle?
            if let style = value as? NSParagraphStyle {
                if style.tabStops == tabStops { return }
                if style is NSMutableParagraphStyle {
                    paragraphStyle = style as? NSMutableParagraphStyle
                } else {
                    paragraphStyle = style.mutableCopy() as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.tabStops == tabStops { return }
                paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            paragraphStyle?.tabStops = tabStops
            setParagraphStyle(paragraphStyle, range: subRange)
        }
    }

    // MARK: - superscript
    /// 1: 上标、0: 无作用、 -1:下标
    func setSuperscript(_ superscript: Int, range: NSRange) {
        if superscript == 0 { return }
        setAttribute(.ctSuperscript, value: superscript, range: range)
    }

    // MARK: - glyphInfo
    func setGlyphInfo(_ glyphInfo: CTGlyphInfo, range: NSRange) {
        setAttribute(.ctGlyphInfo, value: glyphInfo, range: range)
    }

    // MARK: - baselineClass
    func setBaselineClass(_ baselineClass: CFString, range: NSRange) {
        setAttribute(.ctBaselineClass, value: baselineClass)
    }
    
    // MARK: - baselineInfo
    func setBaselineInfo(_ baselineInfo: CFDictionary, range: NSRange) {
        setAttribute(.ctBaselineInfo, value: baselineInfo)
    }
    
    // MARK: - baselineReferenceInfo
    func setBaselineReferenceInfo(_ baselineReferenceInfo: CFDictionary, range: NSRange) {
        setAttribute(.ctBaselineReferenceInfo, value: baselineReferenceInfo)
    }

    // MARK: - runDelegate
    func setRunDelegate(_ delegate: CTRunDelegate?, range: NSRange) {
        setAttribute(.ctRunDelegate, value: delegate, range: range)
    }

    // MARK: - attachment
    func setAttachment(_ attachment: NSTextAttachment, range: NSRange) {
        setAttribute(.attachment, value: attachment, range: range)
    }

    // MARK: - link
    func setLink(_ link: Any?, range: NSRange) {
        setAttribute(.link, value: link, range: range)
    }

    /**************************************** custom ****************************************/

    // MARK: - textBackedString
    func setTextBackedString(_ backedString: PoTextBackedString?, range: NSRange) {
        setAttribute(.poBackedString, value: backedString, range: range)
    }

    // MARK: - textShadow
    var textShadow: PoTextShadow? {
        get { return textShadow(at: 0) }
        nonmutating set { setTextShadow(newValue, range:  NSRange(location: 0, length: base.length)) }
    }
    
    func setTextShadow(_ shadow: PoTextShadow?, range: NSRange) {
        setAttribute(.poShadow, value: shadow, range: range)
    }

    // MARK: - textInnerShadow
    var textInnerShadow: PoTextShadow? {
        get { return textInnerShadow(at: 0) }
        nonmutating set { setTextInnerShadow(newValue, range:  NSRange(location: 0, length: base.length)) }
    }

    func setTextInnerShadow(_ shadow: PoTextShadow?, range: NSRange) {
        setAttribute(.poInnerShadow, value: shadow, range: range)
    }

    // MARK: - textUnderline
    var textUnderline: PoTextDecoration? {
        get { return textUnderline(at: 0) }
        nonmutating set { setTextUnderline(newValue, range: NSRange(location: 0, length: base.length)) }
    }

    func setTextUnderline(_ decoration: PoTextDecoration?, range: NSRange) {
        setAttribute(.poUnderline, value: decoration, range: range)
    }

    // MARK: - textStrikethrough
    var textStrikethrough: PoTextDecoration? {
        get { return textStrikethrough(at: 0) }
        nonmutating set { setTextStrikethrough(newValue, range: NSRange(location: 0, length: base.length)) }
    }

    func setTextStrikethrough(_ decoration: PoTextDecoration?, range: NSRange) {
        setAttribute(.poStrikethrough, value: decoration, range: range)
    }

    // MARK: - textBorder
    var textBorder: PoTextBorder? {
        get { return textBorder(at: 0) }
        nonmutating set { setTextBorder(newValue, range:  NSRange(location: 0, length: base.length)) }
    }

    func setTextBorder(_ border: PoTextBorder?, range: NSRange) {
        setAttribute(.poBorder, value: border, range: range)
    }

    // MARK: - textBlockBorder
    var textBlockBorder: PoTextBorder? {
        get { return textBlockBorder(at: 0) }
        nonmutating set { setTextBlockBorder(newValue, range:  NSRange(location: 0, length: base.length)) }
    }

    func setTextBlockBorder(_ border: PoTextBorder?, range: NSRange) {
        setAttribute(.poBlockBorder, value: border, range: range)
    }

    // MARK: - textAttachment
    func setTextAttachment(_ attachment: PoTextAttachment?, range: NSRange) {
        setAttribute(.poAttachment, value: attachment, range: range)
    }

    // MARK: - textHighlight
    var textHighlight: PoTextHighlight? {
        get { return textHighlight(at: 0) }
        nonmutating set { setTextHighlight(newValue, range: NSRange(location: 0, length: base.length)) }
    }
    
    func setTextHighlight(_ highlight: PoTextHighlight?, range: NSRange) {
        setAttribute(.poHighlight, value: highlight, range: range)
    }

    // MARK: - textRubyAnnotation
    func setTextRubyAnnotation(_ ruby: PoTextRubyAnnotation?, range: NSRange) {
        setAttribute(.ctRubyAnnotation, value: ruby?.ctRubyAnnotation, range: range)
    }

    // MARK: - textGlyphTransform
    var textGlyphTransform: CGAffineTransform {
        get { return textGlyphTransform(at: 0) }
        nonmutating set {
            if newValue.isIdentity {
                setAttribute(.poGlyphTransform, value: nil, range: NSRange(location: 0, length: base.length))
            } else {
                setAttribute(.poGlyphTransform, value: newValue, range: NSRange(location: 0, length: base.length))
            }
        }
    }

    func setTextGlyphTransform(_ transform: CGAffineTransform, range: NSRange) {
        if transform.isIdentity {
            setAttribute(.poGlyphTransform, value: nil, range: range)
        } else {
            setAttribute(.poGlyphTransform, value: transform, range: range)
        }
    }

    // MARK: - highlight
    func setTextHighlight(in range: NSRange, backgroundColor: UIColor, color: UIColor? = nil, userInfo: [AnyHashable: Any]? = nil, tapAction: PoTextAction? = nil, longPressAction: PoTextAction? = nil) {
        let highlight = PoTextHighlight(backgroundColor: backgroundColor)
        highlight.userInfo = userInfo
        highlight.tapAction = tapAction
        highlight.longPressAction = longPressAction
        if let color = color { setForegroundColor(color, range: range) }
        setTextHighlight(highlight, range: range)
    }

    // MARK: - Helper Methods
    func insert(_ string: String, at index: Int) {
        base.replaceCharacters(in: NSRange(location: index, length: 0), with: string)
        removeDiscontinuousAttributes(in: NSRange(location: index, length: string.utf16.count))
    }

    func append(_ content: String) {
        let length = base.length
        base.replaceCharacters(in: NSRange(location: length, length: 0), with: content)
        removeDiscontinuousAttributes(in: NSRange(location: length, length: content.utf16.count))
    }

    func removeDiscontinuousAttributes(in range: NSRange) {
        for key in NSAttributedString.Key.allDiscontinuousAttributeKeys {
            base.removeAttribute(key, range: range)
        }
    }
    
    static func attachmentStringWithContent(_ content: NSObject, contentMode: UIView.ContentMode, width: CGFloat, ascent: CGFloat, descent: CGFloat) -> NSMutableAttributedString {
        let atr = NSMutableAttributedString(string: PoTextToken.attachment)
        let attach = PoTextAttachment(content: content, contentMode: contentMode)
        atr.po.setTextAttachment(attach, range: NSRange(location: 0, length: atr.length))
        
        let delegate = PoTextRunDelegate(width: width, ascent: ascent, descent: descent)
        let ctRunDelegate = delegate.ctRunDelegate
        atr.po.setRunDelegate(ctRunDelegate, range: NSRange(location: 0, length: atr.length))
        return atr
    }
    
    static func attachmentStringWithContent(_ content: NSObject, contentMode: UIView.ContentMode, size: CGSize, alignToFont font: UIFont, alignment: PoTextVerticalAlignment) -> NSMutableAttributedString {
        let atr = NSMutableAttributedString(string: PoTextToken.attachment)
        let attach = PoTextAttachment(content: content, contentMode: contentMode)
        atr.po.setTextAttachment(attach, range: NSRange(location: 0, length: atr.length))
        
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        switch alignment {
        case .top:
            ascent = font.ascender
            descent = size.height - ascent
            if descent < 0 {
                descent = 0
                ascent = size.height
            }
        case .center:
            let fontHeight = font.ascender - font.descender
            let yOffset = font.ascender - fontHeight * 0.5
            ascent = size.height * 0.5 + yOffset
            descent = size.height - ascent
            if descent < 0 {
                descent = 0
                ascent = size.height
            }
        case .bottom:
            ascent = size.height + font.descender
            descent = -font.descender
            if ascent < 0 {
                ascent = 0
                descent = size.height
            }
        }
        
        let delegate = PoTextRunDelegate(width: size.width, ascent: ascent, descent: descent)
        let ctRunDelegate = delegate.ctRunDelegate
        atr.po.setRunDelegate(ctRunDelegate, range: NSRange(location: 0, length: atr.length))
        return atr
    }
    
    static func attachmentStringWithEmojiImage(_ image: UIImage, fontSize: CGFloat) -> NSMutableAttributedString? {
        if fontSize <= 0 { return nil }
        let ascent = PoTextUtilities.emojiGetAscent(with: fontSize)
        let descent = PoTextUtilities.emojiGetDescent(with: fontSize)
        let bounding = PoTextUtilities.emojiGetGlyphBoundingRect(with: fontSize)
        
        let delegate = PoTextRunDelegate(width: bounding.width + 2 * bounding.minX, ascent: ascent, descent: descent)
        
        let attachmentInsets = UIEdgeInsets(top: ascent - (bounding.height + bounding.minY),
                                            left: bounding.minX,
                                            bottom: descent + bounding.minY,
                                            right: bounding.minX)
        let attachment = PoTextAttachment(content: image, contentMode: .scaleAspectFit, contentInsets: attachmentInsets)
        
        let atr = NSMutableAttributedString(string: PoTextToken.attachment)
        atr.po.setTextAttachment(attachment, range: NSRange(location: 0, length: atr.length))
        atr.po.setRunDelegate(delegate.ctRunDelegate, range: NSRange(location: 0, length: atr.length))
        return atr
    }
    
}

