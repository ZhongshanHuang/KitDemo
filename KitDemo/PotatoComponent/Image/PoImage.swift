//
//  PoImage.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/5/16.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

/**
 A YYImage object is a high-level way to display animated image data.
 
 @discussion It is a fully compatible `UIImage` subclass. It extends the UIImage
 to support animated WebP, APNG and GIF format image data decoding. It also
 support NSCoding protocol to archive and unarchive multi-frame image data.
 
 If the image is created from multi-frame image data, and you want to play the
 animation, try replace UIImageView with `YYAnimatedImageView`.
 
 Sample Code:
 
 // animation@3x.webp
 YYImage *image = [YYImage imageNamed:@"animation.webp"];
 YYAnimatedImageView *imageView = [YYAnimatedImageView alloc] initWithImage:image];
 [view addSubView:imageView];
 
 */

class PoImage: UIImage {
    
    // MARK: - Properties
    private(set) var animatedImageType: PoImageType = .unknown
    private(set) var animatedImageMemorySize: Int = 0
    var animatedImageData: NSData? {
        return _decoder?.data
    }
    var preloadAllAnimatedImageFrames: Bool = false {
        didSet {
            if preloadAllAnimatedImageFrames == oldValue { return }
            
            if preloadAllAnimatedImageFrames && _decoder != nil && _decoder!.frameCount > 0 {
                var frames = [UIImage]()
                for i in 0..<_decoder!.frameCount {
                    if let img = animatedImageFrame(at: i) {
                        frames.append(img)
                    }
                }
                _ = _preloadedLock.wait(timeout: .distantFuture)
                preloadedFrames = frames
                _preloadedLock.signal()
            } else {
                _ = _preloadedLock.wait(timeout: .distantFuture)
                preloadedFrames = nil
                _preloadedLock.signal()
            }
        }
    }
    
    private var _decoder: PoImageDecoder?
    private var preloadedFrames: [UIImage]?
    private var _preloadedLock: DispatchSemaphore = DispatchSemaphore(value: 1)
    private var _bytesPerFrame: Int = 0
    
    // MARK: - Initializers
    
    convenience init?(named name: String, bundle: Bundle = .main) {
        if name.isEmpty { return nil }
        if name.hasSuffix("/") { return nil }
        
        let res = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var path: String?
        var scale = 1
        
        // If no extension, guess by system supported (same as UIImage).
        let exts = ext.isEmpty ? ["", "png", "jpeg", "jpg", "gif", "webp", "apng"] : [ext]
        for s in Bundle.preferredScales {
            scale = s
            let scaleName = res.appendingNameScale(scale)
            for e in exts {
                path = bundle.path(forResource: scaleName, ofType: e)
                if path != nil { break }
            }
            if path != nil { break }
        }
        
        if path.isEmpty { return nil }
        
        let data = try? Data(contentsOf: URL(fileURLWithPath: path!))
        if data.isEmpty { return nil }
        
        self.init(data: data!, scale: CGFloat(scale))
    }
    
    override convenience init?(contentsOfFile path: String) {
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        self.init(data: data!, scale: path.pathScale())
    }
    
    override convenience init?(data: Data) {
        self.init(data: data, scale: 1)
    }
    
    convenience override init?(data: Data, scale: CGFloat) {
        if data.isEmpty { return nil }
        var scale = scale
        if scale <= 0 { scale = UIScreen.main.scale }
        
        guard let decoder = try? PoImageDecoder.decoder(with: data as NSData, scale: scale), let image = decoder.frame(at: 0, decodeForDisplay: true)?.image else { return nil }
        
        self.init(cgImage: image.cgImage!, scale: decoder.scale, orientation: image.imageOrientation)
        self.animatedImageType = decoder.type
        if decoder.frameCount > 1 {
            self._decoder = decoder
            self._bytesPerFrame = image.cgImage!.bytesPerRow * image.cgImage!.height
            self.animatedImageMemorySize = self._bytesPerFrame * decoder.frameCount
        }
        self.isDecodedForDisplay = true
    }
    
    override init() {
        super.init()
    }
    
    override init(cgImage: CGImage) {
        super.init(cgImage: cgImage)
    }
    
    override init(cgImage: CGImage, scale: CGFloat, orientation: UIImage.Orientation) {
        super.init(cgImage: cgImage, scale: scale, orientation: orientation)
    }
    
    override init(ciImage: CIImage) {
        super.init(ciImage: ciImage)
    }
    
    override init(ciImage: CIImage, scale: CGFloat, orientation: UIImage.Orientation) {
        super.init(ciImage: ciImage, scale: scale, orientation: orientation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


// MARK: - PoAnimatable
extension PoImage: PoAnimatable {
    
    var animatedImageFrameCount: Int {
        return _decoder?.frameCount ?? NSNotFound
    }
    
    var animatedImageLoopCount: Int {
        return _decoder?.loopCount ?? NSNotFound
    }
    
    var animatedImageBytesPerFrame: Int {
        return _bytesPerFrame
    }
    
    func animatedImageFrame(at index: Int) -> UIImage? {
        guard let _decoder = _decoder, index < _decoder.frameCount else { return nil }
        
        _ = _preloadedLock.wait(timeout: .distantFuture)
        let image = preloadedFrames?[index]
        _preloadedLock.signal()
        if image != nil { return image }
        
        return _decoder.frame(at: index, decodeForDisplay: true)?.image
    }
    
    func animatedImageDuration(at index: Int) -> TimeInterval {
        /*
         http://opensource.apple.com/source/WebCore/WebCore-7600.1.25/platform/graphics/cg/ImageSourceCG.cpp
         Many annoying ads specify a 0 duration to make an image flash as quickly as
         possible. We follow Safari and Firefox's behavior and use a duration of 100 ms
         for any frames that specify a duration of <= 10 ms.
         See <rdar://problem/7689300> and <http://webkit.org/b/36082> for more information.
         
         See also: http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser.
         */
        let duration = _decoder?.frameDuration(at: index) ?? 0
        if duration < 0.011 { return 0.1 }
        return duration
    }
    
    
}
