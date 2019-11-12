//
//  UIImage+extension.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/9/24.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

extension UIImage {
    
    @available(iOS 10.0, *)
    func redrawImage(size: CGSize, corner: CGFloat = 0, scale: CGFloat = UIScreen.main.scale, targetColor: UIColor? = nil, blendMode: CGBlendMode = .normal) -> UIImage {
        let format: UIGraphicsImageRendererFormat
        if #available(iOS 11, *) {
            format = UIGraphicsImageRendererFormat.preferred()
        } else {
            format = UIGraphicsImageRendererFormat.default()
        }
        format.scale = scale
        let imageRender = UIGraphicsImageRenderer(size: size, format: format)
        return imageRender.image { (imageRendererCtx) in
            let ctx = imageRendererCtx.cgContext
            let cgPath = CGPath(roundedRect: CGRect(origin: .zero, size: size), cornerWidth: corner, cornerHeight: corner, transform: nil)
            
            if let color = targetColor {
                ctx.addPath(cgPath)
                ctx.setFillColor(color.cgColor)
                ctx.fillPath()
            }
            
            ctx.addPath(cgPath)
            ctx.clip(using: .evenOdd)
            
            ctx.setBlendMode(blendMode)
            ctx.translateBy(x: 0, y: size.height)
            ctx.scaleBy(x: 1, y: -1)
            ctx.draw(self.cgImage!, in: CGRect(origin: .zero, size: size))
        }
    }
    
    @available(iOS 10.0, *)
    static func draw(in size: CGSize, drawClosure: (CGContext) -> Void) -> UIImage {
        let format: UIGraphicsImageRendererFormat
        if #available(iOS 11, *) {
            format = UIGraphicsImageRendererFormat.preferred()
        } else {
            format = UIGraphicsImageRendererFormat.default()
        }
        let imageRender = UIGraphicsImageRenderer(size: size, format: format)
        return imageRender.image { (imageRendererCtx) in
            let ctx = imageRendererCtx.cgContext
            drawClosure(ctx)
        }
    }
    
}


