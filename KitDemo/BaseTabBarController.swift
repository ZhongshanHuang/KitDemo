//
//  BaseTabBarController.swift
//  KitDemo
//
//  Created by 黄中山 on 2019/11/12.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class BaseTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addChild(TextViewController(), title: "文字")
        addChild(ImageViewController(), title: "图片")
    }
    
    
    private func addChild(_ vc: UIViewController, title: String) {
        vc.title = title
        let nav = UINavigationController(rootViewController: vc)
        addChild(nav)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
