//
//  CGImage+PoImageCoder.swift
//  KitDemo
//
//  Created by 黄中山 on 2019/11/11.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import zlib
import Accelerate.vImage

extension CGImage {
    
    /// Decode an image to bitmap buffer with the specified format.
    /// - Parameters:
    ///   - srcImage: Source image
    ///   - dest: Destination buffer. It should be zero before call this method.
    ///   If decode succeed, you should release the dest->data using free().
    ///   - destFormat: Destination bitmap format.
    /// - Returns: Whether succeed.
    func decodeToBitmapBufferWithAnyFormat(dest: UnsafeMutablePointer<vImage_Buffer>, destFormat: UnsafePointer<vImage_CGImageFormat>) -> Bool {
        let width = vImagePixelCount(self.width)
        let height = vImagePixelCount(self.height)
        if width == 0 || height == 0 { return false }
        
        var error: vImage_Error
        var convertor: vImageConverter?
        var srcFormat = vImage_CGImageFormat()
        srcFormat.bitsPerComponent = UInt32(self.bitsPerComponent)
        srcFormat.bitsPerPixel = UInt32(self.bitsPerPixel)
        srcFormat.colorSpace = Unmanaged.passUnretained(self.colorSpace!)
        srcFormat.bitmapInfo = CGBitmapInfo(rawValue: self.bitmapInfo.rawValue | self.alphaInfo.rawValue)
        
        convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, destFormat, nil, vImage_Flags(kvImageNoFlags), nil)?.takeRetainedValue()
        if convertor == nil { return false }
        
        guard let srcData = self.dataProvider?.data else { return false }
        let srcLength = CFDataGetLength(srcData)
        let srcBytes = CFDataGetBytePtr(srcData)
        if srcLength == 0 || srcBytes == nil { return false }
        
        var src = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: srcBytes), height: height, width: width, rowBytes: self.bytesPerRow)
        
        error = vImageBuffer_Init(dest, height, width, 32, vImage_Flags(kvImageNoFlags))
        if error != kvImageNoError { return false }
        
        error = vImageConvert_AnyToAny(convertor!, &src, dest, nil, vImage_Flags(kvImageNoFlags))
        if error != kvImageNoError { return false }
        
        return true
    }

    /// Decode an image to bitmap buffer with the 32bit format (such as ARGB8888)
    /// - Parameters:
    ///   - srcImage: Source image
    ///   - dest: Destination buffer. It should be zero before call this method.
    ///   If decode succeed, you should release the dest->data using free().
    ///   - bitmapInfo: Destination bitmap format.
    func decodeToBitmapBufferWith32BitFormat(dest: UnsafeMutablePointer<vImage_Buffer>, bitmapInfo: CGBitmapInfo) -> Bool {
        let width = self.width
        let height = self.height
        if width == 0 || height == 0 { return false }
        
        /*
         Try convert with vImageConvert_AnyToAny() (avaliable since iOS 7.0).
         If fail, try decode with CGContextDrawImage().
         CGBitmapContext use a premultiplied alpha format, unpremultiply may lose precision.
         */
        var destFormat = vImage_CGImageFormat()
        destFormat.bitsPerComponent = 8
        destFormat.bitsPerPixel = 32
        destFormat.colorSpace = Unmanaged.passUnretained(PoCGColorSpaceGetDeviceRGB)
        destFormat.bitmapInfo = bitmapInfo
        
        if decodeToBitmapBufferWithAnyFormat(dest: dest, destFormat: &destFormat) { return true }
        
        var hasAlpha = false
        var alphaFirst = false
        var alphaPremultiplied = false
        var byteOrderNormal = false
        
        switch bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue {
        case CGImageAlphaInfo.premultipliedLast.rawValue:
            hasAlpha = true
            alphaPremultiplied = true
        case CGImageAlphaInfo.premultipliedFirst.rawValue:
            hasAlpha = true
            alphaPremultiplied = true
            alphaFirst = true
        case CGImageAlphaInfo.last.rawValue:
            hasAlpha = true
        case CGImageAlphaInfo.first.rawValue:
            hasAlpha = true
            alphaFirst = true
        case CGImageAlphaInfo.noneSkipLast.rawValue:
            break
        case CGImageAlphaInfo.noneSkipFirst.rawValue:
            alphaFirst = true
        default:
            return false
        }
        
        switch  bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue {
        case CGImageByteOrderInfo.orderDefault.rawValue:
            byteOrderNormal = true
        case CGBitmapInfo.byteOrder32Little.rawValue:
            byteOrderNormal = true
        case CGBitmapInfo.byteOrder32Big.rawValue:
            break
        default:
            return false
        }
        
        var contextBitmapInfo = bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue
        if !hasAlpha || alphaPremultiplied {
            contextBitmapInfo |= (bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        } else {
            contextBitmapInfo |= alphaFirst ? CGImageAlphaInfo.premultipliedFirst.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue
        }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: PoCGColorSpaceGetDeviceRGB, bitmapInfo: contextBitmapInfo) else { return false }
        
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height)) // decode and convert
        let bytesPerRow = context.bytesPerRow
        let length = height * bytesPerRow
        guard let data = context.data, length > 0 else { return false }
        
        dest.pointee.data = UnsafeMutableRawPointer.allocate(byteCount: length, alignment: MemoryLayout<UInt8>.stride)
        dest.pointee.width = vImagePixelCount(width)
        dest.pointee.height = vImagePixelCount(height)
        dest.pointee.rowBytes = bytesPerRow
        
        if hasAlpha && !alphaPremultiplied {
            var tmpSrc = vImage_Buffer(data: data, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
            var error: vImage_Error = kvImageNoError
            if alphaFirst && byteOrderNormal {
                error = vImageUnpremultiplyData_ARGB8888(&tmpSrc, dest, vImage_Flags(kvImageNoFlags))
            } else {
                error = vImageUnpremultiplyData_RGBA8888(&tmpSrc, dest, vImage_Flags(kvImageNoFlags))
            }
            if error != kvImageNoError {
                dest.pointee.data.deallocate()
                return false
            }
        } else {
            memcpy(dest.pointee.data, data, length)
        }
        return true
    }


    /// 将未解码的CGImage解码
    ///
    /// - Parameters:
    ///   - imageRef: 未解码的CGImage
    ///   - decodeForDispaly: 是否解码
    /// - Returns: 解码后的CGImage
    func copy(decodeForDispaly: Bool) -> CGImage? {
        let width = self.width
        let height = self.height
        if width == 0 || height == 0 { return nil }
        
        if decodeForDispaly { // decode with redraw (may lose some precision)
            let alphaInfo = self.alphaInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
            var hasAlpha = false
            if alphaInfo == CGImageAlphaInfo.premultipliedLast.rawValue ||
                alphaInfo == CGImageAlphaInfo.premultipliedFirst.rawValue ||
                alphaInfo == CGImageAlphaInfo.last.rawValue ||
                alphaInfo == CGImageAlphaInfo.first.rawValue {
                hasAlpha = true
            }
            
            // ARGB8888 (premultiplied) or XRGB8888
            // same as UIGraphicsBeginImageContext() and UIView.draw(rect:)
            var bitmapInfo = CGBitmapInfo.byteOrder32Host.rawValue
            if hasAlpha {
                bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue
            } else {
                bitmapInfo |= CGImageAlphaInfo.noneSkipFirst.rawValue
            }
            
            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: PoCGColorSpaceGetDeviceRGB, bitmapInfo: bitmapInfo) else { return nil }
            context.interpolationQuality = .high
            context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
            return context.makeImage()
        } else {
            let space = self.colorSpace!
            let bitsPerComponent = self.bitsPerComponent
            let bitsPerPixel = self.bitsPerPixel
            let bytesPerRow = self.bytesPerRow
            let bitmapInfo = self.bitmapInfo
            if bytesPerRow == 0 || width == 0 || height == 0 { return nil }
            
            guard let copyData = CFDataCreateCopy(kCFAllocatorDefault, self.dataProvider?.data),
                let newProvider = CGDataProvider(data: copyData) else {
                return nil
            }
            
            let newImage = CGImage(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: space, bitmapInfo: bitmapInfo, provider: newProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
            return newImage
        }
    }

    func copy(withAffineTransform transform: CGAffineTransform, destSize: CGSize) -> CGImage? {
        let srcWidth: size_t = self.width
        let srcHeight: size_t = self.height
        let destWidth: size_t = size_t(round(destSize.width))
        let destHeight: size_t = size_t(round(destSize.height))
        if srcWidth == 0 || srcHeight == 0 || destWidth == 0 || destHeight == 0 { return nil }
        
        let destProvider: CGDataProvider?
        var destImage: CGImage?
        var src = vImage_Buffer()
        var dest = vImage_Buffer()
        defer {
            if src.data != nil { src.data.deallocate() }
            if dest.data != nil { dest.data.deallocate() }
        }
        if !decodeToBitmapBufferWith32BitFormat(dest: &src, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)) { return nil }
        
        let destBytesPerRow = PoImageByteAlign(size: destWidth * 4, alignment: 32)
        dest.data = UnsafeMutableRawPointer.allocate(byteCount: destHeight * destBytesPerRow, alignment: MemoryLayout<UInt8>.stride)
        dest.width = vImagePixelCount(destWidth)
        dest.height = vImagePixelCount(destHeight)
        dest.rowBytes = destBytesPerRow
        var vTransform = vImage_AffineTransform(a: Float(transform.a),
                                                b: Float(transform.b),
                                                c: Float(transform.c),
                                                d: Float(transform.d),
                                                tx: Float(transform.tx),
                                                ty: Float(transform.ty))
        let backColor = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
        backColor.initialize(repeating: 0, count: 4)
        defer { backColor.deallocate() }
        let error = vImageAffineWarp_ARGB8888(&src, &dest, nil, &vTransform, backColor, vImage_Flags(kvImageBackgroundColorFill))
        if error != kvImageNoError { return nil }
        src.data.deallocate()
        src.data = nil
        
        destProvider = CGDataProvider(dataInfo: dest.data, data: dest.data, size: destHeight * destBytesPerRow, releaseData: PoCGDataProviderReleaseDataCallback)
        dest.data = nil // data hold by tmpProvider
        if destProvider == nil { return nil }
        destImage = CGImage(width: destWidth, height: destHeight, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: destBytesPerRow, space: PoCGColorSpaceGetDeviceRGB, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue | CGImageByteOrderInfo.orderDefault.rawValue), provider: destProvider!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)

        return destImage
    }
    
    /// 将imageRef按照orientation形变，生成新的位图
    /// - Parameters:
    ///   - imageRef: 原始图片
    ///   - orientation: 新图片的方向
    /// - 生成的新位图
    func copy(withOrientation orientation: UIImage.Orientation) -> CGImage? {
        if orientation == .up { return self }
        
        let width = CGFloat(self.width)
        let height = CGFloat(self.height)
        
        // bottom left coordinate system.
        // http://www.cocoachina.com/articles/12021
        // rotate正数是逆时针
        // transform后面的先作用
        // orientation是相机拍摄时的方向
        var transform = CGAffineTransform.identity
        var swapWidthAndHeight = false
        switch orientation {
        case .down:
            transform = transform.rotated(by: .pi)
            transform = transform.translatedBy(x: -width, y: -height)
        case .left:
            transform = transform.rotated(by: .pi/2)
            transform = transform.translatedBy(x: 0, y: -height)
            swapWidthAndHeight = true
        case .right:
            transform = transform.rotated(by: -.pi/2)
            transform = transform.translatedBy(x: -width, y: 0)
            swapWidthAndHeight = true
        case .upMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .downMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.scaledBy(x: 1, y: -1)
        case .leftMirrored:
            transform = transform.rotated(by: -.pi/2)
            transform = transform.scaledBy(x: 1, y: -1)
            transform = transform.translatedBy(x: -width, y: -height)
            swapWidthAndHeight = true
        case .rightMirrored:
            transform = transform.rotated(by: .pi/2)
            transform = transform.scaledBy(x: 1, y: -1)
            swapWidthAndHeight = true
        default:
            break
        }
        if transform.isIdentity { return self }
        var destSize = CGSize(width: width, height: height)
        if swapWidthAndHeight {
            destSize.width = height
            destSize.height = width
        }
        
        return copy(withAffineTransform: transform, destSize: destSize)
    }

    func encodedData(type: PoImageType, quality: CGFloat) -> NSData? {
        var quality = quality
        if quality < 0 { quality = 0 }
        if quality > 1 { quality = 1 }
        
        guard let uti = type.uiType else { return nil }
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else { return nil }
        guard let dest = CGImageDestinationCreateWithData(data, uti, 1, nil) else { return nil }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, self, options as CFDictionary)
        CGImageDestinationFinalize(dest)
        return data
    }
    
}
