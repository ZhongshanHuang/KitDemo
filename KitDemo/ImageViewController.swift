//
//  ImageViewController.swift
//  KitDemo
//
//  Created by 黄中山 on 2019/11/12.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let gif = PoImage(named: "huocai.gif")
        let imageView1 = PoAnimatedImageView(image: gif)
        imageView1.frame.origin = CGPoint(x: 0, y: 0)
        view.addSubview(imageView1)
        
        let apng = PoImage(named: "apng.png")
        let imageView2 = PoAnimatedImageView(image: apng)
        imageView2.frame.origin = CGPoint(x: 0, y: imageView1.bottom)
        view.addSubview(imageView2)
        
        let encode = PoImageEncoder(type: .png)
        for i in 1...4 {
            encode?.add(image: UIImage(named: "p\(i).png")!, duration: 1)
        }
        let customAPNG = PoImage(data: encode!.encode()!)
        let imageView3 = PoAnimatedImageView(image: customAPNG)
        imageView3.frame.origin = CGPoint(x: 0, y: imageView2.bottom)
        view.addSubview(imageView3)
        
        let path = Bundle.main.path(forResource: "beauty", ofType: "png")
        let image = PoImage(contentsOfFile: path!)
        if let new = image?.cgImage?.copy(withOrientation: .right) {
            let leftImage = PoImage(cgImage: new)
            let imageView4 = PoAnimatedImageView(image: leftImage)
            imageView4.frame.origin = CGPoint(x: 0, y: imageView3.bottom)
            view.addSubview(imageView4)
        }
        
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
