//
//  StrikethroughViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class StrikethroughViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString(string: "Strikethrough", attributes: [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 34)])
        
        text.po.textStrikethrough = PoTextDecoration(style: .double, width: 1, color: .red, shadow: nil)
        
        let label = PoLabel(frame: CGRect(x: 0, y: 0, width: view.width - 20, height: 0))
        label.numberOfLines = 0
        label.attributedText = text
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
    }

}
