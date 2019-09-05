//
//  PoAnimatedImageView.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/5/24.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

// MARK: - PoAnimatable

protocol PoAnimatable: class {
    /// Total animated frame count.
    /// If the frame count is less than 1, then the methods below will be ignored.
    var animatedImageFrameCount: Int { get }
    
    /// Animation loop count, 0 means infinite looping.
    var animatedImageLoopCount: Int { get }
    
    /// Bytes per frame (in memory). It may used to optimize memory buffer size.
    var animatedImageBytesPerFrame: Int { get }
    
    /// Returns the frame image from a specified index.
    /// This method may be called on background thread.
    /// @param index  Frame index (zero based).
    func animatedImageFrame(at index: Int) -> UIImage?
    
    /// Returns the frames's duration from a specified index.
    /// @param index  Frame index (zero based).
    func animatedImageDuration(at index: Int) -> TimeInterval
}


// MARK: - PoAnimatedImageView

extension PoAnimatedImageView {
    
    enum AnimatedImageType {
        case none
        case image
        case highlightedImage
        case images
        case highlightedImages
    }
}

private let kBufferSize = 10 * 1024 * 1024 // 10MB

/**
 An image view for displaying animated image.
 
 @discussion It is a fully compatible `UIImageView` subclass.
 If the `image` or `highlightedImage` property adopt to the `YYAnimatedImage` protocol,
 then it can be used to play the multi-frame animation. The animation can also be
 controlled with the UIImageView methods `-startAnimating`, `-stopAnimating` and `-isAnimating`.
 
 This view request the frame data just in time. When the device has enough free memory,
 this view may cache some or all future frames in an inner buffer for lower CPU cost.
 Buffer size is dynamically adjusted based on the current state of the device memory.
 
 Sample Code:
 
 // ani@3x.gif
 YYImage *image = [YYImage imageNamed:@"ani"];
 YYAnimatedImageView *imageView = [YYAnimatedImageView alloc] initWithImage:image];
 [view addSubView:imageView];
 */

class PoAnimatedImageView: UIImageView {
    
    // MARK: - Properties - [public]
    
    /**
     If the image has more than one frame, set this value to `YES` will automatically
     play/stop the animation when the view become visible/invisible.
     
     The default value is `YES`.
     */
    var autoPlayAnimatedImage: Bool = true
    
    /**
     Index of the currently displayed frame (index from 0).
     
     Set a new value to this property will cause to display the new frame immediately.
     If the new value is invalid, this method has no effect.
     
     You can add an observer to this property to observe the playing status.
     */
    var currentAnimatedImageIndex: Int = 0 {
        didSet {
            if _curAnimatedImage == nil { return }
            if currentAnimatedImageIndex >= _curAnimatedImage!.animatedImageFrameCount { return }
            if _curIndex == currentAnimatedImageIndex { return }
            
            Dispatch_async_on_main_queue {
                _ = self._lock.wait(timeout: .distantFuture)
                defer { self._lock.signal() }
                
                self._requestQueue?.cancelAllOperations()
                self._buffer.removeAll()
                self.willChangeValue(forKey: "currentAnimatedImageIndex")
                self._curIndex = self.currentAnimatedImageIndex
                self.didChangeValue(forKey: "currentAnimatedImageIndex")
                self._curFrame = self._curAnimatedImage?.animatedImageFrame(at: self._curIndex)
                self._time = 0
                self._isLoopEnd = false
                self._bufferMiss = false
                self.layer.setNeedsDisplay()
            }
        }
    }
    
    /**
     Whether the image view is playing animation currently.
     
     You can add an observer to this property to observe the playing status.
     */
    private(set) var currentIsPlayingAnimation: Bool = false
    
    /**
     The animation timer's runloop mode, default is `NSRunLoopCommonModes`.
     
     Set this property to `NSDefaultRunLoopMode` will make the animation pause during
     UIScrollView scrolling.
     */
    var runloopMode: RunLoop.Mode = .common {
        didSet {
            if runloopMode == oldValue { return }
            if _link != nil {
                _link?.remove(from: RunLoop.main, forMode: oldValue)
                _link?.add(to: RunLoop.main, forMode: runloopMode)
            }
        }
    }
    
    /**
     The max size (in bytes) for inner frame buffer size, default is 0 (dynamically).
     
     When the device has enough free memory, this view will request and decode some or
     all future frame image into an inner buffer. If this property's value is 0, then
     the max buffer size will be dynamically adjusted based on the current state of
     the device free memory. Otherwise, the buffer size will be limited by this value.
     
     When receive memory warning or app enter background, the buffer will be released
     immediately, and may grow back at the right time.
     */
    var maxBufferSize: Int = 0
    
    // MARK: - Properties - [private]
    
    fileprivate var _lock: DispatchSemaphore!
    private var _requestQueue: OperationQueue?
    
    private var _link: CADisplayLink?
    private var _time: TimeInterval = 0
    
    private var _curAnimatedImage: (UIImage & PoAnimatable)?
    private var _curFrame: UIImage?
    private var _curIndex: Int = 0
    fileprivate var _totalFrameCount: Int = 0

    private var _curLoop: Int = 0
    private var _totalLoop: Int = 0
    private var _isLoopEnd: Bool = false
    fileprivate var _buffer: Dictionary<Int, UIImage>!
    private var _bufferMiss: Bool = false
    fileprivate var _maxBufferCount: Int = 0
    fileprivate var _incrBufferCount: Int = 0
    
    override var image: UIImage? {
        get { return super.image }
        set {
            if newValue === image { return }
            setImage(newValue, withType: .image)
        }
    }
    
    override var highlightedImage: UIImage? {
        get { return super.highlightedImage }
        set {
            if newValue === highlightedImage { return }
            setImage(highlightedImage, withType: .highlightedImage)
        }
    }
    
    override var animationImages: [UIImage]? {
        get { return super.animationImages }
        set {
            if newValue == animationImages { return }
            setImage(animationImages, withType: .images)
        }
    }
    
    override var highlightedAnimationImages: [UIImage]? {
        get { return super.highlightedAnimationImages }
        set {
            if newValue == highlightedAnimationImages { return }
            setImage(highlightedAnimationImages, withType: .highlightedImages)
        }
    }
    
    override var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            if newValue == isHighlighted { return }
            super.isHighlighted = newValue
            if _link != nil { resetAnimated() }
            imageChanged()
        }
    }
    
    override var isAnimating: Bool {
        return currentIsPlayingAnimation
    }
    
    override func startAnimating() {
        let type = currentImageType()
        if type == .images || type == .highlightedImages {
            let images = image(for: type) as! [UIImage]
            if !images.isEmpty {
                super.startAnimating()
                currentIsPlayingAnimation = true
            }
        } else {
            if _curAnimatedImage != nil && _link?.isPaused == true {
                _curLoop = 0
                _isLoopEnd = false
                _link?.isPaused = false
                currentIsPlayingAnimation = true
            }
        }
    }
    
    override func stopAnimating() {
        super.stopAnimating()
        _requestQueue?.cancelAllOperations()
        _link?.isPaused = true
        currentIsPlayingAnimation = false
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        didMoved()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        didMoved()
    }
    
    private func didMoved() {
        if autoPlayAnimatedImage {
            if self.superview != nil && self.window != nil {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
    
    // MARK: - Initializers
        
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init(image: UIImage?) {
        let rect = CGRect(origin: .zero, size: image?.size ?? .zero)
        super.init(frame: rect)
        self.image = image
    }
    
    override init(image: UIImage?, highlightedImage: UIImage?) {
        var size = CGSize.zero
        if image != nil {
            size = image!.size
        } else if highlightedImage != nil {
            size = highlightedImage!.size
        }
        super.init(frame: CGRect(origin: .zero, size: size))
        self.image = image
        self.highlightedImage = highlightedImage
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        _requestQueue?.cancelAllOperations()
        _link?.invalidate()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    // MARK: - Helper
    
    private func resetAnimated() {
        if _link == nil {
            _lock = DispatchSemaphore(value: 1)
            _buffer = [:]
            _requestQueue = OperationQueue()
            _requestQueue?.maxConcurrentOperationCount = 1
            
            let proxy = PoWeakProxy(target: self)
            _link = CADisplayLink(target: proxy, selector: #selector(step(_:)))
            _link?.add(to: RunLoop.main, forMode: runloopMode)
            _link?.isPaused = true
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didReceiveMemoryWarning(_:)),
                                                   name: UIApplication.didReceiveMemoryWarningNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didEnterBackground(_:)),
                                                   name: UIApplication.didEnterBackgroundNotification,
                                                   object: nil)
        }
        
        _requestQueue?.cancelAllOperations()
        
        _ = _lock.wait(timeout: .distantFuture)
        if !_buffer.isEmpty {
            let holder = _buffer
            _buffer = [:]
            DispatchQueue.global(qos: .utility).async {
                // Capture the dictionary to global queue,
                // release these images in background to avoid blocking UI thread.
                _ = holder?.description
            }
        }
        _lock.signal()
        
        _link?.isPaused = true
        _time = 0
        if _curIndex != 0 {
            self.willChangeValue(forKey: "currentAnimatedImageIndex")
            _curIndex = 0
            self.didChangeValue(forKey: "currentAnimatedImageIndex")
        }
        _curAnimatedImage = nil
        _curFrame = nil
        _curLoop = 0
        _totalLoop = 0
        _totalFrameCount = 1
        _isLoopEnd = false
        _bufferMiss = false
        _incrBufferCount = 0
    }
    
    private func image(for type: AnimatedImageType) -> Any? {
        switch type {
        case .none:
            return nil
        case .image:
            return self.image
        case .highlightedImage:
            return self.highlightedImage
        case .images:
            return self.animationImages
        case .highlightedImages:
            return self.highlightedAnimationImages
        }
    }
    
    func currentImageType() -> AnimatedImageType {
        var curType = AnimatedImageType.none
        if self.isHighlighted {
            if self.highlightedAnimationImages?.isEmpty == false {
                curType = .highlightedImages
            } else if self.highlightedImage != nil {
                curType = .highlightedImage
            }
        }
        if curType == .none {
            if self.animationImages?.isEmpty == false {
                curType = .images
            } else if self.image != nil {
                curType = .image
            }
        }
        return curType
    }
    
    private func setImage(_ image: Any?, withType type: AnimatedImageType) {
        stopAnimating()
        if _link != nil { resetAnimated() }
        switch type {
        case .none:
            break
        case .image:
            super.image = image as? UIImage
        case .highlightedImage:
            super.highlightedImage = image as? UIImage
        case .images:
            super.animationImages = image as? [UIImage]
        case .highlightedImages:
            super.highlightedAnimationImages = image as? [UIImage]
        }
        imageChanged()
    }
    
    private func imageChanged() {
        let newType = currentImageType()
        let newVisibleImage = image(for: newType)
        var newImageFrameCount = 0
        
        if let newImage = newVisibleImage as? (UIImage & PoAnimatable) {
            newImageFrameCount = newImage.animatedImageFrameCount
        }
        
        if newImageFrameCount > 1 {
            resetAnimated()
            let tmp = newVisibleImage as! (UIImage & PoAnimatable)
            _curAnimatedImage = tmp
            _curFrame = tmp
            _totalLoop = _curAnimatedImage?.animatedImageLoopCount ?? 0
            _totalFrameCount = newImageFrameCount
            calcMaxBufferCount()
        }
        setNeedsDisplay()
        didMoved()
    }
    
    fileprivate func calcMaxBufferCount() {
        var bytes = _curAnimatedImage?.animatedImageBytesPerFrame ?? 0
        if bytes == 0 { bytes = 1024 }
        
        let total = UIDevice.current.memoryTotal
        let free = UIDevice.current.memoryFree
        var maxValue = Int(min(total * 2 / 10, free * 6 / 10))
        maxValue = max(maxValue, kBufferSize)
        if maxBufferSize > 0 && maxValue > maxBufferSize {
            maxValue = maxBufferSize
        }
        var maxBufferCount = maxValue / bytes
        if maxBufferCount > 512 {
            maxBufferCount = 512
        } else if maxBufferCount < 1 {
            maxBufferCount = 1
        }
        _maxBufferCount = maxBufferCount
    }
    
    // MARK: - Selector
    
    @objc
    private func didReceiveMemoryWarning(_ notification: Notification) {
        _requestQueue?.cancelAllOperations()
        _requestQueue?.addOperation({
            let next = (self._curIndex + 1) % self._totalFrameCount
            
            _ = self._lock.wait(timeout: .distantFuture)
            for key in self._buffer.keys {
                if key != next { // keep the next frame for smoothly animation
                    self._buffer.removeValue(forKey: key)
                }
            }
            self._lock.signal()
            
            self._incrBufferCount = 1
            self.calcMaxBufferCount()
        })
    }
    
    
    @objc
    private func didEnterBackground(_ notification: Notification) {
        _requestQueue?.cancelAllOperations()
        _requestQueue?.addOperation({
            let next = (self._curIndex + 1) % self._totalFrameCount
            
            _ = self._lock.wait(timeout: .distantFuture)
            for key in self._buffer.keys {
                if key != next { // keep the next frame for smoothly animation
                    self._buffer.removeValue(forKey: key)
                }
            }
            self._lock.signal()
            
            self._incrBufferCount = 1
        })
    }
    
    @objc
    private func step(_ link: CADisplayLink) {
        guard let image = _curAnimatedImage else { return }
        
        if _isLoopEnd { // view will keep in last frame
            stopAnimating()
            return
        }
        
        var nextIndex = (_curIndex + 1) % _totalFrameCount
        var delay: TimeInterval = 0
        if !_bufferMiss { // 上次命中缓存
            _time += link.duration
            delay = image.animatedImageDuration(at: _curIndex)
            if _time < delay { return } // 当前这帧还没播放完
            _time -= delay
            if nextIndex == 0 {
                _curLoop += 1
                if _totalLoop != 0 && _curLoop >= _totalLoop {
                    _isLoopEnd = true
                    stopAnimating()
                    layer.setNeedsDisplay() // let system call 'displayLayer:' before runloop sleep
                    return // stop at last frame
                }
            }
        }
        
        var buffer = _buffer
        var bufferedImage: UIImage?
        var bufferIsFull = false
        
        _ = _lock.wait(timeout: .distantFuture) // Lock
        bufferedImage = buffer?[nextIndex]
        if bufferedImage != nil {
            if _incrBufferCount < _totalFrameCount { // 删掉当前帧，buffer只存后续播放的帧
                buffer?.removeValue(forKey: nextIndex)
            }
            willChangeValue(forKey: "currentAnimatedImageIndex")
            _curIndex = nextIndex
            didChangeValue(forKey: "currentAnimatedImageIndex")
            _curFrame = bufferedImage
            nextIndex = (_curIndex + 1) % _totalFrameCount
            _bufferMiss = false
            if buffer?.count == _totalFrameCount {
                bufferIsFull = true
            }
        } else {
            _bufferMiss = true
        }
        _lock.signal() // unlock
        
        if !_bufferMiss {
            layer.setNeedsDisplay() // let system call 'displayLayer:' before runloop sleep
        }
        
        if !bufferIsFull && _requestQueue?.operationCount == 0 { // if some work not finished, wait for next opportunity
            let operation = _PoAnimatedImageViewFetchOperation()
            operation.view = self
            operation.nextIndex = nextIndex
            operation.curImage = image
            _requestQueue?.addOperation(operation)
        }
    }
    
    
    override func display(_ layer: CALayer) {
        layer.contents = _curFrame?.cgImage
    }
}


/// An operation for image fetch
private class _PoAnimatedImageViewFetchOperation: Operation {
    
    // MARK: - Properties
    unowned(unsafe) var view: PoAnimatedImageView?
    unowned(unsafe) var curImage: (UIImage & PoAnimatable)?
    var nextIndex: Int = 0
    
    override func main() {
        guard let view = view else { return }
        
        if self.isCancelled { return }
        view._incrBufferCount += 1
        
        if view._incrBufferCount > view._maxBufferCount {
            view._incrBufferCount = view._maxBufferCount
        }
        
        var idx = nextIndex
        let max = view._incrBufferCount
        let total = view._totalFrameCount
        
        for _ in 0..<max {
            defer { idx += 1 }
            if idx >= total { idx = 0 }
            if self.isCancelled { break }
            
            _ = view._lock.wait(timeout: .distantFuture)
            let miss = (view._buffer[idx] == nil)
            view._lock.signal()
            
            if miss {
                var img = curImage?.animatedImageFrame(at: idx)
                img = img?.imageByDecoded()
                if self.isCancelled { break }
                _ = view._lock.wait(timeout: .distantFuture)
                view._buffer[idx] = img
                view._lock.signal()
            }
        }
    }
    
}
