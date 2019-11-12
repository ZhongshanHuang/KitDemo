//
//  UIButton+extension.swift
//  APITest
//
//  Created by iOSer on 2019/8/8.
//  Copyright © 2019 iOSer. All rights reserved.
//

import UIKit

extension UIButton {
    
    enum ContentLayout {
        case imageTop
        case imageLeft
        case imageBottom
        case imageRight
    }
    
    func adjustContentLayout(_ layout: ContentLayout, spacing: CGFloat = 0) {
        
        guard let imageSize = self.imageView?.image?.size, let font = self.titleLabel?.font, let text = self.titleLabel?.text else { return }
        let textSize = text.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [], attributes: [.font: font], context: nil).size
        let spacingInset = spacing / 2
        let maxWidth = max(textSize.width, imageSize.width)
        let HInset = (textSize.width + imageSize.width - maxWidth) / 2
        let maxHeight = max(textSize.height, imageSize.height)
        let VInset = (textSize.height + imageSize.height - maxHeight) / 2
        
        switch layout {
        case .imageTop:
            // 移动距离 = (left - right) / 2
            imageEdgeInsets = UIEdgeInsets(top: -textSize.height / 2 - spacingInset, left: textSize.width / 2, bottom: textSize.height / 2 + spacingInset, right: -textSize.width / 2)
            titleEdgeInsets = UIEdgeInsets(top: imageSize.height / 2 + spacingInset, left: -imageSize.width / 2, bottom: -imageSize.height / 2 - spacingInset, right: imageSize.width / 2)
            // 正数向外扩展，负数向内缩小
            contentEdgeInsets = UIEdgeInsets(top: VInset + spacingInset, left: -HInset, bottom: VInset + spacingInset, right: -HInset)
        case .imageLeft:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacingInset, bottom: 0, right: spacingInset)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: spacingInset, bottom: 0, right: -spacingInset)
            contentEdgeInsets = UIEdgeInsets(top: 0, left: spacingInset, bottom: 0, right: spacingInset)
        case .imageBottom:
            imageEdgeInsets = UIEdgeInsets(top: textSize.height / 2 + spacingInset, left: textSize.width / 2, bottom: -textSize.height / 2 - spacingInset, right: -textSize.width / 2)
            titleEdgeInsets = UIEdgeInsets(top: -imageSize.height / 2 - spacingInset, left: -imageSize.width / 2, bottom: imageSize.height / 2 + spacingInset, right: imageSize.width / 2)
            contentEdgeInsets = UIEdgeInsets(top: VInset + spacingInset, left: -HInset, bottom: VInset + spacingInset, right: -HInset)
        case .imageRight:
            imageEdgeInsets = UIEdgeInsets(top: 0, left: textSize.width  + spacingInset, bottom: 0, right: -textSize.width - spacingInset)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width - spacingInset, bottom: 0, right: imageSize.width + spacingInset)
            contentEdgeInsets = UIEdgeInsets(top: 0, left: spacingInset, bottom: 0, right: spacingInset)
        }
    }
    
}
