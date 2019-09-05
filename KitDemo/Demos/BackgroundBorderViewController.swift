//
//  BorderViewController.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/8/25.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class BackgroundBorderViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString()
        
        let tags = ["◉red", "◉orange", "◉yellow", "◉green", "◉cyan", "◉blue", "◉purple"]
        let tagStrokeColors = [UIColor(hex: "#fa3f39"),
                               UIColor(hex: "#f48f25"),
                               UIColor(hex: "#f1c02c"),
                               UIColor(hex: "#54bc2e"),
                               UIColor(hex: "#012060"),
                               UIColor(hex: "#29a9ee"),
                               UIColor(hex: "#c171d8")]
        let tagFillColors = [UIColor(hex: "#fb6560"),
                             UIColor(hex: "#f6a550"),
                             UIColor(hex: "#f3cc56"),
                             UIColor(hex: "#76c957"),
                             UIColor(hex: "#012060"),
                             UIColor(hex: "#53baf1"),
                             UIColor(hex: "#cd8ddf")]
        let font = UIFont.boldSystemFont(ofSize: 16)
        
        var i = 0
        while i < tags.count {
            defer { i += 1 }
            let tag = tags[i]
            let tagStrokeColor = tagStrokeColors[i]
            let tagFillColor = tagFillColors[i]
            let tagText = NSMutableAttributedString(string: tag)
            tagText.po.configure { (make) in
                make.insert("   ", at: 0)
                make.append("   ")
                make.font = font
                make.foregroundColor = UIColor.white
                
                let border = PoTextBorder(fillColor: tagFillColor, cornerRadius: 10, insets: UIEdgeInsets(top: -2, left: -5.5, bottom: -2, right: -8))
                border.strokeWidth = 1.5
                border.strokeColor = tagStrokeColor
                border.lineJoin = .bevel
                make.setTextBorder(border, range: (tagText.string as NSString).range(of: tag))
            }
            
            text.append(tagText)
        }
        
        
        text.po.lineSpacing = 10

        
        let label = PoLabel()
        label.numberOfLines = 0
        label.frame = view.bounds
        label.attributedText = text
        label.backgroundColor = UIColor(white: 0.933, alpha: 1)
        view.addSubview(label)

    }

}
