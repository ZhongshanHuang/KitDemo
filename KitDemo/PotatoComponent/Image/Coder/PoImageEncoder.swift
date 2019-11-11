//
//  PoImageEncoder.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/4/29.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import zlib

final class PoImageEncoder {
    
    // MARK: - Properties - [public]
    
    private(set) var type: PoImageType = .unknown
    var loopCount: Int = 0
    var quality: CGFloat = 1.0 {
        didSet {
            if quality < 0 {
                quality = 0
            } else if quality > 1 {
                quality = 1
            }
        }
    }
    
    private lazy var _images: [AnyObject] = []
    private lazy var _durations: [TimeInterval] = []
    
    // MARK: - Initializators
    
    init?(type: PoImageType) {
        self.type = type
        switch type {
        case .jpeg, .jpeg2000:
            quality = 0.9
        case .tiff, .bmp, .gif, .ico, .icns, .png:
            quality = 1
        case .unknown, .webp:
            return nil
        }
    }
    
    // MARK: - Methods - [public]
    
    
    /// Add an image to encoder.
    ///
    /// - Parameters:
    ///   - image: Image.
    ///   - duration: Image duration for animation. Pass 0 to ignore this parameter.
    func add(image: UIImage, duration: TimeInterval = 0) {
        if image.cgImage == nil { return }
        var duration = duration
        if duration < 0 { duration = 0 }
        _images.append(image)
        _durations.append(duration)
    }
    
    
    /// Add an image with image data to encoder.
    ///
    /// - Parameters:
    ///   - data: image data.
    ///   - duration: Image duration for animation. Pass 0 to ignore this parameter.
    func addImage(with data: Data, duration: TimeInterval = 0) {
        if data.isEmpty { return }
        var duration = duration
        if duration < 0 { duration = 0 }
        _images.append(data as NSData)
        _durations.append(duration)
    }
    
    
    /// Add an image from a file path to encoder.
    ///
    /// - Parameters:
    ///   - file: Image file path.
    ///   - duration: Image duration for animation. Pass 0 to ignore this parameter.
    func addImage(with file: String, duration: TimeInterval = 0) {
        if file.isEmpty { return }
        var duration = duration
        if duration < 0 { duration = 0 }
        guard let url = NSURL(string: file) else { return }
        _images.append(url)
        _durations.append(duration)
    }
    
    
    /// Encodes the image and returns the image data.
    ///
    /// - Returns: The image data, or nil if an error occurs.
    func encode() -> Data? {
        if _images.isEmpty { return nil }
        
        if _imageIOAvaliable() {
            return _encodeWithImageIO()
        }
        if type == .png {
            return _encodeAPNG()
        }
        return nil
    }
    
    
    /// Encodes the image to a file.
    ///
    /// - Parameter file: The file path
    /// - Returns: Whether succeed.
    func encode(to file: String) -> Bool {
        if _images.isEmpty || file.isEmpty { return false }
        
        if _imageIOAvaliable() { return _encodeWithImageIO(path: file) }
        if let data = encode() {
            return (data as NSData).write(toFile: file, atomically: true)
        }
        return false
    }
    
    
    /// Convenience method to encode single frame image.
    ///
    /// - Parameters:
    ///   - image: The image.
    ///   - type: The destination image type.
    ///   - quality: Image quality, 0.0~1.0.
    /// - Returns: The image data, or nil if an error occurs.
    static func encode(image: UIImage, type: PoImageType, quality: CGFloat) -> Data? {
        guard let encoder = PoImageEncoder(type: type) else { return nil }
        encoder.quality = quality
        encoder.add(image: image, duration: 0)
        return encoder.encode()
    }
    
    
    /// Convenience method to encode image from a decoder.
    ///
    /// - Parameters:
    ///   - decoder: The image decoder.
    ///   - type: The destination image type.
    ///   - quality: Image quality, 0.0~1.0.
    /// - Returns: The image data, or nil if an error occurs.
    static func encodeImage(with decoder: PoImageDecoder, type: PoImageType, quality: CGFloat) -> Data? {
        if decoder.frameCount == 0 { return nil }
        guard let encoder = PoImageEncoder(type: type) else { return nil }
        for i in 0..<decoder.frameCount {
            if let frame = decoder.frame(at: i, decodeForDisplay: true)?.image {
                encoder.addImage(with: frame.pngData()!, duration: decoder.frameDuration(at: i))
            }
        }
        return encoder.encode()
    }
    
    // MARK: - Helper
    
    private func _imageIOAvaliable() -> Bool {
        switch type {
        case .jpeg, .jpeg2000, .tiff, .bmp, .ico, .icns, .gif:
            return !_images.isEmpty
        case .png:
            return _images.count == 1
        default:
            return false
        }
    }
    
    private func _encodeImage(with destination: CGImageDestination, imageCount: Int) {
        if type == .gif {
            let gifProperty: [CFString: Any] = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loopCount]]
            CGImageDestinationSetProperties(destination, gifProperty as CFDictionary)
        }
        
        for i in 0..<imageCount {
            let imageSrc = _images[i]
            var frameProperty: [CFString: Any]
            if type == .gif && imageCount > 1 {
                frameProperty = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: _durations[i]]]
            } else {
                frameProperty = [kCGImageDestinationLossyCompressionQuality: quality]
            }
            
            if var image = imageSrc as? UIImage {
                if image.imageOrientation != .up && image.cgImage != nil {
                    if let rotated = image.cgImage?.copy(withOrientation: image.imageOrientation) {
                        image = UIImage(cgImage: rotated)
                    }
                }
                if let cgImage = image.cgImage {
                    CGImageDestinationAddImage(destination, cgImage, frameProperty as CFDictionary)
                }
            } else if let source = imageSrc as? NSURL {
                if let source = CGImageSourceCreateWithURL(source, nil) {
                    CGImageDestinationAddImageFromSource(destination, source, 0, frameProperty as CFDictionary)
                }
            } else if let data = imageSrc as? NSData {
                if let source = CGImageSourceCreateWithData(data, nil) {
                    CGImageDestinationAddImageFromSource(destination, source, 0, frameProperty as CFDictionary)
                }
            }
        }
    }
    
    private func _newCGImage(from index: Int, decoded: Bool) -> CGImage? {
        var image: UIImage?
        if let imageSrc = _images[index] as? UIImage {
            image = imageSrc
        } else if let imageSrc = _images[index] as? NSURL {
            image = UIImage(contentsOfFile: imageSrc.absoluteString!)
        } else if let imageSrc = _images[index] as? Data {
            image = UIImage(data: imageSrc)
        }
        
        guard let imageRef = image?.cgImage else { return nil }
        if image!.imageOrientation != .up {
            return imageRef.copy(withOrientation: image!.imageOrientation)
        }
        if decoded {
            return imageRef.copy(decodeForDispaly: true)
        }
        return imageRef
    }
    
    private func _encodeWithImageIO() -> Data? {
        let data = CFDataCreateMutable(kCFAllocatorDefault, 0)!
        let count = type == .gif ? _images.count : 1
        let destination = CGImageDestinationCreateWithData(data, type.uiType!, count, nil)
        var suc = false
        if let destination = destination {
            _encodeImage(with: destination, imageCount: count)
            suc = CGImageDestinationFinalize(destination)
        }
        if suc && CFDataGetLength(data) > 0 {
            return data as Data
        } else {
            return nil
        }
    }
    
    private func _encodeWithImageIO(path: String) -> Bool {
        let count = type == .gif ? _images.count : 1
        let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
                                                          type.uiType!,
                                                          count,
                                                          nil)
        var suc = false
        if let destination = destination {
            _encodeImage(with: destination, imageCount: count)
            suc = CGImageDestinationFinalize(destination)
        }
        return suc
    }
    
    private func _encodeAPNG() -> Data? {
        var pngDatas = [NSData]()
        var pngSizes = [CGSize]()
        var canvasWidth = 0
        var canvasHeight = 0
        
        for i in 0..<_images.count {
            guard let decoded = _newCGImage(from: i, decoded: true) else { return nil }
            let size = CGSize(width: decoded.width, height: decoded.height)
            if size.width < 1 || size.height < 1 { return nil }
            pngSizes.append(size)
            if canvasWidth < decoded.width { canvasWidth = decoded.width }
            if canvasHeight < decoded.height { canvasHeight = decoded.height }
            guard let frameData = decoded.encodedData(type: .png, quality: 1) else { return nil }
            pngDatas.append(frameData)
        }
        
        let firstFrameSize = pngSizes.first!
        if firstFrameSize.width < CGFloat(canvasWidth) || firstFrameSize.height < CGFloat(canvasHeight) {
            guard let decoded = _newCGImage(from: 0, decoded: true) else { return nil }
            guard let context = CGContext(data: nil, width: canvasWidth, height: canvasHeight, bitsPerComponent: 8, bytesPerRow: 0, space: PoCGColorSpaceGetDeviceRGB, bitmapInfo: CGBitmapInfo.byteOrder32Host.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else { return nil }
            context.draw(decoded, in: CGRect(x: 0, y: CGFloat(canvasHeight) - firstFrameSize.height, width: firstFrameSize.width, height: firstFrameSize.height))
            guard let extendedImage = context.makeImage() else { return nil }
            guard let frameData = extendedImage.encodedData(type: .png, quality: 1) else { return nil }
            pngDatas[0] = frameData
        }
        
        let firstFrameData = pngDatas[0]
        guard let info = po_png_info_create(data: firstFrameData.bytes, length: firstFrameData.length) else { return nil }
        var result = Data()
        var insertBefore = false
        var insertAfter = false
        var apngSequenceIndex: UInt32 = 0
        
        let header = UnsafeMutablePointer<UInt32>.allocate(capacity: 2)
        header[0] = po_four_num(c1: 0x89, c2: 0x50, c3: 0x4E, c4: 0x47)
        header[1] = po_four_num(c1: 0x0D, c2: 0x0A, c3: 0x1A, c4: 0x0A)
        header.withMemoryRebound(to: UInt8.self, capacity: 8) { (pt) -> Void in
            result.append(pt, count: 8)
        }
        header.deallocate()
    
        
        for i in 0..<Int(info.pointee.chunk_num) {
            let chunk = info.pointee.chunks![i]
            
            if !insertBefore && chunk.fourcc == po_four_cc(c1: "I", c2: "D", c3: "A", c4: "T") { // IDAT
                insertBefore = true
                // insert acTL
                let acTL = UnsafeMutableRawPointer.allocate(byteCount: 20, alignment: MemoryLayout<UInt8>.stride)
                acTL.storeBytes(of: po_swap_endian_uint32(value: 8), toByteOffset: 0, as: UInt32.self) // length
                acTL.storeBytes(of: po_four_cc(c1: "a", c2: "c", c3: "T", c4: "L"), toByteOffset: 4, as: UInt32.self) // fourcc
                acTL.storeBytes(of: po_swap_endian_uint32(value: UInt32(pngDatas.count)), toByteOffset: 8, as: UInt32.self) // num frames
                acTL.storeBytes(of: po_swap_endian_uint32(value: UInt32(loopCount)), toByteOffset: 12, as: UInt32.self) // num plays
                acTL.storeBytes(of: po_swap_endian_uint32(value: UInt32(crc32(0, acTL.advanced(by: 4).assumingMemoryBound(to: UInt8.self), 12))), toByteOffset: 16, as: UInt32.self) // crc32
                result.append(acTL.assumingMemoryBound(to: UInt8.self), count: 20)
                acTL.deallocate()
                
                // insert fcTL
                var chunk_fcTL = po_png_chunk_fcTL()
                chunk_fcTL.sequence_number = apngSequenceIndex
                chunk_fcTL.width = UInt32(firstFrameSize.width)
                chunk_fcTL.height = UInt32(firstFrameSize.height)
                po_png_delay_to_fraction(duration: _durations[0], num: &chunk_fcTL.delay_num, den: &chunk_fcTL.delay_den)
                chunk_fcTL.dispose_op = po_png_dispose_op.background.rawValue
                chunk_fcTL.blend_op = po_png_blend_op.source.rawValue
                
                let fcTL = UnsafeMutableRawPointer.allocate(byteCount: 38, alignment: MemoryLayout<UInt8>.stride)
                fcTL.storeBytes(of: po_swap_endian_uint32(value: 26), toByteOffset: 0, as: UInt32.self) // length
                fcTL.storeBytes(of: po_four_cc(c1: "f", c2: "c", c3: "T", c4: "L"), toByteOffset: 4, as: UInt32.self) // fourcc
                po_png_chunk_fcTL_write(fcTL: &chunk_fcTL, data: fcTL.advanced(by: 8))
                fcTL.advanced(by: 34).assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: UInt32(crc32(0, fcTL.advanced(by: 4).assumingMemoryBound(to: UInt8.self), 30)))
                result.append(fcTL.assumingMemoryBound(to: UInt8.self), count: 38)
                fcTL.deallocate()
                
                apngSequenceIndex += 1
            }
            
            if !insertAfter && insertBefore && chunk.fourcc != po_four_cc(c1: "I", c2: "D", c3: "A", c4: "T") {
                insertAfter = true
                // insert fcTL and fdAT
                for i in 1..<pngDatas.count {
                    let frameData = pngDatas[i]
                    guard let frame = po_png_info_create(data: frameData.bytes, length: frameData.length) else {
                        po_png_info_release(info)
                        return nil
                    }
                    
                    // insert fcTL
                    var chunk_fcTL = po_png_chunk_fcTL()
                    chunk_fcTL.sequence_number = apngSequenceIndex
                    chunk_fcTL.width = frame.pointee.header.width
                    chunk_fcTL.height = frame.pointee.header.height
                    po_png_delay_to_fraction(duration: _durations[i], num: &chunk_fcTL.delay_num, den: &chunk_fcTL.delay_den)
                    chunk_fcTL.dispose_op = po_png_dispose_op.background.rawValue
                    chunk_fcTL.blend_op = po_png_blend_op.source.rawValue
                    
                    let fcTL = UnsafeMutableRawPointer.allocate(byteCount: 38, alignment: MemoryLayout<UInt8>.stride)
                    fcTL.storeBytes(of: po_swap_endian_uint32(value: 26), toByteOffset: 0, as: UInt32.self) // length
                    fcTL.storeBytes(of: po_four_cc(c1: "f", c2: "c", c3: "T", c4: "L"), toByteOffset: 4, as: UInt32.self) // fourcc
                    po_png_chunk_fcTL_write(fcTL: &chunk_fcTL, data: fcTL.advanced(by: 8))
                    
                    fcTL.advanced(by: 34).assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: UInt32(crc32(0, fcTL.advanced(by: 4).assumingMemoryBound(to: UInt8.self), 30)))
                    result.append(fcTL.assumingMemoryBound(to: UInt8.self), count: 38)
                    fcTL.deallocate()
                    
                    apngSequenceIndex += 1
                    
                    for d in 0..<Int(frame.pointee.chunk_num) {
                        let dchunk = frame.pointee.chunks![d]
                        if dchunk.fourcc == po_four_cc(c1: "I", c2: "D", c3: "A", c4: "T") {
                            let tmp = UnsafeMutableRawPointer.allocate(byteCount: 4, alignment: MemoryLayout<UInt8>.stride)
                            defer { tmp.deallocate() }
                            
                            tmp.storeBytes(of: po_swap_endian_uint32(value: dchunk.length + 4), as: UInt32.self) // length
                            result.append(tmp.assumingMemoryBound(to: UInt8.self), count: 4)
                            
                            tmp.storeBytes(of: po_four_cc(c1: "f", c2: "d", c3: "A", c4: "T"), as: UInt32.self) // fourcc
                            result.append(tmp.assumingMemoryBound(to: UInt8.self), count: 4)
                            
                            tmp.storeBytes(of: po_swap_endian_uint32(value: apngSequenceIndex), as: UInt32.self) // data (sq)
                            result.append(tmp.assumingMemoryBound(to: UInt8.self), count: 4)
                            
                            result.append(frameData.bytes.advanced(by: Int(dchunk.offset + 8)).assumingMemoryBound(to: UInt8.self), count: Int(dchunk.length)) // data
                            
                            let crc = result.withUnsafeBytes { (rpt) -> UInt32 in
                                let bytes = rpt.baseAddress!.advanced(by: result.count - Int(dchunk.length) - 8).assumingMemoryBound(to: UInt8.self)
                                return po_swap_endian_uint32(value: UInt32(crc32(0, bytes, dchunk.length + 8)))
                            }
                            tmp.storeBytes(of: crc, as: UInt32.self)
                            result.append(tmp.assumingMemoryBound(to: UInt8.self), count: 4) // crc
                            
                            apngSequenceIndex += 1
                        }
                    }
                    po_png_info_release(frame)
                }
            }
            
            result.append(firstFrameData.bytes.advanced(by: Int(chunk.offset)).assumingMemoryBound(to: UInt8.self), count: Int(chunk.length) + 12)
        }
        
        po_png_info_release(info)
        return result
    }
}
