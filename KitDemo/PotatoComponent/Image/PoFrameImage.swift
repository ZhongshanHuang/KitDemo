//
//  PoFrameImage.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/5/23.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class PoFrameImage: UIImage {
    
    // MARK: - Properties
    
    private var _loopCount: Int = 0
    private var _oneFrameBytes: Int = 0
    private var _imagePaths: [String]?
    private var _imageDatas: [Data]?
    private var _frameDurations: [TimeInterval]?
    
    convenience init?(imagePaths: [String], oneFrameDuration duration: TimeInterval, loopCount: Int) {
        let durations = Array<TimeInterval>(repeating: duration, count: imagePaths.count)
        self.init(imagePaths: imagePaths, frameDurations: durations, loopCount: loopCount)
    }
    
    convenience init?(imagePaths: [String], frameDurations: [TimeInterval], loopCount: Int) {
        if imagePaths.isEmpty { return nil }
        if imagePaths.count != frameDurations.count { return nil }
        
        let firstPath = imagePaths[0]
        guard let firstData = try? Data(contentsOf: URL(fileURLWithPath: firstPath)),
            let firstCG = UIImage(data: firstData)?.imageByDecoded().cgImage else { return nil }
        let scale = firstPath.pathScale()
        self.init(cgImage: firstCG, scale: scale, orientation: .up)
        _oneFrameBytes = firstCG.bytesPerRow * firstCG.height
        _imagePaths = imagePaths
        _frameDurations = frameDurations
        _loopCount = loopCount
    }

    convenience init?(imageDatas: [Data], oneFrameDuration duration: TimeInterval, loopCount: Int) {
        let durations = Array<TimeInterval>(repeating: duration, count: imageDatas.count)
        self.init(imageDatas: imageDatas, frameDurations: durations, loopCount: loopCount)
    }

    convenience init?(imageDatas: [Data], frameDurations: [TimeInterval], loopCount: Int) {
        if imageDatas.isEmpty { return nil }
        if imageDatas.count != frameDurations.count { return nil }
        
        let firstData = imageDatas[0]
        let scale = UIScreen.main.scale
        guard let firstCG = UIImage(data: firstData)?.imageByDecoded().cgImage else { return nil }
        self.init(cgImage: firstCG, scale: scale, orientation: .up)
        _oneFrameBytes = firstCG.bytesPerRow * firstCG.height
        _imageDatas = imageDatas
        _frameDurations = frameDurations
        _loopCount = loopCount
    }
    
    override init() {
        super.init()
    }
    
    override init?(contentsOfFile path: String) {
        super.init(contentsOfFile: path)
    }
    
    override init?(data: Data) {
        super.init(data: data)
    }
    
    override init?(data: Data, scale: CGFloat) {
        super.init(data: data, scale: scale)
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

extension PoFrameImage: PoAnimatable {
    
    var animatedImageFrameCount: Int {
        if _imagePaths != nil {
            return _imagePaths!.count
        } else if _imageDatas != nil {
            return _imageDatas!.count
        } else {
            return 1
        }
    }
    
    var animatedImageLoopCount: Int {
        return _loopCount
    }
    
    var animatedImageBytesPerFrame: Int {
        return _oneFrameBytes
    }
    
    func animatedImageFrame(at index: Int) -> UIImage? {
        if let _imagePaths = _imagePaths {
            if index >= _imagePaths.count { return nil }
            let path = _imagePaths[index]
            let scale = path.pathScale()
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                return UIImage(data: data, scale: scale)?.imageByDecoded()
            }
            return nil
        } else if let _imageDatas = _imageDatas {
            if index >= _imageDatas.count { return nil }
            return UIImage(data: _imageDatas[index], scale: UIScreen.main.scale)?.imageByDecoded()
        } else {
            return index == 0 ? self : nil
        }
    }
    
    func animatedImageDuration(at index: Int) -> TimeInterval {
        guard let _frameDurations = _frameDurations, index < _frameDurations.count else { return 0 }
        return _frameDurations[index]
    }
    
    
}
