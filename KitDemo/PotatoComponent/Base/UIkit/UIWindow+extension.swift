//
//  UIWindow+extension.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/6/16.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

extension UIWindow {
    
    var visibleViewController: UIViewController? {
        return UIWindow.getVisibleController(from: rootViewController)
    }
    
    static func getVisibleController(from vc: UIViewController?) -> UIViewController? {
        if let nav = vc as? UINavigationController {
            return UIWindow.getVisibleController(from: nav.visibleViewController)
        } else if let tab = vc as? UITabBarController {
            return UIWindow.getVisibleController(from: tab.selectedViewController)
        } else {
            if let model = vc?.presentedViewController {
                return UIWindow.getVisibleController(from: model)
            }
            return vc
        }
    }
    
}


