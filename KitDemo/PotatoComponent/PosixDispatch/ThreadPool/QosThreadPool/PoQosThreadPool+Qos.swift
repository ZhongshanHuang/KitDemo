//
//  PoQosThreadPool+QoS.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/10.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Foundation

extension PoQosThreadPool {

    enum QoS: Int, CaseIterable {
        case userInteractive, userInitiated, utility, background
    }
    
}

extension PoQosThreadPool.QoS {
    
    var maxThreads: Float {
        switch self {
        case .userInteractive:
            return 1
        case .userInitiated:
            return 0.75
        case .utility:
            return 0.5
        case .background:
            return 0.25
        }
    }
    
}
