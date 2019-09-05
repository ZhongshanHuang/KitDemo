//
//  PoLabel.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/9/4.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

/*
 Tips:
 
 1. If you only need a UILabel alternative to display rich text and receive link touch event,
 you do not need to adjust the display mode properties.
 
 2. If you have performance issues, you may enable the asynchronous display mode
 by setting the `displaysAsynchronously` to YES.
 
 3. If you want to get the highest performance, you should do text layout with
 `YYTextLayout` class in background thread. Here's an example:
 
 YYLabel *label = [YYLabel new];
 label.displaysAsynchronously = YES;
 label.ignoreCommonProperties = YES;
 
 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 
 // Create attributed string.
 NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@"Some Text"];
 text.font = [UIFont systemFontOfSize:16];
 text.color = [UIColor grayColor];
 [text setColor:[UIColor redColor] range:NSMakeRange(0, 4)];
 
 // Create text container
 YYTextContainer *container = [YYTextContainer new];
 container.size = CGSizeMake(100, CGFLOAT_MAX);
 container.maximumNumberOfRows = 0;
 
 // Generate a text layout.
 YYTextLayout *layout = [YYTextLayout layoutWithContainer:container text:text];
 
 dispatch_async(dispatch_get_main_queue(), ^{
 label.size = layout.textBoundingSize;
 label.textLayout = layout;
 });
 });
 
 */


class PoLabel: UIView {
    
    // MARK: - Properties - [public]
    
    /// The text displayed by the label.
    /// Set a new value to this property also replaces the text in 'attributedText'.
    /// get the value returns the plain text in 'attributedText'

    var text: String? {
        get { return _innerText.isEmpty ? nil : _innerText.string }
        set {
            if _innerText.string == newValue { return }
            let isNeededAddAttributes = _innerText.isEmpty && !newValue.isEmpty
            _innerText.replaceCharacters(in: _innerText.allRange, with: newValue ?? "")
            _innerText.po.removeDiscontinuousAttributes(in: _innerText.allRange)
            if isNeededAddAttributes {
                _innerText.po.configure { (make) in
                    make.font = _font
                    make.foregroundColor = _textColor
                    make.shadow = _shadowFromProperties()
                    make.alignment = _textAlignment
                }
                switch lineBreakMode {
                case .byWordWrapping, .byCharWrapping, .byClipping:
                    _innerText.po.lineBreakMode = _lineBreakMode
                case .byTruncatingHead, .byTruncatingTail, .byTruncatingMiddle:
                    _innerText.po.lineBreakMode = .byWordWrapping
                @unknown default:
                    fatalError("NSLineBreakMode: \(lineBreakMode) has not implement!")
                }
            }
            if !_innerText.isEmpty { _updateOuterTextProperties() }
            if !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The styled text displayed by the label.
    /// Set a new value to this property also replaces the value of the 'text', 'font', 'textColor', 'textAlignment' and so on.
    var attributedText: NSAttributedString? {
        get { return _innerText.isEmpty ? nil : _innerText }
        set {
            if _innerText == newValue { return }
            if newValue.isEmpty {
                _innerText = NSMutableAttributedString()
            } else {
                _innerText = newValue!.mutableCopy() as! NSMutableAttributedString
                if _innerText.po.font == nil { _innerText.po.font = _font }
                switch lineBreakMode {
                case .byWordWrapping, .byCharWrapping, .byClipping:
                    _innerText.po.lineBreakMode = _lineBreakMode
                case .byTruncatingHead, .byTruncatingTail, .byTruncatingMiddle:
                    _innerText.po.lineBreakMode = .byWordWrapping
                @unknown default:
                    fatalError("NSLineBreakMode: \(lineBreakMode) has not implement!")
                }
            }

            if !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _updateOuterTextProperties()
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The font of the text.
    private var _font: UIFont = UIFont.systemFont(ofSize: 17)
    var font: UIFont {
        get { return _font }
        set {
            if _font == newValue { return }
            _font = newValue
            _innerText.po.font = newValue
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The color of the text.
    private var _textColor: UIColor = UIColor.black
    var textColor: UIColor {
        get { return _textColor }
        set {
            if _textColor == newValue { return }
            _textColor = newValue
            _innerText.po.foregroundColor = newValue
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if !isIgnoredCommonProperties {
                    if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                    _setLayoutNeedUpdate()
                }
            }
        }
    }
    
    /// The shadow color of the text.
    private var _shadowColor: UIColor?
    var shadowColor: UIColor? {
        get { return _shadowColor }
        set {
            if _shadowColor == newValue { return }
            _shadowColor = newValue
            _innerText.po.shadow = _shadowFromProperties()
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
            }
        }
    }
    
    /// The shadow offset of the text.
    private var _shadowOffset: CGSize = .zero
    var shadowOffset: CGSize {
        get { return _shadowOffset }
        set {
            if _shadowOffset == newValue { return }
            _shadowOffset = newValue
            _innerText.po.shadow = _shadowFromProperties()
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
            }
        }
    }
    
    /// The shadow blur of the text.
    private var _shadowBlurRadius: CGFloat = -1
    var shadowBlurRadius: CGFloat {
        get { return _shadowBlurRadius }
        set {
            if _shadowBlurRadius == newValue { return }
            _shadowBlurRadius = newValue
            _innerText.po.shadow = _shadowFromProperties()
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
            }
        }
    }
    
    /// The text horizontal alignment in container.
    private var _textAlignment: NSTextAlignment = .natural
    var textAlignment: NSTextAlignment {
        get { return _textAlignment }
        set {
            if _textAlignment == newValue { return }
            _textAlignment = newValue
            _innerText.po.alignment = newValue
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The text vertical alignment in container.
    private var _textVerticalAlignment: PoTextVerticalAlignment = .center
    var textVerticalAlignment: PoTextVerticalAlignment {
        get { return _textVerticalAlignment }
        set {
            if _textVerticalAlignment == newValue { return }
            _textVerticalAlignment = newValue
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The technique to use for wrapping and truncating the label's text.
    private var _lineBreakMode: NSLineBreakMode = .byTruncatingTail
    var lineBreakMode: NSLineBreakMode {
        get { return _lineBreakMode }
        set {
            if _lineBreakMode == newValue { return }
            _lineBreakMode = newValue
            switch newValue {
            case .byWordWrapping, .byCharWrapping, .byClipping:
                _innerContainer.truncationType = .none
                _innerText.po.lineBreakMode = newValue
            case .byTruncatingHead:
                _innerContainer.truncationType = .head
                _innerText.po.lineBreakMode = .byWordWrapping
            case .byTruncatingTail:
                _innerContainer.truncationType = .tail
                _innerText.po.lineBreakMode = .byWordWrapping
            case .byTruncatingMiddle:
                _innerContainer.truncationType = .middle
                _innerText.po.lineBreakMode = .byWordWrapping
            @unknown default:
                fatalError("NSLineBreakMode: \(lineBreakMode) has not implement!")
            }
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The truncation token string used when text is truncated. default is nil, the label use '…' as truncation token.
    private var _truncationToken: NSAttributedString?
    var truncationToken: NSAttributedString? {
        get { return _truncationToken }
        set {
            if _truncationToken == newValue { return }
            _truncationToken = newValue
            _innerContainer.truncationToken = newValue
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The maximum number of lines to use for rendering text.
    /// Default is 1, 0 means no limit.
    private var _numberOfLines: Int = 1
    var numberOfLines: Int {
        get { return _numberOfLines }
        set {
            if _numberOfLines == newValue { return }
            _innerContainer.maximumNumberOfRows = newValue
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// When 'text' or 'attributedText' is changed, the parser will be called to modify the text.
    private var _textParser: PoTextParser?
    var textParser: PoTextParser? {
        get { return _textParser }
        set {
            _textParser = newValue
            if let parser = newValue, parser.parse(text: _innerText, selectedRange: nil) {
                _updateOuterTextProperties()
                if !_innerText.isEmpty && !isIgnoredCommonProperties {
                    if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                    _setLayoutNeedUpdate()
                    _endTouch()
                    invalidateIntrinsicContentSize()
                }
            }
        }
    }
    
    /// The current text layout in text view. set both textLayout and isIgnoredCommonProperties will get best performance
    var textLayout: PoTextLayout? {
        get {
            _updateIfNeeded()
            return _innerLayout
        }
        set {
            _innerLayout = newValue
            _innerText = (newValue?.text.mutableCopy() as? NSMutableAttributedString) ?? NSMutableAttributedString()
            _innerContainer = (newValue?.container.copy() as? PoTextContainer) ?? PoTextContainer(size: .zero)
            if !isIgnoredCommonProperties {
                _updateOuterTextProperties()
                _updateOuterContainerProperties()
            }
            if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
            _state.isLayoutNeedUpdate = false
            _setLayoutNeedRedraw()
            _endTouch()
            invalidateIntrinsicContentSize()
        }
    }
    
    /******************************************* text container *******************************************/
    
    /// A UIBezierPath object that specifies the shape of the text frame.
    private var _textContainerPath: UIBezierPath?
    var textContainerPath: UIBezierPath? {
        get { return _textContainerPath }
        set {
            if _textContainerPath == newValue { return }
            _textContainerPath = newValue
            _innerContainer.path = newValue
            if newValue == nil {
                _innerContainer.size = bounds.size
                _innerContainer.insets = _textContainerInsets
            }
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// An array of UIBezierPath objects representing the exclusion paths inside the receiver's bounding rectangle.
    private var _exclusionPaths: [UIBezierPath]?
    var exclusionPaths: [UIBezierPath]? {
        get { return _exclusionPaths }
        set {
            if _exclusionPaths == newValue { return }
            _exclusionPaths = newValue
            _innerContainer.exclusionPaths = newValue
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The insets of the text container's layout area within the text view's content area.
    private var _textContainerInsets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
    var textContainerInsets: UIEdgeInsets {
        get { return _textContainerInsets }
        set {
            if _textContainerInsets == newValue { return }
            _textContainerInsets = newValue
            _innerContainer.insets = newValue
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The text line position modifier used to modify the lines'position in layout.
    private var _linePositionModifier: (PoTextLinePositionModifier)?
    var linePositionModifier: PoTextLinePositionModifier? {
        get { return _linePositionModifier }
        set {
            _linePositionModifier = newValue
            _innerContainer.linePositionModifyer = newValue
            if !_innerText.isEmpty && !isIgnoredCommonProperties {
                if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay { _clearContents() }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The preferred maximum width for a multiple line label.(it is valid in autolayout)
    var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    /******************************************* text interaction *******************************************/
    
    /// When user tap the label, this action will be called.
    var textTapAction: PoTextAction?
    
    /// When user long press the label, this action will be called.
    var textLongPressAction: PoTextAction?
    
    /// When user tap the highlight range of text, this action will be called.
    var highlightTapAction: PoTextAction?
    
    /// When user long press the highlight range of text, this action will be called.
    var highlightLongPressAction: PoTextAction?
    
    /******************************************* text display *******************************************/
    
    /// A Boolean value indicating whether the layout and rendering codes are running asynchronously on back background threads.
    var isDisplayedAsynchronously: Bool = true {
        didSet { (layer as! PoAsyncLayer).isDispalyedsAsynchronously = isDisplayedAsynchronously }
    }
    
    /// If the value is true, and the layer is rendered asynchronously, then it will set label.layer.contents to nil before display.
    var isClearedContentsBeforeAsynchronouslyDisplay: Bool = true
    
    /// If the value is ture, and the layer is rendered asynchronously, then it will add a fade animation on layer when the contents of layer changed.
    var isFadedOnAsynchronouslyDisplay: Bool = true
    
    /// If the value is ture, then it will add a fade animation on layer when some range of text become highlighted.
    var isFadedHighlighted: Bool = true
    
    /// Ignore common properties (such as text, font, textColor, attributedtext...) and only use 'textLayout' to display content.
    var isIgnoredCommonProperties: Bool = false
    
    
    
    // MARK: - Properties - [private]
    
    private lazy var _innerText: NSMutableAttributedString = NSMutableAttributedString()
    private var _innerContainer: PoTextContainer = PoTextContainer()
    private var _innerLayout: PoTextLayout?
    
    private lazy var _attachmentViews: [UIView] = []
    private lazy var _attachmentLayers: [CALayer] = []
    
    private var _highlightRange: NSRange = NSRange(location: NSNotFound, length: 0)
    private var _highlight: PoTextHighlight?
    
    private var _longPressTimer: Timer?
    private var _touchBeganPoint: CGPoint = .zero
    private var _state: State = State()
    
    
    //MARK: - Override
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _initCommons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initCommons()
    }
    
    private func _initCommons() {
        _innerContainer.size = bounds.size
        _innerContainer.insets = _textContainerInsets
        _innerContainer.maximumNumberOfRows = numberOfLines
        layer.contentsScale = UIScreen.main.scale
    }
    
    deinit {
        _longPressTimer?.invalidate()
    }
    
    override class var layerClass: AnyClass {
        return PoAsyncLayer.self
    }
    
    override var frame: CGRect {
        willSet {
            if _state.usingAutoLayout { return }
            if frame.size == newValue.size { return }
            if _state.updatedSizeThatFits {
                _state.updatedSizeThatFits = false
                return
            }
            _innerContainer.size = newValue.size
            if !isIgnoredCommonProperties {
                _state.isLayoutNeedUpdate = true
            }
            if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay {
                _clearContents()
            }
            _setLayoutNeedRedraw()
        }
    }
    
    override var bounds: CGRect {
        willSet {
            if _state.usingAutoLayout { return }
            if bounds.size == newValue.size { return }
            
            _innerContainer.size = newValue.size
            if !isIgnoredCommonProperties {
                _state.isLayoutNeedUpdate = true
            }
            if isDisplayedAsynchronously && isClearedContentsBeforeAsynchronouslyDisplay {
                _clearContents()
            }
            _setLayoutNeedRedraw()
        }
    }
    
    /// 调用sizeToFit时调用此方法
    /// 此方法调用后系统会自动调用frame的set，记住状态这样可以减少一次layout计算
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if isIgnoredCommonProperties { return _innerLayout?.textBoundingSize ?? .zero }
        
        if preferredMaxLayoutWidth > 0 {
            _innerContainer.size.width = preferredMaxLayoutWidth
        } else {
            _innerContainer.size.width = size.width > 0 ? size.width : PoTextContainer.maxSize.width
        }
        _innerContainer.size.height = PoTextContainer.maxSize.height
        
        _updateIfNeeded()
        _state.updatedSizeThatFits = true
        
        return _innerLayout?.textBoundingSize ?? .zero
    }
    
    /// 只有在使用autolayout时才会调用此方法，否则就算调用invalidateIntrinsicContentSize也不会触发
    /// 此方法调用后系统会自动调用bounds的set，记住状态这样可以减少一次layout计算
    override var intrinsicContentSize: CGSize {
        _state.usingAutoLayout = true
        if preferredMaxLayoutWidth > 0 {
            _innerContainer.size.width = preferredMaxLayoutWidth
        } else {
            _innerContainer.size.width = bounds.size.width > 0 ? bounds.size.width : PoTextContainer.maxSize.width
        }
        _innerContainer.size.height = PoTextContainer.maxSize.height

        _updateIfNeeded()
        return _innerLayout?.textBoundingSize ?? .zero
    }

    
    // MARK: - Touches Handle
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        
        _highlight = _getHighlight(at: point, range: &_highlightRange)
        if _highlight != nil { _showHighlight(animated: true) }
        
        _state.hasTapAction = (textTapAction != nil || highlightTapAction != nil || _highlight?.tapAction != nil)
        _state.hasLongPressAction = (textLongPressAction != nil || highlightLongPressAction != nil || _highlight?.longPressAction != nil)
        
        if _state.hasTapAction || _state.hasLongPressAction {
            _touchBeganPoint = point
            _state.trackingTouch = true
            _state.swallowTouch = true
            _state.touchMoved = false
            if _state.hasLongPressAction { _startLongPressTimer() }
        } else {
            _state.trackingTouch = false
            _state.swallowTouch = false
            _state.touchMoved = false
        }
        
        if !_state.swallowTouch {
            super.touchesBegan(touches, with: event)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        
        if _state.trackingTouch {
            if !_state.touchMoved {
                let moveH = abs(point.x - _touchBeganPoint.x)
                let moveV = abs(point.y - _touchBeganPoint.y)
                if moveH > moveV {
                    if moveH > kLongPressAllowableMovement { _state.touchMoved = true }
                } else {
                    if moveV > kLongPressAllowableMovement { _state.touchMoved = true }
                }
                if _state.touchMoved {
                    _endLongPressTimer()
                }
            }
            
            if _state.touchMoved && _highlight != nil {
                let highlight = _getHighlight(at: point, range: nil)
                if highlight != _highlight {
                    _hideHighlight(animated: isFadedHighlighted)
                }
            }
        }
        
        if !_state.swallowTouch {
            super.touchesMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if _state.trackingTouch {
            _endLongPressTimer()
            if !_state.touchMoved && textTapAction != nil {
                var range = NSRange(location: NSNotFound, length: 0)
                var rect = CGRect.null
                let point1 = _convertPointToLayout(_touchBeganPoint)
                if let textRange = _innerLayout?.textRangeAtPoint(point1) {
                    let textRect = _innerLayout!.rectForRange(textRange)
                    rect = _convertRectFromLayout(textRect)
                    range = textRange.asRange
                }
                textTapAction?(self, _innerText, range, rect)
            }
        }
        
        if _highlight != nil {
            if !_state.touchMoved {
                let tapAction = _highlight?.tapAction ?? highlightTapAction
                if tapAction != nil {
                    let start = PoTextPosition(offset: _highlightRange.location)
                    let end = PoTextPosition(offset: _highlightRange.location + _highlightRange.length, affinity: .backward)
                    let rang = PoTextRange(start: start, end: end)
                    var rect = _innerLayout?.rectForRange(rang) ?? .zero
                    rect = _convertRectFromLayout(rect)
                    tapAction?(self, _innerText, _highlightRange, rect)
                }
            }
            _removeHighlight(animated: isFadedHighlighted)
        }
        
        if !_state.swallowTouch {
            super.touchesEnded(touches, with: event)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        _endTouch()
        if !_state.swallowTouch {
            super.touchesCancelled(touches, with: event)
        }
    }
    
    // MARK: - Methods - [private]
    
    private func _setLayoutNeedUpdate() {
        _state.isLayoutNeedUpdate = true
        _clearInnerLayout()
        _setLayoutNeedRedraw()
    }
    
    private func _updateIfNeeded() {
        if _state.isLayoutNeedUpdate {
            _state.isLayoutNeedUpdate = false
            _updateLayout()
        }
    }
    
    private func _updateLayout() {
        _innerLayout = PoTextLayout(container: _innerContainer, text: _innerText)
    }
    
    private func _setLayoutNeedRedraw() {
        layer.setNeedsDisplay()
    }
    
    private func _clearInnerLayout() {
        guard let layout = _innerLayout else { return }
        _innerLayout = nil
        PoDispatchQueuePool.utilityQOS.queue().async {
            let text = layout.text
            if layout.attachments != nil {
                DispatchQueue.main.async {
                    _ = text.self
                }
            }
        }
    }
    
    private func _startLongPressTimer() {
        _longPressTimer?.invalidate()
        _longPressTimer = Timer(timeInterval: kLongPressMiniDuration,
                                target: PoWeakProxy(target: self),
                                selector: #selector(_trackDidLongPress),
                                userInfo: nil,
                                repeats: false)
        RunLoop.current.add(_longPressTimer!, forMode: .common)
    }
    
    private func _endLongPressTimer() {
        _longPressTimer?.invalidate()
        _longPressTimer = nil
    }
    
    @objc
    private func _trackDidLongPress() {
        _endLongPressTimer()
        if _state.hasLongPressAction {
            var range = NSRange(location: NSNotFound, length: 0)
            var rect = CGRect.null
            let point = _convertPointToLayout(_touchBeganPoint)
            if let textRange = _innerLayout?.textRangeAtPoint(point) {
                let textRect = _innerLayout!.rectForRange(textRange)
                rect = _convertRectFromLayout(textRect)
                range = textRange.asRange
            }
            textLongPressAction?(self, _innerText, range, rect)
            _state.trackingTouch = false // 修复长按和单击同时设置了后，长按松开时会调用单击
        }
        
        if let hightlight = _highlight {
            let longPressAction = hightlight.longPressAction ?? highlightLongPressAction
            if let longPressAction = longPressAction, _highlightRange.location != NSNotFound  {
                let start = PoTextPosition(offset: _highlightRange.location)
                let end = PoTextPosition(offset: _highlightRange.location + _highlightRange.length, affinity: .backward)
                let range = PoTextRange(start: start, end: end)
                var rect = _innerLayout!.rectForRange(range)
                rect = _convertRectFromLayout(rect)
                longPressAction(self, _innerText, _highlightRange, rect)
            }
        }
    }
    
    private func _getHighlight(at point: CGPoint, range: NSRangePointer?) -> PoTextHighlight? {
        if _innerLayout?.isContainsHighlight == false { return nil }
        let aPoint = _convertPointToLayout(point)
        let position = _innerLayout!.textPositionForPoint(aPoint)
        if position == NSNotFound { return nil }
        
        var highlightRange = NSRange(location: NSNotFound, length: 0)
        let highlight = _innerText.attribute(.poHighlight, at: position, longestEffectiveRange: &highlightRange, in: NSRange(location: 0, length: _innerText.length))
        
        if highlight == nil { return nil }
        range?.pointee = highlightRange
        return highlight as? PoTextHighlight
    }
    
    private func _showHighlight(animated: Bool) {
        if _highlight != nil && _highlightRange.location != NSNotFound {
            _state.showHighlight = true
            _state.contentsNeedFade = animated
            _setLayoutNeedRedraw()
        }
    }
    
    private func _hideHighlight(animated: Bool) {
        if _state.showHighlight {
            _state.showHighlight = false
            _state.contentsNeedFade = animated
            _setLayoutNeedRedraw()
        }
    }
    
    private func _removeHighlight(animated: Bool) {
        _hideHighlight(animated: animated)
        _highlight = nil
    }
    
    private func _endTouch() {
        _endLongPressTimer()
        _removeHighlight(animated: true)
        _state.trackingTouch = false
    }
    

    // MARK: - Coordition convert
    
    private func _convertPointToLayout(_ point: CGPoint) -> CGPoint {
        guard let boundingSize = _innerLayout?.textBoundingSize else { return .zero }
        var point = point
        switch textVerticalAlignment {
        case .center:
            point.y -= (self.bounds.height - boundingSize.height) * 0.5
        case .bottom:
            point.y -= (self.bounds.height - boundingSize.height)
        case .top:
            break
        }
        return point
    }
    
    private func _convertPointFromLayout(_ point: CGPoint) -> CGPoint {
        guard let boundingSize = _innerLayout?.textBoundingSize else { return .zero }
        var point = point
        if boundingSize.height < self.bounds.height {
            switch textVerticalAlignment {
            case .center:
                point.y += (self.bounds.height - boundingSize.height) * 0.5
            case .bottom:
                point.y += (self.bounds.height - boundingSize.height)
            case .top:
                break
            }
        }
        return point
    }
    
    private func _convertRectToLayout(_ rect: CGRect) -> CGRect {
        var rect = rect
        rect.origin = _convertPointToLayout(rect.origin)
        return rect
    }
    
    private func _convertRectFromLayout(_ rect: CGRect) -> CGRect {
        var rect = rect
        rect.origin = _convertPointFromLayout(rect.origin)
        return rect
    }
    
    private func _shadowFromProperties() -> NSShadow? {
        if shadowColor == nil || shadowBlurRadius < 0 { return nil }
        let shadow = NSShadow()
        shadow.shadowColor = shadowColor
        shadow.shadowOffset = shadowOffset
        shadow.shadowBlurRadius = shadowBlurRadius
        return shadow
    }
    
    private func _updateOuterTextProperties() {
        _font = _innerText.po.font ?? UIFont.systemFont(ofSize: 17)
        _textColor = _innerText.po.foregroundColor ?? UIColor.black
        if _innerText.isEmpty == false {
            _textAlignment = _innerText.po.alignment
            _lineBreakMode = _innerText.po.lineBreakMode
        }
        let shadow = _innerText.po.shadow
        _shadowColor = shadow?.shadowColor as? UIColor
        _shadowOffset = shadow?.shadowOffset ?? .zero
        _shadowBlurRadius = shadow?.shadowBlurRadius ?? -1
        _updateOuterLineBreakMode()
    }
    
    private func _updateOuterContainerProperties() {
        _truncationToken = _innerContainer.truncationToken
        _numberOfLines = _innerContainer.maximumNumberOfRows
        _textContainerPath = _innerContainer.path
        _exclusionPaths = _innerContainer.exclusionPaths
        _textContainerInsets = _innerContainer.insets
        _linePositionModifier = _innerContainer.linePositionModifyer
        _updateOuterLineBreakMode()
    }
    
    private func _updateOuterLineBreakMode() {
        switch _innerContainer.truncationType {
        case .head:
            lineBreakMode = .byTruncatingHead
        case .tail:
            lineBreakMode = .byTruncatingTail
        case .middle:
            lineBreakMode = .byTruncatingMiddle
        case .none:
            lineBreakMode = _innerText.po.lineBreakMode
        }
    }
    
    private func _clearContents() {
        guard let contents = layer.contents else { return }
        
        let image = contents as! CGImage
        layer.contents = nil
        PoDispatchQueuePool.utilityQOS.queue().async {
            _ = image.self
        }
    }
    
}


// MARK: - PoAsyncLayerDelegate
extension PoLabel: PoAsyncLayerDelegate {
    
    func newAsyncDisplayTask() -> PoAsyncLayerDisplayTask {
        // capture current context
        let contentsNeedFade = _state.contentsNeedFade
        let text: NSAttributedString = _innerText
        let container = _innerContainer
        let verticalAlignment = textVerticalAlignment
        let layoutNeedUpdate = _state.isLayoutNeedUpdate
        let fadeForAsync = isDisplayedAsynchronously && isFadedOnAsynchronouslyDisplay
        
        var layout: PoTextLayout?
        if _state.showHighlight && _highlight != nil {
            let hiText = _innerText.mutableCopy() as! NSMutableAttributedString
            for (key, value) in _highlight!.attributes {
                hiText.po.setAttribute(key, value: value, range: _highlightRange)
            }
            layout = PoTextLayout(container: _innerContainer, text: hiText)
        } else {
            layout = _innerLayout
        }
        
        var layoutUpdated = false
        
        // create display task
        let dispalyTask = PoAsyncLayerDisplayTask()
        
        dispalyTask.willDisplay = { (layer) in
            layer.removeAnimation(forKey: "contents")
            
            // if the attachment not in new layout, or we don't know the new layout currently
            // the attachment should be removed.
            for view in self._attachmentViews {
                if layoutNeedUpdate || layout?.attachmentContentsSet?.contains(view) == false {
                    if view.superview == self {
                        view.removeFromSuperview()
                    }
                }
            }
            for layer in self._attachmentLayers {
                if layoutNeedUpdate || layout?.attachmentContentsSet?.contains(layer) == false {
                    if layer.superlayer == self.layer {
                        layer.removeFromSuperlayer()
                    }
                }
            }
            self._attachmentViews.removeAll()
            self._attachmentLayers.removeAll()
        }
        
        dispalyTask.display = { (context, size, isCancelled) in
            if isCancelled() || text.isEmpty { return }
            
            if layoutNeedUpdate { // 直到此时layout才计算
                layout = PoTextLayout(container: container, text: text)
                if isCancelled() { return }
                layoutUpdated = true
            }
            
            let boundingSize = layout?.textBoundingSize ?? .zero
            var point = CGPoint.zero
            switch verticalAlignment {
            case .center:
                point.y = (size.height - boundingSize.height) * 0.5
            case .bottom:
                point.y = (size.height - boundingSize.height)
            case .top:
                break
            }
            point = point.pixelRound // 像素对齐
            layout?.draw(in: context, point: point, size: size, view: nil, layer: nil, cancel: isCancelled)
        }
        
        dispalyTask.didDisplay = { (layer, finished) in
            
            // if the display task is cancelled, we should clear the attachments.
            if finished == false {
                if layout?.attachments == nil { return }
                for attachment in layout!.attachments! {
                    if let aview = attachment.content as? UIView {
                        if aview.superview == (layer.delegate as? UIView) { aview.removeFromSuperview() }
                    } else if let alayer = attachment.content as? CALayer {
                        if alayer.superlayer == layer { alayer.removeFromSuperlayer() }
                    }
                }
                return
            }
            
            layer.removeAnimation(forKey: "contents")
            
            guard let view = layer.delegate as? PoLabel else { return }
            if view._state.isLayoutNeedUpdate && layoutUpdated {
                view._innerLayout = layout
                view._state.isLayoutNeedUpdate = false
            }
            
            let size = layer.bounds.size
            let boundingSize = layout?.textBoundingSize ?? .zero
            var point = CGPoint.zero
            switch verticalAlignment {
            case .center:
                point.y = (size.height - boundingSize.height) * 0.5
            case .bottom:
                point.y = (size.height - boundingSize.height)
            case .top:
                break
            }
            point = point.pixelRound
            layout?.draw(in: nil, point: point, size: size, view: view, layer: layer)
            
            if layout?.attachments != nil {
                for attachment in layout!.attachments! {
                    if let aview = attachment.content as? UIView {
                        self._attachmentViews.append(aview)
                    } else if let alayer = attachment.content as? CALayer {
                        self._attachmentLayers.append(alayer)
                    }
                }
            }
            
            if contentsNeedFade {
                let transition = CATransition()
                transition.duration = kHighlightFadeDuration
                transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
                transition.type = .fade
                layer.add(transition, forKey: "contents")
            } else if fadeForAsync {
                let transition = CATransition()
                transition.duration = kAsyncFadeDuration
                transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
                transition.type = .fade
                layer.add(transition, forKey: "contents")
            }
        }
        
        return dispalyTask
    }
    
}


private let kLongPressMiniDuration: TimeInterval = 0.5
private let kLongPressAllowableMovement: CGFloat = 9.0
private let kHighlightFadeDuration: TimeInterval = 0.15
private let kAsyncFadeDuration: TimeInterval = 0.08

private struct State {
    var isLayoutNeedUpdate: Bool = false
    
    var usingAutoLayout: Bool = false
    var updatedSizeThatFits: Bool = false
    
    var showHighlight: Bool = false
    var trackingTouch: Bool = false
    var swallowTouch: Bool = false
    var touchMoved: Bool = false
    var hasTapAction: Bool = false
    var hasLongPressAction: Bool = false
    var contentsNeedFade: Bool = false
}
