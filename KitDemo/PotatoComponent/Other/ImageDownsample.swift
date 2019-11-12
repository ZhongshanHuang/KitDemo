//
//  ImageDownsample.swift
//  KitDemo
//
//  Created by 黄中山 on 2019/11/12.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

// MARK: - downsample large images for display at smaller size

func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions)!
    
    let maxDimentionInPixels = max(pointSize.width, pointSize.height)
    let downsampleOptions = [
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimentionInPixels] as CFDictionary
    let downsampleImage = CGImageSourceCreateImageAtIndex(imageSource, 0, downsampleOptions)!
    return UIImage(cgImage: downsampleImage)
}
