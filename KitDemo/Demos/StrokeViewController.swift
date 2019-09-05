//
//  StrokeViewController.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class StrokeViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString()
        
        do {
            let stroke1 = NSMutableAttributedString(string: "Typography StrokeWidth -4")
            stroke1.po.strokeWidth = -4
            text.append(stroke1)
            text.append(padding)
            
            let stroke2 = NSMutableAttributedString(string: "Typography StrokeWidth 0")
            stroke2.po.strokeWidth = 0
            stroke2.po.strokeColor = .orange
            text.append(stroke2)
            text.append(padding)
            
            let stroke3 = NSMutableAttributedString(string: "Typography StrokeWidth 4")
            stroke3.po.strokeWidth = 4
            stroke3.po.strokeColor = .green
            text.append(stroke3)
            text.append(padding)
        }
        
        
        let label = PoLabel(frame: CGRect(x: 0, y: 0, width: view.width - 20, height: 0))
        label.numberOfLines = 0
        label.attributedText = text
        label.font = UIFont.systemFont(ofSize: 30)
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
    }
    
}
