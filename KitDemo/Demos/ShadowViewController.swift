//
//  ShadowViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class ShadowViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString()
        
        let shadowText = NSMutableAttributedString(string: "Shadow")
        shadowText.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = .white
            make.textShadow = PoTextShadow(color: UIColor(white: 0, alpha: 0.49), offset: CGSize(width: 0, height: 1), blur: 5)
        }
        text.append(shadowText)
        text.append(padding)
        
        
        let innerShadowText = NSMutableAttributedString(string: "Inner Shadow")
        innerShadowText.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = .white
            make.textInnerShadow = PoTextShadow(color: UIColor(white: 0, alpha: 0.4), offset: CGSize(width: 0, height: 1), blur: 1)
        }
        text.append(innerShadowText)
        text.append(padding)
        
        
        let multipleShadowText = NSMutableAttributedString(string: "Multiple Shadow")
        multipleShadowText.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = UIColor(red: 1, green: 0.795, blue: 0.014, alpha: 1)
            
            let shadow = PoTextShadow(color: UIColor(white: 0, alpha: 0.2), offset: CGSize(width: 0, height: -1), blur: 1.5)
            let subShadow = PoTextShadow(color: UIColor(white: 1, alpha: 0.99), offset: CGSize(width: 0, height: 1), blur: 1.5)
            shadow.subShadow = subShadow
            make.textShadow = shadow
            
            make.textInnerShadow = PoTextShadow(color: UIColor(red: 0.851, green: 0.311, blue: 0, alpha: 0.78), offset: CGSize(width: 0, height: 1), blur: 1)
        }
        text.append(multipleShadowText)
        text.append(padding)
        
        
        let ctShadow = NSMutableAttributedString(string: "Core Text Shadow")
        ctShadow.po.configure { (make) in
            make.font = UIFont.systemFont(ofSize: 30)
            make.foregroundColor = .white
            let shadow = NSShadow()
            shadow.shadowOffset = CGSize(width: 0, height: 2)
            shadow.shadowBlurRadius = 1.5
            shadow.shadowColor = UIColor.gray
            make.shadow = shadow
        }
        text.append(ctShadow)
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
