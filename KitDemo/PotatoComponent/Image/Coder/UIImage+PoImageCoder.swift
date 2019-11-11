//
//  UIImage+PoImageCoder.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/5/15.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

extension UIImage {
    private struct PoImageCoderKey {
        static let isDecodedForDisplayKey: String = ""
    }
}

extension UIImage {
    
    var isDecodedForDisplay: Bool {
        get {
            if (images?.count ?? 0) > 1 { return true }
            return (objc_getAssociatedObject(self, PoImageCoderKey.isDecodedForDisplayKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, PoImageCoderKey.isDecodedForDisplayKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    func imageByDecoded() -> Self {
        if self.isDecodedForDisplay { return self }
        guard let imageRef = self.cgImage else { return self }
        guard let newImageRef = imageRef.copy(decodeForDispaly: true) else { return self }
        let newImage = type(of: self).init(cgImage: newImageRef, scale: self.scale, orientation: self.imageOrientation)
        newImage.isDecodedForDisplay = true
        return newImage
    }
}


