//
//  ViewController.swift
//  KitDemo
//
//  Created by 黄中山 on 2018/5/21.
//  Copyright © 2018年 黄中山. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var tableView: UITableView = UITableView(frame: .zero, style: .plain)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.estimatedRowHeight = 0
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.frame = view.bounds
        view.addSubview(tableView)

        tableView.register(Cell.self, forCellReuseIdentifier: "cell")
//        test()
//        let path = Bundle.main.path(forResource: "dribbble64_imageio", ofType: "png")
//        let image = UIImage(contentsOfFile: path!)
//        let new = PoCGImageCreateCopyWithOrientation(imageRef: image!.cgImage!, orientation: .left)
//        print(new)
    }
    
    private func test() {
//        let image = PoImage(named: "apng.png")
//        let imageView = PoAnimatedImageView(image: PoImage(named: "huocai.gif"))
//        imageView.image = image
//        imageView.center = view.center
//        view.addSubview(imageView)
        
//        let encode = PoImageEncoder(type: .png)
//        for i in 1...4 {
//            let path = Bundle.main.path(forResource: "\(i)", ofType: ".png")
//            encode?.add(image: UIImage(named: "p\(i).png")!, duration: 1)
//        }
        
//        let image = PoImage(data: encode!.encode()!)
        
        let image = PoImage(named: "beauty")
        let imageView = PoAnimatedImageView(image: image)
        imageView.center = view.center
        view.addSubview(imageView)
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DemoType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell
        cell.lable.text = DemoType.allCases[indexPath.row].rawValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var vc: UIViewController!
        let type = DemoType.allCases[indexPath.row]
        switch type {
        case .highlight:
            vc = HighlightViewController()
        case .shadow:
            vc = ShadowViewController()
        case .foregroundBorder:
            vc = ForegroundBorderViewController()
        case .backgroundBorder:
            vc = BackgroundBorderViewController()
        case .blockBorder:
            vc = BlockBorderViewController()
        case .rubyAnnotation:
            vc = RubyAnnotationViewController()
        case .attachment:
            vc = AttachmentViewController()
        case .underline:
            vc = UnderlineViewController()
        case .strikethrough:
            vc = StrikethroughViewController()
        case .glyphTransform:
            vc = GlyphTransformViewController()
        case .kern:
            vc = KernViewController()
        case .stroke:
            vc = StrokeViewController()
        case .ligature:
            vc = LigatureViewController()
        }
        vc.title = type.rawValue
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Cell

class Cell: UITableViewCell {
    
    let lable: PoLabel = PoLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        lable.frame = bounds
        lable.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(lable)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - DemoType

enum DemoType: String, CaseIterable {
    case highlight
    case shadow
    case foregroundBorder
    case backgroundBorder
    case blockBorder
    case rubyAnnotation
    case attachment
    case underline
    case strikethrough
    case glyphTransform
    case kern
    case stroke
    case ligature
}

