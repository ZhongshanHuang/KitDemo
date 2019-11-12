//
//  PoImageUtilities.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/4/29.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import MobileCoreServices.UTCoreTypes

enum PoImageType {
    case unknown
    case jpeg              // jpeg, jpg
    case jpeg2000          // jpe2
    case tiff              // tiff, tif
    case bmp               // bmp
    case ico               // ico
    case icns              // icns
    case gif               // gif
    case png               // png
    case webp              // webp
    
    init(uti: CFString) {
        switch uti {
        case kUTTypeJPEG:
            self = .jpeg
        case kUTTypeJPEG2000:
            self = .jpeg2000
        case kUTTypeTIFF:
            self = .tiff
        case kUTTypeBMP:
            self = .bmp
        case kUTTypeICO:
            self = .ico
        case kUTTypeAppleICNS:
            self = .icns
        case kUTTypeGIF:
            self = .gif
        case kUTTypePNG:
            self = .png
        default:
            self = .unknown
        }

    }
}

extension PoImageType {
    
    var typeExtension: String? {
        switch self {
        case .jpeg:
            return "jpg"
        case .jpeg2000:
            return "jp2"
        case .tiff:
            return "tiff"
        case .bmp:
            return "bmp"
        case .ico:
            return "ico"
        case .icns:
            return "icns"
        case .gif:
            return "gif"
        case .png:
            return "png"
        case .webp:
            return "webp"
        default: // unknown
            return nil
        }
    }
    
    var uiType: CFString? {
        switch self {
        case .jpeg:
             return kUTTypeJPEG
        case .jpeg2000:
            return kUTTypeJPEG2000
        case .tiff:
            return kUTTypeTIFF
        case .bmp:
            return kUTTypeBMP
        case .ico:
            return kUTTypeICO
        case .icns:
            return kUTTypeAppleICNS
        case .gif:
            return kUTTypeGIF
        case .png:
            return kUTTypePNG
        default: // webp,unknown
            return nil
        }
    }
}


// MARK: - Helper

/// - Returns: byte-aligned size
@inlinable
func PoImageByteAlign(size: size_t, alignment: size_t) -> size_t {
    return ((size + (alignment - 1)) / alignment) * alignment
}

/// System color space
let PoCGColorSpaceGetDeviceRGB: CGColorSpace = CGColorSpaceCreateDeviceRGB()
let PoCGColorSpaceGetDeviceGray: CGColorSpace = CGColorSpaceCreateDeviceGray()

func PoCGColorSpaceIsDeviceRGB(space: CGColorSpace) -> Bool {
    return CFEqual(space, PoCGColorSpaceGetDeviceRGB)
}

func PoCGColorSpaceIsDeviceGray(space: CGColorSpace) -> Bool {
    return CFEqual(space, PoCGColorSpaceGetDeviceGray)
}

/// CGDataProviderReleaseCallback
func PoCGDataProviderReleaseDataCallback(_ info: UnsafeMutableRawPointer?, _ data: UnsafeRawPointer, _ size: Int) {
    info?.deallocate()
}

func PoImageDetectType(data: NSData?) -> PoImageType {
    guard let data = data else { return .unknown }
    
    let lenth = data.length
    if lenth < 16 { return .unknown }
    
    let baseAddress = data.bytes
    let magic4 = baseAddress.load(fromByteOffset: 0, as: UInt32.self)
    
    switch magic4 {
    case po_four_num(c1: 0x4D, c2: 0x4D, c3: 0x00, c4: 0x2A), po_four_num(c1: 0x49, c2: 0x49, c3: 0x2A, c4: 0x00):
        return .tiff
    case po_four_num(c1: 0x00, c2: 0x00, c3: 0x01, c4: 0x00), po_four_num(c1: 0x00, c2: 0x00, c3: 0x02, c4: 0x00):
        return .ico
    case po_four_num(c1: 0x69, c2: 0x63, c3: 0x6E, c4: 0x73): // icns
        return .icns
    case po_four_num(c1: 0x47, c2: 0x49, c3: 0x46, c4: 0x38): // GIF
        return .gif
    case po_four_num(c1: 0x89, c2: 0x50, c3: 0x4E, c4: 0x47): // PNG
        let tmp = baseAddress.load(fromByteOffset: 4, as: UInt32.self)
        if tmp == po_four_num(c1: 0x0D, c2: 0x0A, c3: 0x1A, c4: 0x0A) {
            return .png
        }
    case po_four_num(c1: 0x52, c2: 0x49, c3: 0x46, c4: 0x46): // webp
        let tmp = baseAddress.load(fromByteOffset: 8, as: UInt32.self)
        if tmp == po_four_num(c1: 0x57, c2: 0x45, c3: 0x42, c4: 0x50) {
            return .webp
        }
    default:
        break
    }
    
    let magic2 = baseAddress.load(fromByteOffset: 0, as: UInt16.self)
    
    switch magic2 {
    case po_two_cc(c1: "B", c2: "A"), // BA
    po_two_cc(c1: "B", c2: "M"), // BM
    po_two_cc(c1: "I", c2: "C"), // IC
    po_two_cc(c1: "P", c2: "I"), // PI
    po_two_cc(c1: "C", c2: "I"), // CI
    po_two_cc(c1: "C", c2: "P"): // CP
        return .bmp
    case po_two_num(c1: 0xFF, c2: 0x4F):
        return .jpeg2000
    default:
        break
    }
    
    // jpg
    var isJPG = true
    let buff1: [UInt8] = [0xFF, 0xD8, 0xFF]
    for (index, value) in buff1.enumerated() {
        if baseAddress.load(fromByteOffset: index, as: UInt8.self) != value {
            isJPG = false
        }
    }
    if isJPG { return .jpeg }
    
    // jpg2
    var isJPG2 = true
    let buff2: [UInt8] = [0x6A, 0x50, 0x20, 0x20, 0x0D]
    for (index, value) in buff2.enumerated() {
        if baseAddress.load(fromByteOffset: index, as: UInt8.self) != value {
            isJPG2 = false
        }
    }
    if isJPG2 { return .jpeg2000 }
    
    return .unknown
}

func PoUIImageOrientationFromEXITValue(_ value: Int) -> UIImage.Orientation {
    switch value {
    case UIImage.Orientation.up.rawValue:
        return .up
    case UIImage.Orientation.down.rawValue:
        return .down
    case UIImage.Orientation.left.rawValue:
        return .left
    case UIImage.Orientation.right.rawValue:
        return .right
    case UIImage.Orientation.upMirrored.rawValue:
        return .upMirrored
    case UIImage.Orientation.downMirrored.rawValue:
        return .downMirrored
    case UIImage.Orientation.leftMirrored.rawValue:
        return .leftMirrored
    case UIImage.Orientation.rightMirrored.rawValue:
        return .rightMirrored
    default:
        return .up
    }
}

