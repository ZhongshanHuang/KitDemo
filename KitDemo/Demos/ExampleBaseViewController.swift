//
//  ExampleBaseViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class ExampleBaseViewController: UIViewController {

    var padding: NSAttributedString {
        let pad = NSMutableAttributedString(string: "\n\n")
        pad.po.font = UIFont.systemFont(ofSize: 4)
        return pad
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
