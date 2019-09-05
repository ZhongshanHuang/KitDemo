//
//  UnderlineViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class UnderlineViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString(string: "Underline", attributes: [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 34)])
    
        text.po.textUnderline = PoTextDecoration(style: .single, width: 1, color: .red, shadow: nil)
        // 下面这种写法也可以
//        text.po.underlineStyle = NSUnderlineStyle.single
//        text.po.underlineColor = UIColor.red
        
        let label = PoLabel(frame: CGRect(x: 0, y: 0, width: view.width - 20, height: 0))
        label.numberOfLines = 0
        label.attributedText = text
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
    }

}
