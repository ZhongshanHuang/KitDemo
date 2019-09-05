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
//        static let imageDataRepresentationKey: String = ""
    }
    
    var isDecodedForDisplay: Bool {
        get {
            if (images?.count ?? 0) > 1 { return true }
            return (objc_getAssociatedObject(self, PoImageCoderKey.isDecodedForDisplayKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, PoImageCoderKey.isDecodedForDisplayKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    func imageByDecoded() -> UIImage {
        if self.isDecodedForDisplay { return self }
        guard let imageRef = self.cgImage else { return self }
        guard let newImageRef = PoCGImageCreateDecodedCopy(imageRef: imageRef, decodeForDispaly: true) else { return self }
        let newImage = UIImage(cgImage: newImageRef, scale: self.scale, orientation: self.imageOrientation)
        newImage.isDecodedForDisplay = true
        return newImage
    }
}


