//
//  GlyphTransformViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class GlyphTransformViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString(string: "GlyphTransform", attributes: [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 34)])
        
        text.po.textGlyphTransform = CGAffineTransform.identity.rotated(by: -.pi / 8)
        
        let label = PoLabel(frame: CGRect(x: 0, y: 0, width: view.width - 20, height: 0))
        label.numberOfLines = 0
        label.attributedText = text
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
    }

}
