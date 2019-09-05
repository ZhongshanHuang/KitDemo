//
//  LigatureViewController.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class LigatureViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString(string: "flush and fily")
        text.po.font = UIFont(name: "futura", size: 30)

        let label = PoLabel(frame: CGRect(x: 0, y: 0, width: view.width - 20, height: 0))
        label.numberOfLines = 0
        label.attributedText = text
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
      
    }

}
