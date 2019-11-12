//
//  UIView+extension.swift
//  KitDemo
//
//  Created by 黄山哥 on 2018/11/1.
//  Copyright © 2018 黄中山. All rights reserved.
//

import UIKit

extension UIView {
    
    /// 屏幕截图
    @available(iOS 10.0, *)
    var snapshotImage: UIImage {
        let format: UIGraphicsImageRendererFormat
        if #available(iOS 11, *) {
            format = UIGraphicsImageRendererFormat.preferred()
        } else {
            format = UIGraphicsImageRendererFormat.default()
        }
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        let image = renderer.image { (context) in
            UIGraphicsPushContext(context.cgContext)
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
            UIGraphicsPopContext()
        }
        return image
    }
    
    /// 设置阴影
    func setLayerShadow(color: UIColor, offset: CGSize, radius: CGFloat) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowPath = CGPath(rect: bounds, transform: nil)
        layer.shadowOpacity = 1
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    /// 获取view响应链上的第一个controller
    var viewController: UIViewController? {
        var nextResponder = next
        while nextResponder != nil {
            if let vc = nextResponder as? UIViewController {
                return vc
            }
            nextResponder = nextResponder?.next
        }
        return nil
    }
    
    // MARK: - Coordination convert
    
    func convert(point: CGPoint, toViewOrWindow view: UIView) -> CGPoint {
        let from = (self is UIWindow) ? (self as! UIWindow) : self.window
        let to = (view is UIWindow) ? (view as! UIWindow) : view.window
        
        if (from == nil || to == nil) || from == to {
            return convert(point, to: view)
        }
        
        var point = convert(point, to: from)
        point = to!.convert(point, from: from)
        point = view.convert(point, from: to)
        return point
    }
    
    func convert(point: CGPoint, fromViewOrWindow view: UIView) -> CGPoint {
        let from = (view is UIWindow) ? (view as! UIWindow) : view.window
        let to = (self is UIWindow) ? (self as! UIWindow) : self.window
        
        if (from == nil || to == nil) || from == to {
            return convert(point, to: view)
        }
        
        var point = from!.convert(point, from: view)
        point = to!.convert(point, from: from)
        point = convert(point, from: to)
        return point
    }
    
    func convert(rect: CGRect, toViewOrWindow view: UIView) -> CGRect {
        let from = (self is UIWindow) ? (self as! UIWindow) : self.window
        let to = (view is UIWindow) ? (view as! UIWindow) : view.window
        
        if (from == nil || to == nil) || from == to {
            return convert(rect, to: view)
        }
        
        var rect = convert(rect, to: from)
        rect = to!.convert(rect, from: from)
        rect = view.convert(rect, from: to)
        return rect
    }
    
    func convert(rect: CGRect, fromViewOrWindow view: UIView) -> CGRect {
        let from = (view is UIWindow) ? (view as! UIWindow) : view.window
        let to = (self is UIWindow) ? (self as! UIWindow) : self.window
        
        if (from == nil || to == nil) || from == to {
            return convert(rect, to: view)
        }
        
        var rect = from!.convert(rect, from: view)
        rect = to!.convert(rect, from: from)
        rect = convert(rect, from: to)
        return rect
    }
}

extension UIView {
    
    var origin: CGPoint {
        get { return frame.origin }
        set { frame.origin = newValue }
    }
    
    var size: CGSize {
        get { return frame.size }
        set { frame.size = newValue }
    }
    
    var width: CGFloat {
        get { return frame.size.width }
        set { frame.size.width = newValue }
    }
    
    var height: CGFloat {
        get { return frame.size.height }
        set { frame.size.height = newValue }
    }
    
    var top: CGFloat {
        get { return frame.origin.y }
        set { frame.origin.y = newValue }
    }
    
    var left: CGFloat {
        get { return frame.origin.x }
        set { frame.origin.x = newValue }
    }
    
    var bottom: CGFloat {
        get { return frame.origin.y + frame.size.height }
        set { frame.origin.y = newValue - frame.size.height }
    }
    
    var right: CGFloat {
        get { return frame.origin.x + frame.size.width }
        set { frame.origin.x = newValue - frame.size.width }
    }
}
