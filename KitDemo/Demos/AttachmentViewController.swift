//
//  AttachmentViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/26.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit

class AttachmentViewController: ExampleBaseViewController {

    var label: PoLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let text = NSMutableAttributedString()
        let font = UIFont.systemFont(ofSize: 16)
        
        do {
            let title = "This is UIImage attachment:"
            text.append(NSAttributedString(string: title))
            
            var image = UIImage(named: "dribbble64_imageio")!
            image = UIImage(cgImage: image.cgImage!, scale: 2, orientation: .up)
            
            let attachText = NSMutableAttributedString.po.attachmentStringWithContent(image, contentMode: .center, size: image.size, alignToFont: font, alignment: .center)
            text.append(attachText)
            text.append(NSAttributedString(string: "\n"))
        }
        
        do {
            let title = "This is UIView attachment:"
            text.append(NSAttributedString(string: title))
            
            let switcher = UISwitch()
            switcher.sizeToFit()
            
            let attachText = NSMutableAttributedString.po.attachmentStringWithContent(switcher, contentMode: .center, size: switcher.size, alignToFont: font, alignment: .center)
            text.append(attachText)
            text.append(NSAttributedString(string: "\n"))
        }
        
        do {
            let title = "This is Animated Image attachment:"
            text.append(NSAttributedString(string: title))
            
            if let bundlepath = Bundle.main.path(forResource: "EmoticonQQ", ofType: ".bundle"), let bundle = Bundle(path: bundlepath) {
                for name in ["001.gif", "022.gif", "019.gif", "056.gif", "085.gif"] {
                    let image = PoImage(named: name, bundle: bundle)
                    image?.preloadAllAnimatedImageFrames = true
                    let imageView = PoAnimatedImageView(image: image)
                    let attachText = NSMutableAttributedString.po.attachmentStringWithContent(imageView, contentMode: .center, size: imageView.size, alignToFont: font, alignment: .center)
                    text.append(attachText)
                }
            }
            
            let image = PoImage(named: "pia");
            image?.preloadAllAnimatedImageFrames = true
            let imageView = PoAnimatedImageView(image: image)
            imageView.autoPlayAnimatedImage = false
            imageView.startAnimating()
            
            let attachText = NSMutableAttributedString.po.attachmentStringWithContent(imageView, contentMode: .center, size: imageView.size, alignToFont: font, alignment: .center)
            text.append(attachText)
            text.append(NSAttributedString(string: "\n"))
        }
        
        
        text.po.font = font
        
        
        label = PoLabel()
        label.numberOfLines = 0
        label.textVerticalAlignment = .top
        label.size = CGSize(width: 260, height: 260)
        label.center = view.center
        label.attributedText = text
        addSeeMoreButton()
        view.addSubview(label)
        
        label.layer.borderWidth = 0.5
        label.layer.borderColor = UIColor(red: 0, green: 0.436, blue: 1, alpha: 1).cgColor
        
        let dot = newDotView()
        dot.center = CGPoint(x: label.width, y: label.height)
        dot.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        label.addSubview(dot)
        
        let gesture = PoGestureRecognizer()
        gesture.action = { [weak self] (gesture, state) in
            guard let self = self else { return }
            if state != .moved { return }
            let width = gesture.currentPoint.x
            let height = gesture.currentPoint.y
            self.label.width = width < 30 ? 30 : width
            self.label.height = height < 30 ? 30 : height
        }
        gesture.delegate = self
        label.addGestureRecognizer(gesture)
    }
    
    
    private func addSeeMoreButton() {
        
        let text = NSMutableAttributedString(string: "...more")
        
        let hi = PoTextHighlight()
        hi.foregroundColor = UIColor(red: 0.578, green: 0.79, blue: 1, alpha: 1)
        hi.tapAction = { [weak self] (_, _, _, _) in
            guard let self = self else { return }
            self.label.sizeToFit()
        }
        text.po.setForegroundColor(UIColor(red: 0, green: 0.449, blue: 1, alpha: 1), range: (text.string as NSString).range(of: "more"))
        text.po.setTextHighlight(hi, range: (text.string as NSString).range(of: "more"))
        text.po.font = self.label.font
        
        let seeMore = PoLabel()
        seeMore.attributedText = text
        seeMore.sizeToFit()
        
        let truncationToken = NSMutableAttributedString.po.attachmentStringWithContent(seeMore, contentMode: .center, size: seeMore.size, alignToFont: text.po.font!, alignment: .center)
        label.truncationToken = truncationToken
    }
    
    private func newDotView() -> UIView {
        let view = UIView()
        view.size = CGSize(width: 50, height: 50)
        
        let dot = UIView()
        dot.size = CGSize(width: 10, height: 10)
        dot.backgroundColor = UIColor(red: 0, green: 0.463, blue: 1, alpha: 1)
        dot.clipsToBounds = true
        dot.layer.cornerRadius = dot.width / 2
        dot.center = CGPoint(x: view.width / 2, y: view.height / 2)
        view.addSubview(dot)
        
        return view
    }
    
}

extension AttachmentViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let p = gestureRecognizer.location(in: label)
        if p.x < label.width - 40 { return false }
        if p.y < label.height - 40 { return false }
        return true
    }
}
