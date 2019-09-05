//
//  PoTextAttachment.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/7/18.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

final class PoTextAttachment {
    
    // MARK: - Properties
    
    /// Supported type: UIImage, UIView, CALayer.
    var content: NSObject
    
    /// Content dispaly mode.
    var contentMode: UIView.ContentMode
    
    /// The insets when drawing content.
    var contentInsets: UIEdgeInsets
    
    /// The user information dictionary.
    var userInfo: Dictionary<AnyHashable, Any>?
    
    // MARK: - Initializer
    init(content: NSObject, contentMode: UIView.ContentMode = .scaleToFill, contentInsets: UIEdgeInsets = .zero) {
        self.content = content
        self.contentMode = contentMode
        self.contentInsets = contentInsets
    }
}
