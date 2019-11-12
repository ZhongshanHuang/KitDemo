//
//  PoImageDecoder.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/4/29.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class PoImageFrame: NSCopying {
    var index: Int = 0
    var width: Int = 0
    var height: Int = 0
    var offsetX: Int = 0
    var offsetY: Int = 0
    var duration: TimeInterval = 0
    var dispose: po_png_dispose_op = .none
    var blend: po_png_blend_op = .source
    var image: UIImage?
    
    required init(image: UIImage? = nil) {
        self.image = image
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let frame = type(of: self).init()
        frame.index = index
        frame.width = width
        frame.height = height
        frame.offsetX = offsetX
        frame.offsetY = offsetY
        frame.duration = duration
        frame.dispose = dispose
        frame.blend = blend
        frame.image = image
        return frame
    }
}

private final class _PoImageDecoderFrame: PoImageFrame {
    
    /// whether frame has alpha
    var hasAlpha: Bool = false
    
    /// whether frame fill the canvas
    var isFullSize: Bool = false
    
    /// blend from frame index to current frame
    var blendFromIndex: Int = 0
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let frame = super.copy(with: zone) as! _PoImageDecoderFrame
        frame.hasAlpha = hasAlpha
        frame.isFullSize = isFullSize
        frame.blendFromIndex = blendFromIndex
        return frame
    }
}

extension PoImageDecoder {
    enum DecoderError: Error {
        case invalidData
    }
}

final class PoImageDecoder {
    
    // MARK: - Properties - [public]
    
    private(set) var data: NSData?
    private(set) var type: PoImageType = .unknown
    private(set) var scale: CGFloat = 0
    private(set) var frameCount: Int = 0
    private(set) var loopCount: Int = 0
    private(set) var width: Int = 0
    private(set) var height: Int = 0
    private(set) var isFinalized: Bool = false
    
    // MARK: - Properties - [private]
    
    private var _lock: pthread_mutex_t = pthread_mutex_t()
    private var _sourceTypeDetected: Bool = false
    private var _source: CGImageSource?
    private var _apngSource: UnsafeMutablePointer<po_png_info>?
    private var _orientation: UIImage.Orientation = .up
    private lazy var _framesLock: DispatchSemaphore = DispatchSemaphore(value: 1)
    private lazy var _frames: [_PoImageDecoderFrame] = []
    private var _isNeededBlend: Bool = false
    private var _blendFrameIndex: Int = 0
    private var _blendCanvas: CGContext?
    
    // MARK: - Initializers
    
    init(scale: CGFloat = UIScreen.main.scale) {
        if scale <= 0 { self.scale = 1 }
        else { self.scale = scale }
        
        var mutexattr = pthread_mutexattr_t()
        pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&_lock, &mutexattr)
        pthread_mutexattr_destroy(&mutexattr)
    }
    
    static func decoder(with data: NSData, scale: CGFloat) throws -> PoImageDecoder {
        let decoder = PoImageDecoder(scale: scale)
        decoder.update(data, final: true)
        if decoder.frameCount == 0 { throw DecoderError.invalidData }
        return decoder
    }
    
    deinit {
        pthread_mutex_destroy(&_lock)
        if _apngSource != nil { po_png_info_release(_apngSource!) }
    }
    
    // MARK: - Methods
    
    /**
     Updates the incremental image with new data.
     
     @discussion You can use this method to decode progressive/interlaced/baseline
     image when you do not have the complete image data. The `data` was retained by
     decoder, you should not modify the data in other thread during decoding.
     
     @param data  The data to add to the image decoder. Each time you call this
     function, the 'data' parameter must contain all of the image file data
     accumulated so far.
     
     @param final  A value that specifies whether the data is the final set.
     Pass YES if it is, NO otherwise. When the data is already finalized, you can
     not update the data anymore.
     
     @return Whether succeed.
     */
    
    @discardableResult
    func update(_ data: NSData, final: Bool) -> Bool {
        var result = false
        pthread_mutex_lock(&_lock)
        result = _update(data, final: final)
        pthread_mutex_unlock(&_lock)
        return result
    }
    
    /**
     Decodes and returns a frame from a specified index.
     @param index  Frame image index (zero-based).
     @param decodeForDisplay Whether decode the image to memory bitmap for display.
     If NO, it will try to returns the original frame data without blend.
     @return A new frame with image, or nil if an error occurs.
     */
    func frame(at index: Int, decodeForDisplay: Bool) -> PoImageFrame? {
        var result: PoImageFrame?
        pthread_mutex_lock(&_lock)
        result = _frame(at: index, decodeForDisplay: decodeForDisplay)
        pthread_mutex_unlock(&_lock)
        return result
    }
    
    /**
     Returns the frame duration from a specified index.
     @param index  Frame image (zero-based).
     @return Duration in seconds.
     */
    func frameDuration(at index: Int) -> TimeInterval {
        var result: TimeInterval = 0
        _ = _framesLock.wait(timeout: .distantFuture)
        if index < _frames.count {
            result = _frames[index].duration
        }
        _framesLock.signal()
        return result
    }
    
    /**
     Returns the frame's properties. See "CGImageProperties.h" in ImageIO.framework
     for more information.
     
     @param index  Frame image index (zero-based).
     @return The ImageIO frame property.
     */
    func frameProperties(at index: Int) -> Dictionary<CFString, Any>? {
        var result: Dictionary<CFString, Any>?
        pthread_mutex_lock(&_lock)
        result = _frameProperties(at: index)
        pthread_mutex_unlock(&_lock)
        return result
    }
    
    /**
     Returns the image's properties. See "CGImageProperties.h" in ImageIO.framework
     for more information.
     */
    var imageProperties: Dictionary<CFString, Any>? {
        var result: Dictionary<CFString, Any>?
        pthread_mutex_lock(&_lock)
        result = _imageProperties()
        pthread_mutex_unlock(&_lock)
        return result
    }
    
    
    // MARK: - Helper
    
    /// 防止Data的写时复制产生的副作用，所以采用NSData
    private func _update(_ data: NSData, final: Bool) -> Bool {
        if isFinalized { return false }
        if self.data != nil && data.count < self.data!.count {
            return false
        }
        isFinalized = final
        self.data = data
        
        let imageType = PoImageDetectType(data: data)
        if _sourceTypeDetected {
            if imageType != type {
                return false
            } else {
                _updateSource()
            }
        } else {
            if data.count > 16 {
                type = imageType
                _sourceTypeDetected = true
                _updateSource()
            }
        }
        return true
    }
    
    private func _frame(at index: Int, decodeForDisplay: Bool) -> PoImageFrame? {
        if index >= _frames.count { return nil }
        let frame = _frames[index].copy() as! _PoImageDecoderFrame
        var decoded = false
        var extendToCanvas = false
        if type != .ico && decodeForDisplay { // ICO contains multi-size frame and should not extend to canvas.
            extendToCanvas = true
        }
        
        if !_isNeededBlend {
            guard var imageRef = _newUnblendedImage(at: index, extendToCanvas: extendToCanvas, decoded: &decoded) else { return nil }
            if decodeForDisplay && !decoded {
                if let imageRefDecoded = imageRef.copy(decodeForDispaly: true) {
                    imageRef = imageRefDecoded
                    decoded = true
                }
            }
            let image = UIImage(cgImage: imageRef, scale: scale, orientation: _orientation)
            image.isDecodedForDisplay = decoded
            frame.image = image
            return frame
        }
        
        // blend
        if !_createBlendContextIfNeeded() { return nil }
        var imageRef: CGImage?
        
        if _blendFrameIndex != NSNotFound && _blendFrameIndex + 1 == frame.index {
            imageRef = _newBlendedImage(with: frame)
            _blendFrameIndex = index
        } else { // should draw canvas from previous frame
            _blendFrameIndex = NSNotFound
            _blendCanvas?.clear(CGRect(x: 0, y: 0, width: self.width, height: self.height))
            
            if frame.blendFromIndex == frame.index {
                if let unblendImage = _newUnblendedImage(at: index, extendToCanvas: false, decoded: nil) {
                    _blendCanvas?.draw(unblendImage, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
                imageRef = _blendCanvas?.makeImage()
                if frame.dispose == .background {
                    _blendCanvas?.clear(CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
                _blendFrameIndex = index
            } else { // canvas is not ready
                for i in frame.blendFromIndex...frame.index {
                    if i == frame.index {
                        if imageRef == nil { imageRef = _newBlendedImage(with: frame) }
                    } else {
                        _blendImage(with: _frames[i])
                    }
                }
                _blendFrameIndex = index
            }
        }
        if imageRef == nil { return nil }
        let image = UIImage(cgImage: imageRef!, scale: scale, orientation: _orientation)
        image.isDecodedForDisplay = true
        frame.image = image
        if extendToCanvas {
            frame.width = width
            frame.height = height
            frame.offsetX = 0
            frame.offsetY = 0
            frame.dispose = .none
            frame.blend = .source
         }
        return frame
    }
    
    private func _frameProperties(at index: Int) -> Dictionary<CFString, Any>? {
        if index >= _frames.count { return nil }
        if _source == nil { return nil }
        let properties = CGImageSourceCopyPropertiesAtIndex(_source!, index, nil)
        return properties as? Dictionary<CFString, Any>
    }
    
    private func _imageProperties() -> Dictionary<CFString, Any>? {
        if _source == nil { return nil }
        let properties = CGImageSourceCopyProperties(_source!, nil)
        return properties as? Dictionary<CFString, Any>
    }
    
    private func _updateSource() {
        switch type {
        case .png:
            _updateSourceAPNG()
        default:
            _updateSourceImageIO()
        }
    }
    
    private func _updateSourceAPNG() {
        /*
         APNG extends PNG format to support animation, it was supported by ImageIO
         since iOS 8.
         
         We use a custom APNG decoder to make APNG available in old system, so we
         ignore the ImageIO's APNG frame info. Typically the custom decoder is a bit
         faster than ImageIO.
         */
        if _apngSource != nil { // 数据不一定已经加载完成，所以需要重新解析，将之前的数据释放
            po_png_info_release(_apngSource!)
            _apngSource = nil
        }
        
        _updateSourceImageIO() // decode first frame
        if frameCount == 0 { return } // png decode failed or only one pic
        if !isFinalized { return } // ignore multi-frame before finalized
        
        guard let apng = po_png_info_create(data: data!.bytes, length: data!.length) else { return }
        if apng.pointee.apng_frame_num == 0 || (apng.pointee.apng_frame_num == 1 && apng.pointee.apng_first_frame_is_cover) {
            po_png_info_release(apng)
            return // no animation
        }
        if _source != nil { // apng decode succeed, no longer need image source
            _source = nil
        }
        
        let canvasWidth = apng.pointee.header.width
        let canvasHeight = apng.pointee.header.height
        var frames = [_PoImageDecoderFrame]()
        var needBlend = false
        var lastBlendIndex = 0
        for i in 0..<Int(apng.pointee.apng_frame_num) {
            let frame = _PoImageDecoderFrame()
            frames.append(frame)
            
            let fi = apng.pointee.apng_frames!.advanced(by: i)
            frame.index = i
            frame.duration = po_png_delay_to_seconds(num: fi.pointee.frame_control.delay_num, den: fi.pointee.frame_control.delay_den)
            frame.hasAlpha = true
            frame.width = Int(fi.pointee.frame_control.width)
            frame.height = Int(fi.pointee.frame_control.height)
            frame.offsetX = Int(fi.pointee.frame_control.x_offset)
            frame.offsetY = Int(canvasHeight - fi.pointee.frame_control.y_offset - fi.pointee.frame_control.height)
            
            let sizeEqualsToCanvas = frame.width == canvasWidth && frame.height == canvasHeight
            let offsetIsZero = fi.pointee.frame_control.x_offset == 0 && fi.pointee.frame_control.y_offset == 0
            frame.isFullSize = sizeEqualsToCanvas && offsetIsZero
            
            // (0:none, 1:background 2:previous)
            switch fi.pointee.frame_control.dispose_op {
            case po_png_dispose_op.background.rawValue:
                frame.dispose = .background
            case po_png_dispose_op.previous.rawValue:
                frame.dispose = .previous
            default:
                frame.dispose = .none
            }
            
            // 0:source, 1: over
            switch fi.pointee.frame_control.blend_op {
            case po_png_blend_op.over.rawValue:
                frame.blend = .over
            default:
                frame.blend = .source
            }
            
            if frame.blend == .source && frame.isFullSize {
                frame.blendFromIndex = Int(i)
                if frame.dispose != .previous { lastBlendIndex = i }
            } else {
                if frame.dispose == .background && frame.isFullSize {
                    frame.blendFromIndex = lastBlendIndex
                    lastBlendIndex += 1
                } else {
                    frame.blendFromIndex = lastBlendIndex
                }
            }
            if frame.index != frame.blendFromIndex { needBlend = true }
        }
        
        self.width = Int(canvasWidth)
        self.height = Int(canvasHeight)
        self.frameCount = frames.count
        self.loopCount = Int(apng.pointee.apng_loop_num)
        self._isNeededBlend = needBlend
        self._apngSource = apng
        _ = _framesLock.wait(timeout: .distantFuture)
        self._frames = frames
        _framesLock.signal()
    }
    
    private func _updateSourceImageIO() {
        self.width = 0
        self.height = 0
        self._orientation = .up
        self.loopCount = 0
        _ = _framesLock.wait(timeout: .distantFuture)
        _frames = []
        _framesLock.signal()
        
        if _source == nil {
            if isFinalized {
                _source = CGImageSourceCreateWithData(data! as CFData, nil)
            } else {
                _source = CGImageSourceCreateIncremental(nil)
                if _source != nil { CGImageSourceUpdateData(_source!, data!, false) }
            }
        } else {
            CGImageSourceUpdateData(_source!, data!, isFinalized)
        }
        
        guard let source1 = _source else { return }
        
        frameCount = CGImageSourceGetCount(_source!)
        
        if frameCount == 0 { return }
        
        if !isFinalized { // ignore multi-frame before finalized
            frameCount = 1
        } else {
            if type == .png { // use custom apng decoder and ignore multi-frame
                frameCount = 1
            }
            if type == .gif { // get gif loop count
                if let properties = CGImageSourceCopyProperties(source1, nil) as? Dictionary<CFString, Any>,
                    let gif = properties[kCGImagePropertyGIFDictionary] as? Dictionary<CFString, Any>,
                    let loop = gif[kCGImagePropertyGIFLoopCount] as? Int {
                    loopCount = loop
                }
            }
        }
        
        /*
         ICO, GIF, APNG may contains multi-frame.
         */
        var frames = [_PoImageDecoderFrame]()
        for i in 0..<frameCount {
            let frame = _PoImageDecoderFrame()
            frame.index = i
            frame.blendFromIndex = i
            frame.hasAlpha = true
            frame.isFullSize = true
            frames.append(frame)
            
            if let properties = CGImageSourceCopyPropertiesAtIndex(source1, i, nil) as? Dictionary<CFString, Any> {
                var duration: TimeInterval = 0
                let width = properties[kCGImagePropertyPixelWidth] as! Int
                let height = properties[kCGImagePropertyPixelHeight] as! Int
                if type == .gif, let gif = properties[kCGImagePropertyGIFDictionary] as? Dictionary<CFString, Any> {
                    if let value = gif[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval {
                        duration = value
                    } else if let value = gif[kCGImagePropertyGIFDelayTime] as? TimeInterval {
                        duration = value
                    }
                }
                
                frame.width = width
                frame.height = height
                frame.duration = duration
                
                if i == 0 && self.width + self.height == 0 { // init first frame
                    self.width = width
                    self.height = height
                    if let value = properties[kCGImagePropertyOrientation] as? Int {
                        self._orientation = PoUIImageOrientationFromEXITValue(value)
                    }
                }
            }
        }
        
        _ = _framesLock.wait(timeout: .distantFuture)
        self._frames = frames
        _framesLock.signal()
    }
    
    private func _createBlendContextIfNeeded() -> Bool {
        if _blendCanvas == nil {
            _blendFrameIndex = NSNotFound
            _blendCanvas = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: PoCGColorSpaceGetDeviceRGB, bitmapInfo: CGBitmapInfo.byteOrder32Host.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        }
        return _blendCanvas != nil
    }
    
    private func _newUnblendedImage(at index: Int, extendToCanvas: Bool, decoded: UnsafeMutablePointer<Bool>?) -> CGImage? {
        if !isFinalized && index > 0 { return nil }
        if _frames.count <= index { return nil }
        let frame = _frames[index]
        
        if let source = _source {
            var imageRef = CGImageSourceCreateImageAtIndex(source, index, [kCGImageSourceShouldCache: true] as CFDictionary)
            if imageRef != nil, extendToCanvas {
                let width = imageRef!.width
                let height = imageRef!.height
                if self.width == width && self.height == height {
                    if let imageRefExtended = imageRef?.copy(decodeForDispaly: true) {
                        imageRef = imageRefExtended
                        decoded?.pointee = true
                    }
                } else {
                    if let context = CGContext(data: nil, width: self.width, height: self.height, bitsPerComponent: 8, bytesPerRow: 0, space: PoCGColorSpaceGetDeviceRGB, bitmapInfo: CGBitmapInfo.byteOrder32Host.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) {
                        context.draw(imageRef!, in: CGRect(x: 0, y: self.height - height, width: width, height: height))
                        if let imageRefExtended = context.makeImage() {
                            imageRef = imageRefExtended
                            decoded?.pointee = true
                        }
                        
                    }
                }
            }
            return imageRef
        }
        
        if _apngSource != nil {
            var size: Int = 0
            if let bytes = po_png_copy_frame_data_at_index(data: data!.bytes.assumingMemoryBound(to: UInt8.self), info: _apngSource!, index: index, size: &size) {
                guard let provider = CGDataProvider(dataInfo: bytes, data: bytes, size: size, releaseData: PoCGDataProviderReleaseDataCallback) else {
                    bytes.deallocate()
                    return nil
                }
                
                guard let sourcel = CGImageSourceCreateWithDataProvider(provider, nil), CGImageSourceGetCount(sourcel) > 0 else { return nil }
                guard let imageRef = CGImageSourceCreateImageAtIndex(sourcel, 0, [kCGImageSourceShouldCache: true] as CFDictionary) else { return nil }
                if extendToCanvas, let context = CGContext(data: nil, width: self.width, height: self.height, bitsPerComponent: 8, bytesPerRow: 0, space: PoCGColorSpaceGetDeviceRGB, bitmapInfo: CGBitmapInfo.byteOrder32Host.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) {
                    context.draw(imageRef, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                    decoded?.pointee = true
                    return context.makeImage()
                }
                return imageRef
            }
            return nil
        }
    
        return nil
    }
    
    private func _blendImage(with frame: _PoImageDecoderFrame) {
        if frame.dispose == .previous {
            // nothing
        } else if frame.dispose == .background {
            _blendCanvas?.clear(CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
        } else { // no dispose
            if frame.blend == .over {
                let unblendImage = _newUnblendedImage(at: frame.index, extendToCanvas: false, decoded: nil)
                if unblendImage != nil {
                    _blendCanvas?.draw(unblendImage!, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
            } else {
                _blendCanvas?.clear(CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                let unblendImage = _newUnblendedImage(at: frame.index, extendToCanvas: false, decoded: nil)
                if unblendImage != nil {
                    _blendCanvas?.draw(unblendImage!, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
            }
        }
    }
    
    private func _newBlendedImage(with frame: _PoImageDecoderFrame) -> CGImage? {
        var cgImage: CGImage?
        if frame.dispose == .previous { // 显示完当前帧后，将画板恢复到当前帧的前一帧
            if frame.blend == .over { // 在前一帧的基础上画上当前帧
                let previousImage = _blendCanvas?.makeImage()
                let unblendImage = _newUnblendedImage(at: frame.index, extendToCanvas: false, decoded: nil)
                if unblendImage != nil {
                    _blendCanvas?.draw(unblendImage!, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
                cgImage = _blendCanvas?.makeImage()
                _blendCanvas?.clear(CGRect(x: 0, y: 0, width: width, height: height))
                if previousImage != nil {
                    _blendCanvas?.draw(previousImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
                }
            } else { // 在要画上当前帧的范围内先清除，然后再画上当前帧
                let previousImage = _blendCanvas?.makeImage()
                let unblendImage = _newUnblendedImage(at: frame.index, extendToCanvas: false, decoded: nil)
                if unblendImage != nil {
                    _blendCanvas?.clear(CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                    _blendCanvas?.draw(unblendImage!, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
                cgImage = _blendCanvas?.makeImage()
                _blendCanvas?.clear(CGRect(x: 0, y: 0, width: width, height: height))
                if previousImage != nil {
                    _blendCanvas?.draw(previousImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
                }
            }
        } else if frame.dispose == .background { // 画完当前帧显示后，将当前帧的范围清除
            if frame.blend == .over {
                let unblendImage = _newUnblendedImage(at: frame.index, extendToCanvas: false, decoded: nil)
                if unblendImage != nil {
                    _blendCanvas?.draw(unblendImage!, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
                cgImage = _blendCanvas?.makeImage()
                _blendCanvas?.clear(CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
            } else {
                let unblendImage = _newUnblendedImage(at: frame.index, extendToCanvas: false, decoded: nil)
                if unblendImage != nil {
                    _blendCanvas?.clear(CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                    _blendCanvas?.draw(unblendImage!, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
                cgImage = _blendCanvas?.makeImage()
                _blendCanvas?.clear(CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
            }
            
        } else { // no dispose
            if frame.blend == .over {
                let unblendImage = _newUnblendedImage(at: frame.index, extendToCanvas: false, decoded: nil)
                if unblendImage != nil {
                    _blendCanvas?.draw(unblendImage!, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
                cgImage = _blendCanvas?.makeImage()
            } else {
                let unblendImage = _newUnblendedImage(at: frame.index, extendToCanvas: false, decoded: nil)
                if unblendImage != nil {
                    _blendCanvas?.clear(CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                    _blendCanvas?.draw(unblendImage!, in: CGRect(x: frame.offsetX, y: frame.offsetY, width: frame.width, height: frame.height))
                }
                cgImage = _blendCanvas?.makeImage()
            }
        }
        return cgImage
    }
}
