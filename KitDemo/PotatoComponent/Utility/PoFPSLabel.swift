//
//  PoFPSLabel.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/6/11.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

final class PoFPSLabel: UILabel {
    
    // MARK: - Properties - [private]
    private var _link: CADisplayLink!
    private var _count: Double = 0
    private var _lastTime: TimeInterval = 0
    private let _font: UIFont = UIFont(name: "Courier", size: 14)!
    private let _subFont: UIFont = UIFont(name: "Courier", size: 4)!
    
    override init(frame: CGRect) {
        var labelFrame = frame
        if frame.size == .zero { labelFrame.size = CGSize(width: 55, height: 20) }
        super.init(frame: labelFrame)
        _link = CADisplayLink(target: PoWeakProxy(target: self), selector: #selector(tick))
        _link.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        layer.cornerRadius = 5
        clipsToBounds = true
        textAlignment = .center
        isUserInteractionEnabled = false
        backgroundColor = UIColor(white: 0.0, alpha: 0.7)
    }
    
    deinit {
        _link.invalidate()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Selector
    @objc private func tick() {
        if _lastTime == 0 {
            _lastTime = _link.timestamp
            return
        }
        
        _count += 1
        let delta = _link.timestamp - _lastTime
        if delta < 1 { return }
        _lastTime = _link.timestamp
        let fps = _count / delta
        let progress = fps / 60.0
        _count = 0
        
        let text = NSMutableAttributedString(string: "\(Int(round(fps))) FPS")
        let color = UIColor(hue: 0.27 * CGFloat(progress - 0.2), saturation: 1, brightness: 0.9, alpha: 1)
        text.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0, length: text.length - 4))
        text.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: NSRange(location: text.length - 3, length: 3))
        text.addAttribute(NSAttributedString.Key.font, value: _font, range: NSRange(location: 0, length: text.length))
        text.addAttribute(NSAttributedString.Key.font, value: _subFont, range: NSRange(location: text.length - 4, length: 1))
        
        self.attributedText = text
    }
    
}


