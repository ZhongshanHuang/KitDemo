//
//  PoTableView.swift
//  Animation3.0
//
//  Created by 黄山哥 on 2017/5/19.
//  Copyright © 2017年 黄山哥. All rights reserved.
//

import UIKit

@objc protocol PoTableViewDataSource: NSObjectProtocol {
    func tableView(_ tableView: PoTableView, numberOfRowsIn section: Int) -> Int
    func tableView(_ tableView: PoTableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    
    @objc optional func numberOfSections(in tableView: PoTableView) -> Int
}

@objc protocol PoTableViewDelegate: UIScrollViewDelegate {
    @objc optional func tableView(_ tableView: PoTableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    @objc optional func tableView(_ tableView: PoTableView, heightForHeaderIn section: Int) -> CGFloat
    @objc optional func tableView(_ tableView: PoTableView, heightForFooterIn section: Int) -> CGFloat

    @objc optional func tableView(_ tableView: PoTableView, shouldSelectRowAt indexPath: IndexPath) -> Bool
    @objc optional func tableView(_ tableView: PoTableView, willSelectRowAt indexPath: IndexPath)
    @objc optional func tableView(_ tableView: PoTableView, didSelectRowAt indexPath: IndexPath)

    @objc optional func tableView(_ tableView: PoTableView, shouldDeselectRowAt indexPath: IndexPath) -> Bool
    @objc optional func tableView(_ tableView: PoTableView, willDeselectRowAt indexPath: IndexPath)
    @objc optional func tableView(_ tableView: PoTableView, didDeselectRowAt indexPath: IndexPath)
}

private extension PoTableView {
    
    struct DataSourceHas {
        var hasNumberOfRowsInSection = false
    }
    
    struct DelegateHas {
        var hasHeightForRowAtIndexPath = false
        var hasHeightForHeaderInSection = false
        var hasHeightForFooterInSection = false
        var hasShouldSelectRowAtIndexPath = false
        var hasWillSelectRowAtIndexPath = false
        var hasDidSelectRowAtIndexPath = false
        var hasShouldDeselectRowAtIndexPath = false
        var hasWillDeselectRowAtIndexPath = false
        var hasDidDeselectRowAtIndexPath = false
    }
    
    struct PoTableViewLayoutAttributes {
        var frame: CGRect
        var indexPath: IndexPath
    }
}


class PoTableView: UIScrollView {
    //    private(set) var style: UITableViewStyle = .plain
    // 默认cell高度
    var rowHeight: CGFloat = 44
    // headerView
    var tableHeaderView: UIView?
    // footerView
    var tableFooterView: UIView?
    // delegate
    weak var _delegate: PoTableViewDelegate? {
        didSet {
            guard let delegate = _delegate else { _delegateHas = DelegateHas(); return }
            
            _delegateHas.hasHeightForRowAtIndexPath = delegate.responds(to: #selector(PoTableViewDelegate.tableView(_:didSelectRowAt:)))
            _delegateHas.hasHeightForHeaderInSection = delegate.responds(to: #selector(PoTableViewDelegate.tableView(_:heightForHeaderIn:)))
            _delegateHas.hasHeightForFooterInSection = delegate.responds(to: #selector(PoTableViewDelegate.tableView(_:heightForFooterIn:)))
            _delegateHas.hasShouldSelectRowAtIndexPath = delegate.responds(to: #selector(PoTableViewDelegate.tableView(_:shouldSelectRowAt:)))
            _delegateHas.hasWillSelectRowAtIndexPath = delegate.responds(to: #selector(PoTableViewDelegate.tableView(_:willSelectRowAt:)))
            _delegateHas.hasDidSelectRowAtIndexPath = delegate.responds(to: #selector(PoTableViewDelegate.tableView(_:didSelectRowAt:)))
            _delegateHas.hasShouldDeselectRowAtIndexPath = delegate.responds(to: #selector(PoTableViewDelegate.tableView(_:shouldDeselectRowAt:)))
            _delegateHas.hasWillDeselectRowAtIndexPath = delegate.responds(to: #selector(PoTableViewDelegate.tableView(_:willDeselectRowAt:)))
            _delegateHas.hasDidDeselectRowAtIndexPath = delegate.responds(to: #selector(PoTableViewDelegate.tableView(_:didDeselectRowAt:)))
        }
    }
    // dataSource
    weak var _dataSource: PoTableViewDataSource! {
        didSet {
            guard let dataSource = _dataSource else { _dataSourceHas = DataSourceHas(); return }
            _dataSourceHas.hasNumberOfRowsInSection = dataSource.responds(to: #selector(PoTableViewDataSource.numberOfSections(in:)))
        }
    }
    
    private var _sectionItemAttributes: Array<Array<PoTableViewLayoutAttributes>>!
    private var _allItemAttributes: Array<PoTableViewLayoutAttributes>!

    // 重用的cell
    private lazy var reusableCells = Set<UITableViewCell>()
    // 显示中的cell，用来减少创建cell
    private lazy var visibleCells = Dictionary<IndexPath, UITableViewCell>()

    // 是否重新reload
    private var isNeededReload: Bool = false

    // 记录是否实现delegate和dataSource方法
    private var _delegateHas: DelegateHas = DelegateHas()
    private var _dataSourceHas: DataSourceHas = DataSourceHas()
    
    override var frame: CGRect {
        willSet {
            if frame.size == newValue.size { return }
            prepareLayout()
        }
    }
    
    override var bounds: CGRect {
        willSet {
            if bounds.size == newValue.size { return }
            prepareLayout()
        }
    }
    
    // MARK: - Public api
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        
    }

    func setNeedsReload() {
        isNeededReload = true
    }

    func reloadIfNeeded() {
        if isNeededReload {
            reloadData()
        }
    }

    func reloadData() {
        prepareLayout()
        contentSize = tableViewContentSize
    }

    func prepareLayout() {
        let sectionCount = _dataSourceHas.hasNumberOfRowsInSection ? _dataSource.numberOfSections!(in: self) : 1
        if sectionCount < 1 { return }

        // 重置布局信息
        _allItemAttributes = []
        _sectionItemAttributes = []

        var top: CGFloat = 0

        for section in 0..<sectionCount {
            let rowCount = _dataSourceHas.hasNumberOfRowsInSection ? _dataSource.tableView(self, numberOfRowsIn: section) : 0
            if rowCount < 1 { break }
            
            var sectionAttributes = [PoTableViewLayoutAttributes]()
            sectionAttributes.reserveCapacity(rowCount)
            
            for row in 0..<rowCount {
                let rowH = _delegateHas.hasDidDeselectRowAtIndexPath ? _delegate!.tableView!(self, heightForRowAt: IndexPath(row: row, section: section)) : rowHeight
                let rowFrame = CGRect(x: 0, y: top, width: bounds.width, height: rowH)
                let attributes = PoTableViewLayoutAttributes(frame: rowFrame, indexPath: IndexPath(row: row, section: section))
                sectionAttributes.append(attributes)
                _allItemAttributes.append(attributes)
                
                top += rowH
            }
            _sectionItemAttributes.append(sectionAttributes)
        }
    }

    // dequeueReusableCell
    func dequeueReusableCell(withIdentifier identifier: String) -> UITableViewCell? {
        for cell in reusableCells where cell.reuseIdentifier == identifier {
            reusableCells.remove(cell)
            return cell
        }
        return nil
    }

    // 将要显示的时候进行布局
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        reloadData()
    }

    // 滑动的时候会不停调用此方法
    override func layoutSubviews() {
        super.layoutSubviews()

        let visibleAttributes = layoutAttributes(in: CGRect(origin: contentOffset, size: bounds.size))

        for attr in visibleAttributes {
            // 如果已经在显示，则不管
            if let _ = visibleCells[attr.indexPath] { break }
            // 没有显示的cell添加上来
            let cell = _dataSource.tableView(self, cellForRowAt: attr.indexPath)
            cell.frame = attr.frame
            addSubview(cell)
            // 正在显示的cell保存起来
            visibleCells[attr.indexPath] = cell
        }
    }
    
    private func layoutAttributes(in visibleFrame: CGRect) -> [PoTableViewLayoutAttributes] {
        let intersectionIdx = binarySearchIntersectionIndex(with: visibleFrame)
        if intersectionIdx == NSNotFound { return [] }
        
        var visibleAttrs = [PoTableViewLayoutAttributes]()
        // 从交叉点往前找
        for idx in 0..<intersectionIdx {
            let attr = _allItemAttributes[idx]
            if visibleFrame.intersects(attr.frame) {
                visibleAttrs.append(attr)
            } else {
                if let cell = visibleCells[attr.indexPath] {
                    cell.removeFromSuperview()
                    visibleCells.removeValue(forKey: attr.indexPath)
                    reusableCells.insert(cell)
                }
                break
            }
        }
        
        // 这个row已经检测过相交了，所以也添加进来
        visibleAttrs.append(_allItemAttributes[intersectionIdx])
        
        // 从交叉点往后找
        for idx in intersectionIdx..<_allItemAttributes.count {
            let attr = _allItemAttributes[idx]
            if visibleFrame.intersects(attr.frame) {
                visibleAttrs.append(attr)
            } else {
                if let cell = visibleCells[attr.indexPath] {
                    cell.removeFromSuperview()
                    visibleCells.removeValue(forKey: attr.indexPath)
                    reusableCells.insert(cell)
                }
                break
            }
        }
        
        return visibleAttrs
    }
    
    private func binarySearchIntersectionIndex(with targetFrame: CGRect) -> Int {
        var start = 0
        var end = _allItemAttributes.count - 1
        var mid: Int = NSNotFound
        while start <= end {
            mid = (start + end) / 2
            let attrFrame = _allItemAttributes[mid].frame
            if targetFrame.intersects(attrFrame) {
                return mid
            } else if attrFrame.minY < targetFrame.minY {
                end = mid - 1
            } else {
                start = mid + 1
            }
        }
        return mid
    }


    // 宽度有没有发生变化
    func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        if self.bounds.size.width == newBounds.size.width {
            return false
        } else { 
            return true
        }
    }
    
    // 整个布局的size
    var tableViewContentSize: CGSize {
        if _allItemAttributes.count == 0 { return CGSize.zero }
        return CGSize(width: bounds.width, height: _allItemAttributes.last!.frame.maxY)
    }
}

