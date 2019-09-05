//
//  RubyAnnotationViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/26.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class RubyAnnotationViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString(string: "这是用汉语写的一段文字。", attributes: [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 34)])
        
        let ruby1 = PoTextRubyAnnotation()
        ruby1.textInline = "zhè shì"
        
        let ruby2 = PoTextRubyAnnotation()
        ruby2.textBefore = "hàn yŭ"
        
        let ruby3 = PoTextRubyAnnotation()
        ruby3.textAfter = "wén zì"
        
        
        text.po.configure { (make) in
            make.setTextRubyAnnotation(ruby1, range: (text.string as NSString).range(of: "这是"))
            make.setTextRubyAnnotation(ruby2, range: (text.string as NSString).range(of: "汉语"))
            make.setTextRubyAnnotation(ruby3, range: (text.string as NSString).range(of: "文字"))
        }
        
        // 与这种写法效果一样
//        text.po.setTextRubyAnnotation(ruby1, range: (text.string as NSString).range(of: "这是"))
//        text.po.setTextRubyAnnotation(ruby2, range: (text.string as NSString).range(of: "汉语"))
//        text.po.setTextRubyAnnotation(ruby3, range: (text.string as NSString).range(of: "文字"))
        
        let label = PoLabel(frame: CGRect(x: 0, y: 0, width: view.width - 20, height: 0))
        label.numberOfLines = 0
        label.attributedText = text
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
    }

}
