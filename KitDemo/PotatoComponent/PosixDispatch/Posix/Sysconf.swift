//
//  Sysconf.swift
//  KitDemo
//
//  Created by 黄中山 on 2020/6/9.
//  Copyright © 2020 黄中山. All rights reserved.
//

import Darwin.POSIX.unistd

struct Sysconf {
    
    static let processorsCount = sysconf(_SC_NPROCESSORS_ONLN)
    
}
