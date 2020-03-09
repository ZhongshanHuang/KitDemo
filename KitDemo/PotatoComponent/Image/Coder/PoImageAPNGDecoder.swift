//
//  PoImageAPNGDecoder.swift
//  KitDemo
//
//  Created by 黄中山 on 2019/11/11.
//  Copyright © 2019 黄中山. All rights reserved.
//

import Foundation
import zlib

// MARK: - APNG

/*
 PNG  spec: http://www.libpng.org/pub/png/spec/1.2/PNG-Structure.html
 APNG spec: https://wiki.mozilla.org/APNG_Specification
 
 ===============================================================================
 PNG format:
 header (8): 89 50 4e 47 0d 0a 1a 0a
 chunk, chunk, chunk, ...
 
 ===============================================================================
 chunk format:
 length (4): uint32_t big endian
 fourcc (4): chunk type code
 data   (length): data
 crc32  (4): uint32_t big endian crc32(fourcc + data)
 
 ===============================================================================
 PNG chunk define:
 
 IHDR (Image Header) required, must appear first, 13 bytes
 width              (4) pixel count, should not be zero
 height             (4) pixel count, should not be zero
 bit depth          (1) expected: 1, 2, 4, 8, 16
 color type         (1) 1<<0 (palette used), 1<<1 (color used), 1<<2 (alpha channel used)
 compression method (1) 0 (deflate/inflate)
 filter method      (1) 0 (adaptive filtering with five basic filter types)
 interlace method   (1) 0 (no interlace) or 1 (Adam7 interlace)
 
 IDAT (Image Data) required, must appear consecutively if there's multiple 'IDAT' chunk
 
 IEND (End) required, must appear last, 0 bytes
 
 ===============================================================================
 APNG chunk define:
 
 acTL (Animation Control) required, must appear before 'IDAT', 8 bytes
 num frames     (4) number of frames
 num plays      (4) number of times to loop, 0 indicates infinite looping
 
 fcTL (Frame Control) required, must appear before the 'IDAT' or 'fdAT' chunks of the frame to which it applies, 26 bytes
 sequence number   (4) sequence number of the animation chunk, starting from 0
 width             (4) width of the following frame
 height            (4) height of the following frame
 x offset          (4) x position at which to render the following frame
 y offset          (4) y position at which to render the following frame
 delay num         (2) frame delay fraction numerator
 delay den         (2) frame delay fraction denominator
 dispose op        (1) type of frame area disposal to be done after rendering this frame (0:none, 1:background 2:previous)
 blend op          (1) type of frame area rendering for this frame (0:source, 1:over)
 
 fdAT (Frame Data) required
 sequence number   (4) sequence number of the animation chunk
 frame data        (x) frame data for this frame (same as 'IDAT')
 
 ===============================================================================
 `dispose_op` specifies how the output buffer should be changed at the end of the delay
 (before rendering the next frame).
 
 * NONE: no disposal is done on this frame before rendering the next; the contents
 of the output buffer are left as is.
 * BACKGROUND: the frame's region of the output buffer is to be cleared to fully
 transparent black before rendering the next frame.
 * PREVIOUS: the frame's region of the output buffer is to be reverted to the previous
 contents before rendering the next frame.
 
 `blend_op` specifies whether the frame is to be alpha blended into the current output buffer
 content, or whether it should completely replace its region in the output buffer.
 
 * SOURCE: all color components of the frame, including alpha, overwrite the current contents
 of the frame's output buffer region.
 * OVER: the frame should be composited onto the output buffer based on its alpha,
 using a simple OVER operation as described in the "Alpha Channel Processing" section
 of the PNG specification
 */

enum po_png_alpha_type: UInt32 {
    case paleete = 1
    case color = 2
    case alpha = 4
}

/// Specifies how the output buffer should be changed at the end of the delay (before rendering the next frame).
enum po_png_dispose_op: UInt8 {
    /// 不做任何事
    /// is done on this frame before rendering the next; the contents of the output buffer are left as is
    case none = 0
    /// 画完当前帧显示后，将当前帧的范围清除
    /// the frame's region of the output buffer is to be cleared to fully transparent black before rendering the next frame.
    case background = 1
    /// 显示完当前帧后，将画板恢复到当前帧的前一帧
    /// the frame's region of the output buffer is to be reverted to the previous contents before rendering the next frame.If the first `fcTL` chunk uses a `dispose_op` of po_png_dispose_op_previous it should be treated as po_png_dispose_op_background
    case previous = 2
}

/// Specifies whether the frame is to be alpha blended into the current output buffer content, or whether it should completely replace its region in the output buffer.
enum po_png_blend_op: UInt8 {
    /// 在要画上当前帧的范围内先清除，然后再画上当前帧
    /// all color components of the frame, including alpha, overwrite the current contents of the frame's output buffer region.
    case source = 0
    /// 在前一帧的基础上画上当前帧
    /// the frame should be composited onto the output buffer based on its alpha, using a simple OVER operation as described in the "Alpha Channel Processing" section of the PNG specification
    case over = 1
}

struct po_png_chunk_info {
    var offset: UInt32 = 0 // chunk offset in png data
    var length: UInt32 = 0 // chunk data length
    var fourcc: UInt32 = 0 // chunk fourcc
    var crc32: UInt32 = 0 // chunk crc32
}

// 13 bytes
struct po_png_chunk_IHDR {
    var width: UInt32 = 0 // pixel count, should not be zero
    var height: UInt32 = 0 // pixel count, should not be zero
    var bit_depth: UInt8 = 0 // expected: 1, 2, 4, 8, 16
    var color_type: UInt8 = 0 // see po_png_alpha_type
    var compreseeion_method: UInt8 = 0 // (deflate/inflate)
    var filter_method: UInt8 = 0 // (adaptive filtering with five basic filter types)
    var interlace_method: UInt8 = 0 // 0 (no interlace) or 1 (Adam7 interlace)
}

// 26 bytes
struct po_png_chunk_fcTL {
    var sequence_number: UInt32 = 0 // sequence number of the animation chunk, starting from 0
    var width: UInt32 = 0 // width of the following frame
    var height: UInt32 = 0 // height of the following frame
    var x_offset: UInt32 = 0 // x position at which to render the following frame
    var y_offset: UInt32 = 0 // y position at which to render the following frame
    var delay_num: UInt16 = 0 // frame delay fraction numerator
    var delay_den: UInt16 = 0 // frame delay fraction denominator
    var dispose_op: UInt8 = 0 // see po_png_dispose_op
    var blend_op: UInt8 = 0 // see po_png_blend_op
}

struct po_png_frame_info {
    var chunk_index: UInt32 = 0 // the first 'fdAT'/''IDAT' chunk index
    var chunk_num: UInt32 = 0 // the 'fdAT'/'IDAT' chunk count
    var chunk_size: UInt32 = 0 // the 'fdAT'/'IDAT' chunk bytes
    var frame_control: po_png_chunk_fcTL = po_png_chunk_fcTL()
}

struct po_png_info {
    var header: po_png_chunk_IHDR = po_png_chunk_IHDR()
    var chunks: UnsafeMutablePointer<po_png_chunk_info>?
    var chunk_num: UInt32 = 0
    
    var apng_frames: UnsafeMutablePointer<po_png_frame_info>? // frame info, nil if not apng
    var apng_frame_num: UInt32 = 0 // 0 if not apng
    var apng_loop_num: UInt32 = 0 // 0 indicates infinite looping
    
    var apng_shared_chunk_indices: UnsafeMutablePointer<UInt32>?
    var apng_shared_chunk_num: UInt32 = 0
    var apng_shared_chunk_size: UInt32 = 0
    var apng_shared_insert_index: UInt32 = 0 // IDAT 出现在第几个chunk
    var apng_first_frame_is_cover: Bool = false // IDAT 是否做为第一个frame帧
}

func po_png_chunk_IHDR_read(IHDR: UnsafeMutablePointer<po_png_chunk_IHDR>, data: UnsafeRawPointer) {
    IHDR.pointee.width = po_swap_endian_uint32(value: data.assumingMemoryBound(to: UInt32.self).pointee)
    IHDR.pointee.height = po_swap_endian_uint32(value: data.advanced(by: 4).assumingMemoryBound(to: UInt32.self).pointee)
    IHDR.pointee.bit_depth = data.load(fromByteOffset: 8, as: UInt8.self)
    IHDR.pointee.color_type = data.load(fromByteOffset: 9, as: UInt8.self)
    IHDR.pointee.compreseeion_method = data.load(fromByteOffset: 10, as: UInt8.self)
    IHDR.pointee.filter_method = data.load(fromByteOffset: 11, as: UInt8.self)
    IHDR.pointee.interlace_method = data.load(fromByteOffset: 12, as: UInt8.self)
}

func po_png_chunk_IHDR_write(IHDR: UnsafeMutablePointer<po_png_chunk_IHDR>, data: UnsafeMutableRawPointer) {
    data.assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: IHDR.pointee.width)
    data.advanced(by: 4).assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: IHDR.pointee.height)
    data.storeBytes(of: IHDR.pointee.bit_depth, toByteOffset: 8, as: UInt8.self)
    data.storeBytes(of: IHDR.pointee.color_type, toByteOffset: 9, as: UInt8.self)
    data.storeBytes(of: IHDR.pointee.compreseeion_method, toByteOffset: 10, as: UInt8.self)
    data.storeBytes(of: IHDR.pointee.filter_method, toByteOffset: 11, as: UInt8.self)
    data.storeBytes(of: IHDR.pointee.interlace_method, toByteOffset: 12, as: UInt8.self)
}

func po_png_chunk_fcTL_read(fcTL: UnsafeMutablePointer<po_png_chunk_fcTL>, data: UnsafeRawPointer) {
    fcTL.pointee.sequence_number = po_swap_endian_uint32(value: data.assumingMemoryBound(to: UInt32.self).pointee)
    fcTL.pointee.width = po_swap_endian_uint32(value: data.advanced(by: 4).assumingMemoryBound(to: UInt32.self).pointee)
    fcTL.pointee.height = po_swap_endian_uint32(value: data.advanced(by: 8).assumingMemoryBound(to: UInt32.self).pointee)
    fcTL.pointee.x_offset = po_swap_endian_uint32(value: data.advanced(by: 12).assumingMemoryBound(to: UInt32.self).pointee)
    fcTL.pointee.y_offset = po_swap_endian_uint32(value: data.advanced(by: 16).assumingMemoryBound(to: UInt32.self).pointee)
    fcTL.pointee.delay_num = po_swap_endian_uint16(value: data.advanced(by: 20).assumingMemoryBound(to: UInt16.self).pointee)
    fcTL.pointee.delay_den = po_swap_endian_uint16(value: data.advanced(by: 22).assumingMemoryBound(to: UInt16.self).pointee)
    fcTL.pointee.dispose_op = data.load(fromByteOffset: 24, as: UInt8.self)
    fcTL.pointee.blend_op = data.load(fromByteOffset: 25, as: UInt8.self)
}

func po_png_chunk_fcTL_write(fcTL: UnsafeMutablePointer<po_png_chunk_fcTL>, data: UnsafeMutableRawPointer) {
    data.assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: fcTL.pointee.sequence_number)
    data.advanced(by: 4).assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: fcTL.pointee.width)
    data.advanced(by: 8).assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: fcTL.pointee.height)
    data.advanced(by: 12).assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: fcTL.pointee.x_offset)
    data.advanced(by: 16).assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: fcTL.pointee.y_offset)
    data.advanced(by: 20).assumingMemoryBound(to: UInt16.self).pointee = po_swap_endian_uint16(value: fcTL.pointee.delay_num)
    data.advanced(by: 22).assumingMemoryBound(to: UInt16.self).pointee = po_swap_endian_uint16(value: fcTL.pointee.delay_den)
    data.storeBytes(of: fcTL.pointee.dispose_op, toByteOffset: 24, as: UInt8.self)
    data.storeBytes(of: fcTL.pointee.blend_op, toByteOffset: 25, as: UInt8.self)
}

/// convert double value to fraction
func po_png_delay_to_fraction(duration: Double, num: UnsafeMutablePointer<UInt16>, den: UnsafeMutablePointer<UInt16>) {
    if duration >= 0xFF {
        num.pointee = 0xFF
        den.pointee = 1
    } else if duration <= (1.0 / 0xFF) {
        num.pointee = 1
        den.pointee = 0xFF
    } else {
        // use continued fraction to calculate the num and den.
        let max = 10
        let eps: Double = 0.5 / 0xFF
        var p = Array<Int>(repeating: 0, count: max)
        var q = Array<Int>(repeating: 0, count: max)
        var a = Array<Int>(repeating: 0, count: max)
        var i = 2
        var numl = 0
        var denl = 0
        // the first two convergents are 0/1 and 1/0
        p[0] = 0; q[0] = 1
        p[1] = 1; q[1] = 0
        // the rest of the convergents (and continued fraction)
        while i < max {
            var duration = duration
            a[i] = lrint(floor(duration))
            p[i] = a[i] * p[i - 1] + p[i - 2]
            q[i] = a[i] * q[i - 1] + q[i - 2]
            if p[i] <= 0xFF && q[i] <= 0xFF { // uint16
                numl = p[i]
                denl = q[i]
            } else {
                break
            }
            if fabs(duration - Double(a[i])) < eps {
                break
            }
            duration = 1.0 / (duration - Double(a[i]))
            i += 1
        }
        
        if numl != 0 && denl != 0 {
            num.pointee = UInt16(numl)
            den.pointee = UInt16(denl)
        } else {
            num.pointee = 1
            den.pointee = 100
        }
    }
}

/// convert fraction to double value
func po_png_delay_to_seconds(num: UInt16, den: UInt16) -> Double {
    if den == 0 {
        return Double(num) / 100.0
    } else {
        return Double(num) / Double(den)
    }
}

func po_png_validate_animation_chunk_order(chunks: UnsafePointer<po_png_chunk_info>, chunk_num: UInt32, first_idat_index: UnsafeMutablePointer<UInt32>, first_frame_is_cover: UnsafeMutablePointer<Bool>) -> Bool {
    /*
     PNG at least contains 3 chunks: IHDR, IDAT, IEND.
     `IHDR` must appear first.
     `IDAT` must appear consecutively.
     `IEND` must appear end.
     
     APNG must contains one `acTL` and at least one 'fcTL' and `fdAT`.
     `fdAT` must appear consecutively.
     `fcTL` must appear before `IDAT` or `fdAT`.
     */
    if chunk_num <= 2 { return false }
    if chunks.pointee.fourcc != po_four_cc(c1: "I", c2: "H", c3: "D", c4: "R") { return false }
    if chunks[Int(chunk_num - 1)].fourcc != po_four_cc(c1: "I", c2: "E", c3: "N", c4: "D") { return false }
    
    var pre_fourcc: UInt32 = 0
    var IHDR_num: UInt32 = 0
    var IDAT_num: UInt32 = 0
    var acTL_num: UInt32 = 0
    var fcTL_num: UInt32 = 0
    var first_IDAT: UInt32 = 0
    var first_frame_cover = false
    for i in 0..<chunk_num {
        let chunk = chunks.advanced(by: Int(i))
        switch chunk.pointee.fourcc {
        case po_four_cc(c1: "I", c2: "H", c3: "D", c4: "R"):
            if i != 0 { return false }
            if IHDR_num > 0 { return false }
            IHDR_num += 1
        case po_four_cc(c1: "I", c2: "D", c3: "A", c4: "T"):
            if pre_fourcc != po_four_cc(c1: "I", c2: "D", c3: "A", c4: "T") {
                if IDAT_num == 0 {
                    first_IDAT = i
                } else {
                    return false
                }
                IDAT_num += 1
            }
        case po_four_cc(c1: "a", c2: "c", c3: "T", c4: "L"):
            if acTL_num > 0 { return false }
            acTL_num += 1
        case po_four_cc(c1: "f", c2: "c", c3: "T", c4: "L"):
            if i + 1 == chunk_num { return false }
            if chunk.successor().pointee.fourcc != po_four_cc(c1: "f", c2: "d", c3: "A", c4: "T") && chunk.successor().pointee.fourcc != po_four_cc(c1: "I", c2: "D", c3: "A", c4: "T") {
                return false
            }
            if fcTL_num == 0 {
                if chunk.successor().pointee.fourcc == po_four_cc(c1: "I", c2: "D", c3: "A", c4: "T") {
                    first_frame_cover = true
                }
            }
            fcTL_num += 1
        case po_four_cc(c1: "f", c2: "d", c3: "A", c4: "T"):
            if pre_fourcc != po_four_cc(c1: "f", c2: "d", c3: "A", c4: "T") &&
                pre_fourcc != po_four_cc(c1: "f", c2: "c", c3: "T", c4: "L") {
                return false
            }
        default:
            break
        }
        pre_fourcc = chunk.pointee.fourcc
    }
    if IHDR_num != 1 { return false }
    if IDAT_num == 0 { return false }
    if acTL_num != 1 { return false }
    if fcTL_num < acTL_num { return false }
    first_idat_index.pointee = first_IDAT
    first_frame_is_cover.pointee = first_frame_cover
    return true
}

func po_png_info_release(_ info: UnsafePointer<po_png_info>) {
    info.pointee.chunks?.deallocate()
    info.pointee.apng_frames?.deallocate()
    info.pointee.apng_shared_chunk_indices?.deallocate()
    info.deallocate()
}

/**
 Create a png info from a png file. See struct png_info for more information.
 
 @param data   png/apng file data.
 @param length the data's length in bytes.
 @return A png info object, you may call po_png_info_release() to release it.
 Returns NULL if an error occurs.
 */

func po_png_info_create(data: UnsafeRawPointer, length: Int) -> UnsafeMutablePointer<po_png_info>? {
    if length < 61 { return nil } // 至少包含signature(8) + IHDR(25) + IDAT(>12) + IEND(16)

    let result = (data.load(fromByteOffset: 0, as: UInt32.self) == po_four_num(c1: 0x89, c2: 0x50, c3: 0x4E, c4: 0x47) &&
                data.load(fromByteOffset: 4, as: UInt32.self) == po_four_num(c1: 0x0D, c2: 0x0A, c3: 0x1A, c4: 0x0A))
    // 判断是否png格式
    if !result { return nil }
    
    let chunk_realloc_num: UInt32 = 16
    var chunks = UnsafeMutablePointer<po_png_chunk_info>.allocate(capacity: Int(chunk_realloc_num))
    
    // parse png chunks
    var offset: UInt32 = 8
    var chunk_num: UInt32 = 0
    var chunk_capacity: UInt32 = chunk_realloc_num
    var apng_loop_num: UInt32 = 0
    var apng_sequence_index: Int32 = -1
    var apng_frame_index: Int32 = 0
    var apng_frame_number: UInt32 = 0
    var apng_chunk_error = false
    
    repeat {
        if chunk_num >= chunk_capacity {
            chunks = realloc(chunks, MemoryLayout<po_png_chunk_info>.stride * Int(chunk_capacity + chunk_realloc_num)).assumingMemoryBound(to: po_png_chunk_info.self)
            chunk_capacity += chunk_realloc_num
        }
        let chunk = chunks.advanced(by: Int(chunk_num))
        chunk.initialize(to: po_png_chunk_info()) // must init
        let chunk_data = data.advanced(by: Int(offset))
        chunk.pointee.offset = offset
        chunk.pointee.length = po_swap_endian_uint32(value: chunk_data.assumingMemoryBound(to: UInt32.self).pointee)
   
        if chunk.pointee.offset + chunk.pointee.length + 12 > length {
            chunks.deallocate()
            return nil
        }
        
        chunk.pointee.fourcc = chunk_data.advanced(by: 4).assumingMemoryBound(to: UInt32.self).pointee
        chunk.pointee.crc32 = po_swap_endian_uint32(value: chunk_data.advanced(by: 8 + Int(chunk.pointee.length)).assumingMemoryBound(to: UInt32.self).pointee)
        
        chunk_num += 1
        offset += 12 + chunk.pointee.length
        
        switch chunk.pointee.fourcc {
        case po_four_cc(c1: "a", c2: "c", c3: "T", c4: "L"):
            if chunk.pointee.length == 8 {
                apng_frame_number = po_swap_endian_uint32(value: chunk_data.advanced(by: 8).assumingMemoryBound(to: UInt32.self).pointee)
                apng_loop_num = po_swap_endian_uint32(value: chunk_data.advanced(by: 12).assumingMemoryBound(to: UInt32.self).pointee)
            } else {
                apng_chunk_error = true
            }
        case po_four_cc(c1: "f", c2: "c", c3: "T", c4: "L"), po_four_cc(c1: "f", c2: "d", c3: "A", c4: "T"):
            if chunk.pointee.fourcc == po_four_cc(c1: "f", c2: "c", c3: "T", c4: "L") {
                if chunk.pointee.length != 26 {
                    apng_chunk_error = true
                } else {
                    apng_frame_index += 1
                }
            }
            if chunk.pointee.length > 4 {
                if apng_sequence_index + 1 == po_swap_endian_uint32(value: chunk_data.advanced(by: 8).assumingMemoryBound(to: UInt32.self).pointee) {
                    apng_sequence_index += 1
                } else {
                    apng_chunk_error = true
                }
            } else {
                apng_chunk_error = true
            }
        case po_four_cc(c1: "I", c2: "E", c3: "N", c4: "D"):
            offset = UInt32(length)
        default:
            break
        }
    } while offset + 12 <= length
    
    if chunk_num < 3 ||
        chunks.pointee.fourcc != po_four_cc(c1: "I", c2: "H", c3: "D", c4: "R") ||
        chunks.pointee.length != 13 {
        chunks.deallocate()
        return nil
    }
    
    // png info
    let info = UnsafeMutablePointer<po_png_info>.allocate(capacity: 1)
    info.initialize(to: po_png_info())
    info.pointee.chunks = chunks
    info.pointee.chunk_num = chunk_num
    po_png_chunk_IHDR_read(IHDR: &info.pointee.header, data: data.advanced(by: Int(chunks.pointee.offset + 8)))
    
    // apng info
    if !apng_chunk_error && apng_frame_number == apng_frame_index && apng_frame_number >= 1 {
        var first_frame_is_cover = false
        var first_IDAT_index: UInt32 = 0
        if !po_png_validate_animation_chunk_order(chunks: info.pointee.chunks!, chunk_num: info.pointee.chunk_num, first_idat_index: &first_IDAT_index, first_frame_is_cover: &first_frame_is_cover) {
            return info // ignore apng chunk
        }
        
        info.pointee.apng_loop_num = apng_loop_num
        info.pointee.apng_frame_num = apng_frame_number
        info.pointee.apng_first_frame_is_cover = first_frame_is_cover
        info.pointee.apng_shared_insert_index = first_IDAT_index
        info.pointee.apng_frames = UnsafeMutablePointer<po_png_frame_info>.allocate(capacity: Int(apng_frame_number))
        info.pointee.apng_frames?.initialize(repeating: po_png_frame_info(), count: Int(apng_frame_number))
        info.pointee.apng_shared_chunk_indices = UnsafeMutablePointer<UInt32>.allocate(capacity: Int(chunk_num))
        info.pointee.apng_shared_chunk_indices?.initialize(repeating: 0, count: Int(chunk_num))
        
        var frame_index: Int32 = -1
        var shared_chunk_index = info.pointee.apng_shared_chunk_indices!
        for i in 0..<info.pointee.chunk_num {
            let chunk = info.pointee.chunks!.advanced(by: Int(i))
            switch chunk.pointee.fourcc {
            case po_four_cc(c1: "I", c2: "D", c3: "A", c4: "T"):
                if first_frame_is_cover {
                    let frame = info.pointee.apng_frames!.advanced(by: Int(frame_index))
                    frame.pointee.chunk_num += 1
                    frame.pointee.chunk_size += chunk.pointee.length + 12
                }
            case po_four_cc(c1: "a", c2: "c", c3: "T", c4: "L"):
                break
            case po_four_cc(c1: "f", c2: "c", c3: "T", c4: "L"):
                frame_index += 1
                let frame = info.pointee.apng_frames!.advanced(by: Int(frame_index))
                frame.pointee.chunk_index = i + 1
                po_png_chunk_fcTL_read(fcTL: &frame.pointee.frame_control, data: data.advanced(by: Int(chunk.pointee.offset + 8)))
            case po_four_cc(c1: "f", c2: "d", c3: "A", c4: "T"):
                let frame = info.pointee.apng_frames!.advanced(by: Int(frame_index))
                frame.pointee.chunk_num += 1
                frame.pointee.chunk_size += chunk.pointee.length + 12
            default: // IHDR | IEND
                shared_chunk_index.pointee = i
                shared_chunk_index += 1
                info.pointee.apng_shared_chunk_size += chunk.pointee.length + 12
                info.pointee.apng_shared_chunk_num += 1
            }
        }
    }
    return info
}

/**
 Copy a png frame data from an apng file.
 
 @param data  apng file data
 @param info  png info
 @param index frame index (zero-based)
 @param size  output, the size of the frame data
 @return A frame data (single-frame png file), call free() to release the data.
 Returns NULL if an error occurs.
 */

func po_png_copy_frame_data_at_index(data: UnsafeRawPointer, info: UnsafePointer<po_png_info>, index: Int, size: UnsafeMutablePointer<Int>) -> UnsafeMutableRawPointer? {
    if index >= info.pointee.apng_frame_num { return nil }
    
    let frame_info = info.pointee.apng_frames!.advanced(by: index)
    // 8: PNG signature + apng_shared_chunk_size: IHDR & IEND
    var frame_remux_size: UInt32 = 8 + info.pointee.apng_shared_chunk_size + frame_info.pointee.chunk_size
    if !(info.pointee.apng_first_frame_is_cover && index == 0) {
        frame_remux_size -= frame_info.pointee.chunk_num * 4 // remove fdAT sequence number
    }
    let frame_data = UnsafeMutableRawPointer.allocate(byteCount: Int(frame_remux_size), alignment: MemoryLayout<UInt8>.stride)
    size.pointee = Int(frame_remux_size)
    
    var data_offset: Int = 0
    var inserted = false
    memcpy(frame_data, data, 8) // PNG signature
    data_offset += 8
    for i in 0..<info.pointee.apng_shared_chunk_num {
        let shared_chunk_index = info.pointee.apng_shared_chunk_indices![Int(i)]
        let shared_chunk_info = info.pointee.chunks!.advanced(by: Int(shared_chunk_index))
        
        if shared_chunk_index >= info.pointee.apng_shared_insert_index && !inserted { // replace IDAT with fdAT
            inserted = true
            for c in 0..<frame_info.pointee.chunk_num {
                let insert_chunk_info = info.pointee.chunks!.advanced(by: Int(frame_info.pointee.chunk_index + c))
                if insert_chunk_info.pointee.fourcc == po_four_cc(c1: "f", c2: "d", c3: "A", c4: "T") {
                    frame_data.advanced(by: data_offset).assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: insert_chunk_info.pointee.length - 4)
                    frame_data.advanced(by: data_offset + 4).assumingMemoryBound(to: UInt32.self).pointee = po_four_cc(c1: "I", c2: "D", c3: "A", c4: "T")
                    memcpy(frame_data.advanced(by: data_offset + 8), data.advanced(by: Int(insert_chunk_info.pointee.offset + 12)), Int(insert_chunk_info.pointee.length - 4))
                    let crc = UInt32(crc32(0, frame_data.advanced(by: data_offset + 4).assumingMemoryBound(to: UInt8.self), insert_chunk_info.pointee.length))
                    frame_data.advanced(by: data_offset + Int(insert_chunk_info.pointee.length) + 4).assumingMemoryBound(to: UInt32.self).pointee = po_swap_endian_uint32(value: crc)
                    data_offset += Int(insert_chunk_info.pointee.length + 8)
                } else { // IDAT
                    memcpy(frame_data.advanced(by: data_offset), data.advanced(by: Int(insert_chunk_info.pointee.offset)), Int(insert_chunk_info.pointee.length) + 12)
                    data_offset += Int(insert_chunk_info.pointee.length + 12)
                }
            }
        }
        
        if shared_chunk_info.pointee.fourcc == po_four_cc(c1: "I", c2: "H", c3: "D", c4: "R") { // IHDR
            let tmp = UnsafeMutablePointer<UInt8>.allocate(capacity: 25)
            tmp.initialize(repeating: 0, count: 25)
            defer { tmp.deallocate() }
            
            memcpy(tmp, data.advanced(by: Int(shared_chunk_info.pointee.offset)), 25)
            var IHDR = info.pointee.header
            IHDR.width = frame_info.pointee.frame_control.width
            IHDR.height = frame_info.pointee.frame_control.height
            po_png_chunk_IHDR_write(IHDR: &IHDR, data: tmp.advanced(by: 8))
            tmp.advanced(by: 21).withMemoryRebound(to: UInt32.self, capacity: 1) { (pt) -> Void in
                pt.pointee = po_swap_endian_uint32(value: UInt32(crc32(0, tmp.advanced(by: 4), 17)))
            }
            memcpy(frame_data.advanced(by: data_offset), tmp, 25)
            data_offset += 25
        } else {
            memcpy(frame_data.advanced(by: data_offset), data.advanced(by: Int(shared_chunk_info.pointee.offset)), Int(shared_chunk_info.pointee.length + 12))
            data_offset += Int(shared_chunk_info.pointee.length + 12)
        }
    }
    return frame_data
}

// MARK: - Utility for little endian platform

func po_four_num(c1: UInt8, c2: UInt8, c3: UInt8, c4: UInt8) -> UInt32 {
    let value1 = UInt32(c1)
    let value2 = UInt32(c2) << 8
    let value3 = UInt32(c3) << 16
    let value4 = UInt32(c4) << 24
    return value4 | value3 | value2 | value1
}

func po_four_cc(c1: Unicode.Scalar, c2: Unicode.Scalar, c3: Unicode.Scalar, c4: Unicode.Scalar) -> UInt32 {
    let value1 = c1.value
    let value2 = c2.value << 8
    let value3 = c3.value << 16
    let value4 = c4.value << 24
    return value4 | value3 | value2 | value1
}

func po_two_num(c1: UInt8, c2: UInt8) -> UInt16 {
    return ((UInt16(c1) & 0x00FF) << 8) | ((UInt16(c2) & 0xFF00) >> 8)
}

func po_two_cc(c1: Unicode.Scalar, c2: Unicode.Scalar) -> UInt16 {
    return ((UInt16(c1.value) & 0x00FF) << 8) | ((UInt16(c2.value) & 0xFF00) >> 8)
}

func po_swap_endian_uint16(value: UInt16) -> UInt16 {
    return ((value & 0x00FF) << 8) | ((value & 0xFF00) >> 8)
}

func po_swap_endian_uint32(value: UInt32) -> UInt32 {
    let value1 = (value & 0x000000FF) << 24
    let value2 = (value & 0x0000FF00) << 8
    let value3 = (value & 0x00FF0000) >> 8
    let value4 = (value & 0xFF000000) >> 24
    return value1 | value2 | value3 | value4
}
