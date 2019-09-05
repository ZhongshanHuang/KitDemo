//
//  ForegroundBorderViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class ForegroundBorderViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString()
        
        let borderText1 = NSMutableAttributedString(string: "Single")
        borderText1.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = UIColor(hex: "#fa3f39")
            make.textBorder = PoTextBorder(lineStyle: .single,
                                           lineWidth: 2,
                                           strokeColor: UIColor(hex: "#fa3f39"),
                                           cornerRadius: 10,
                                           insets: UIEdgeInsets(top: 0, left: -2, bottom: 0, right: -2))
        }
        text.append(borderText1)
        text.append(padding)
        text.append(padding)
        text.append(padding)
        
        
        let borderText2 = NSMutableAttributedString(string: "Double")
        borderText2.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = UIColor(hex: "#f48f25")
            make.textBorder = PoTextBorder(lineStyle: .double,
                                           lineWidth: 1,
                                           strokeColor: UIColor(hex: "#f48f25"),
                                           cornerRadius: 10,
                                           insets: UIEdgeInsets(top: 0, left: -2, bottom: 0, right: -2))
        }
        text.append(borderText2)
        text.append(padding)
        text.append(padding)
        text.append(padding)
        
        
        let borderText3 = NSMutableAttributedString(string: "Single&PatterDot")
        borderText3.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = UIColor(hex: "#f1c02c")
            make.textBorder = PoTextBorder(lineStyle: [.single, .patternDot],
                                           lineWidth: 3,
                                           strokeColor: UIColor(hex: "#f1c02c"),
                                           cornerRadius: 10,
                                           insets: UIEdgeInsets(top: 0, left: -2, bottom: 0, right: -2))
        }
        text.append(borderText3)
        text.append(padding)
        text.append(padding)
        text.append(padding)
        
        
        let borderText4 = NSMutableAttributedString(string: "Double&PatternDash")
        borderText4.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = UIColor(hex: "#54bc2e")
            make.textBorder = PoTextBorder(lineStyle: [.double, .patternDash],
                                           lineWidth: 1,
                                           strokeColor: UIColor(hex: "#54bc2e"),
                                           cornerRadius: 10,
                                           insets: UIEdgeInsets(top: 0, left: -2, bottom: 0, right: -2))
        }
        text.append(borderText4)
        text.append(padding)
        text.append(padding)
        text.append(padding)
        
        
        let borderText5 = NSMutableAttributedString(string: "Single&PatternDashDot")
        borderText5.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = UIColor(hex: "#012060")
            make.textBorder = PoTextBorder(lineStyle: [.single, .patternDashDot],
                                           lineWidth: 3,
                                           strokeColor: UIColor(hex: "#012060"),
                                           cornerRadius: 10,
                                           insets: UIEdgeInsets(top: 0, left: -2, bottom: 0, right: -2))
        }
        text.append(borderText5)
        text.append(padding)
        text.append(padding)
        text.append(padding)
        
        
        let borderText6 = NSMutableAttributedString(string: "Single&PatternDashDotDot")
        borderText6.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = UIColor(hex: "#29a9ee")
            make.textBorder = PoTextBorder(lineStyle: [.single, .patternDashDotDot],
                                           lineWidth: 3,
                                           strokeColor: UIColor(hex: "#29a9ee"),
                                           cornerRadius: 10,
                                           insets: UIEdgeInsets(top: 0, left: -2, bottom: 0, right: -2))
        }
        text.append(borderText6)
        text.append(padding)
        text.append(padding)
        text.append(padding)
        
        let borderText7 = NSMutableAttributedString(string: "Single&PatternCircleDot")
        borderText7.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = UIColor(hex: "#c171d8")
            make.textBorder = PoTextBorder(lineStyle: [.single, .patternCircleDot],
                                           lineWidth: 3,
                                           strokeColor: UIColor(hex: "#c171d8"),
                                           cornerRadius: 10,
                                           insets: UIEdgeInsets(top: 0, left: -2, bottom: 0, right: -2))
        }
        text.append(borderText7)

        
        
        let label = PoLabel()
        label.numberOfLines = 0
        label.frame = view.bounds
        label.attributedText = text
        label.backgroundColor = UIColor(white: 0.933, alpha: 1)
        label.textAlignment = .center
        label.textVerticalAlignment = .center
        view.addSubview(label)
        
    }
    
}
