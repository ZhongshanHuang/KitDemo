//
//  HighlightViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class HighlightViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString()
        
        let linkText1 = NSMutableAttributedString(string: "link1-link2")
        linkText1.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.textUnderline = PoTextDecoration(style: .single, width: 2, color: .blue, shadow: nil)
            //            make.underlineStyle = NSUnderlineStyle.single.rawValue
            make.foregroundColor = .blue
            
            let hl1 = PoTextHighlight(backgroundColor: .red)
            hl1.tapAction = { (_, _, _, _) in
                print("link1 tap")
            }
            make.setTextHighlight(hl1, range: NSRange(location: 0, length: 5))
            
            let hl2 = PoTextHighlight(backgroundColor: .yellow)
            hl2.tapAction = { (_, _, _, _) in
                print("link2 tap")
            }
            make.setTextHighlight(hl2, range: NSRange(location: 6, length: 5))
        }
        text.append(linkText1)
        text.append(padding)
        
        
        let h2 = NSMutableAttributedString(string: "another link")
        h2.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.textBorder = PoTextBorder(lineStyle: [.single, .patternDot], lineWidth: 1, strokeColor: .red, cornerRadius: 5)
            make.foregroundColor = .red
            let hl = PoTextHighlight(attributes: [.backgroundColor: UIColor.red, .foregroundColor: UIColor.white])
            let border = PoTextBorder(fillColor: .red, cornerRadius: 5)
            border.strokeWidth = 0
            hl.border = border
            hl.tapAction = { (_, _, _, _) in
                print("another link tap")
            }
            make.textHighlight = hl
        }
        text.append(h2)
        text.append(padding)
        
        
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
