////
////  PoCollectionViewMasonryLayout2.swift
////  MasonryCollectionView
////
////  Created by HzS on 16/4/12.
////  Copyright © 2016年 HzS. All rights reserved.
////
//
import UIKit


@objc protocol PoCollectionViewMasonryLayoutDelegate {

    // MARK: height methods
    func collectionViewMasonryLayout(_ collectionView: UICollectionView, layout: PoCollectionViewMasonryLayout, heightForItemAtIndexPath indexPath: IndexPath) -> CGFloat

    @objc optional func collectionViewMasonryLayout(_ collectionView: UICollectionView, layout: PoCollectionViewMasonryLayout, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat

    @objc optional func collectionViewMasonryLayout(_ collectionView: UICollectionView, layout: PoCollectionViewMasonryLayout, heightForFooterAtIndexPath indexPath: IndexPath) -> CGFloat

    // MARK: insets methods
    @objc optional func collectionViewMasonryLayout(_ collectionView: UICollectionView, layout: PoCollectionViewMasonryLayout, insetsForSection section: Int) -> UIEdgeInsets

    @objc optional func collectionViewMasonryLayout(_ collectionView: UICollectionView, layout: PoCollectionViewMasonryLayout, insetsForHeader section: Int) -> UIEdgeInsets

    @objc optional func collectionViewMasonryLayout(_ collectionView: UICollectionView, layout: PoCollectionViewMasonryLayout, insetsForFooter section: Int) -> UIEdgeInsets
}


class PoCollectionViewMasonryLayout: UICollectionViewLayout {
    // MARK: Public property
    var columnCount: Int = 3
    var minColumnSpacing: CGFloat = 10
    var minInterItemSpacing: CGFloat = 10

    var headerHeight: CGFloat = 0.0
    var footerHeight: CGFloat = 0.0

    var sectionInsets: UIEdgeInsets = UIEdgeInsets()
    var headerInsets: UIEdgeInsets = UIEdgeInsets()
    var footerInsets: UIEdgeInsets = UIEdgeInsets()


    // MARK: Private property
    private var _masonryDelegate: PoCollectionViewMasonryLayoutDelegate {
        return collectionView!.delegate as! PoCollectionViewMasonryLayoutDelegate
    }
    private var _columnHeights: ContiguousArray<ContiguousArray<CGFloat>>!
    private var _sectionItemAttributes: Array<Array<UICollectionViewLayoutAttributes>>!
    private var _allItemAttributes: Array<UICollectionViewLayoutAttributes>!
    private var _headerAttributes: Dictionary<Int, UICollectionViewLayoutAttributes>!
    private var _footerAttributes: Dictionary<Int, UICollectionViewLayoutAttributes>!


    // MARK: Override
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if collectionView!.bounds.size.width == newBounds.size.width {
            return false
        }
        return true
    }

    override func prepare() {
        let sectionCount = collectionView!.numberOfSections
        if sectionCount == 0 { return }
        //信息重置
        _columnHeights = []
        _sectionItemAttributes = []
        _allItemAttributes = []
        _headerAttributes = [:]
        _footerAttributes = [:]

        let columnInSection = ContiguousArray<CGFloat>(repeating: 0.0, count: columnCount)
        _columnHeights = ContiguousArray<ContiguousArray<CGFloat>>(repeating: columnInSection, count: sectionCount)
        var top: CGFloat = 0
        var attributes: UICollectionViewLayoutAttributes

        for section in 0..<sectionCount {
            var sectionInset: UIEdgeInsets = sectionInsets

            if let insets = _masonryDelegate.collectionViewMasonryLayout?(collectionView!, layout: self, insetsForSection: section) {
                sectionInset = insets
            }
            var headerInset: UIEdgeInsets = headerInsets
            if let insets = _masonryDelegate.collectionViewMasonryLayout?(collectionView!, layout: self, insetsForHeader: section) {
                headerInset = insets
            }
            var footerInset: UIEdgeInsets = footerInsets
            if let insets = _masonryDelegate.collectionViewMasonryLayout?(collectionView!, layout: self, insetsForFooter: section) {
                footerInset = insets
            }

            //header
            top += headerInset.top
            if headerHeight > 0 {
                let headerWidth = collectionView!.bounds.size.width - (headerInsets.left + headerInsets.right)
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: headerInset.left, y: top, width: headerWidth, height: headerHeight)

                _headerAttributes[section] = attributes
                _allItemAttributes.append(attributes)
                top = attributes.frame.maxY + headerInset.bottom
            }
            top += sectionInset.top
            for idx in 0..<columnCount {
                _columnHeights[section][idx] = top
            }

            //item
            let itemWidth = (collectionView!.bounds.size.width - (sectionInset.left + sectionInset.right) - CGFloat(columnCount - 1)*minColumnSpacing ) / CGFloat(columnCount)
            top += sectionInset.bottom
            var itemAttributesArray = Array<UICollectionViewLayoutAttributes>()

            for item in 0..<collectionView!.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                let currentColumn = findShortestColumnIn(section: section)
                let itemX = sectionInset.left + (itemWidth + minColumnSpacing)*CGFloat(currentColumn.column)
                let itemY = currentColumn.height
                let itemHeight = _masonryDelegate.collectionViewMasonryLayout(collectionView!, layout: self, heightForItemAtIndexPath: indexPath)
                attributes.frame = CGRect(x: itemX, y: itemY, width: itemWidth, height: itemHeight).integral

                itemAttributesArray.append(attributes)
                _allItemAttributes.append(attributes)
                _columnHeights[section][currentColumn.column] = attributes.frame.maxY + minInterItemSpacing
            }
            _sectionItemAttributes.append(itemAttributesArray)

            //footer
            top = findTallestColumnIn(section: section) - minInterItemSpacing + sectionInsets.bottom
            top += footerInset.top
            if footerHeight > 0 {
                let footerWidth = collectionView!.bounds.size.width - (footerInsets.left + footerInsets.right)
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: footerInset.left, y: top, width: footerWidth, height: footerHeight)
                _footerAttributes[section] = attributes
                _allItemAttributes.append(attributes)
                top = attributes.frame.maxY + footerInset.bottom
            }

            for index in 0..<columnCount {
                _columnHeights[section][index] = top
            }
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let matchIndex = _binarySearchForIntersectsAttributes(array: _allItemAttributes, in: rect)
        if matchIndex < 0 {
            return nil
        } else {
            var result = [UICollectionViewLayoutAttributes]()

            // 从后向前反向遍历
            for attributes in _allItemAttributes[..<matchIndex].reversed() {
                guard attributes.frame.maxY >= rect.minY else { break }
                result.append(attributes)
            }

            // 从前往后正向遍历
            for attributes in _allItemAttributes[matchIndex...] {
                guard attributes.frame.minY <= rect.maxY else { break }
                result.append(attributes)
            }

            return  result
        }
    }

    private func _binarySearchForIntersectsAttributes(array: [UICollectionViewLayoutAttributes], in rect: CGRect) -> Int {
        var low = 0
        var hight = array.count - 1
        var mid = 0
        while low <= hight {
            mid = (low + hight) / 2
            if array[mid].frame.intersects(rect) {
                return mid
            } else if array[mid].frame.maxY < rect.minY {
                low = mid + 1
            } else  { // array[mid].frame.minY > rect.maxY
                hight = mid - 1
            }
        }
        return -1
    }

    //contentSize
    override var collectionViewContentSize: CGSize {
        let sectionCount = collectionView!.numberOfSections
        return CGSize(width: collectionView!.bounds.width, height: _columnHeights[sectionCount - 1][0])
    }
    //item
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < collectionView!.numberOfSections && indexPath.item < collectionView!.numberOfItems(inSection: indexPath.section) else {
            return nil
        }
        return _sectionItemAttributes[indexPath.section][indexPath.item]
    }
    //header
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < collectionView!.numberOfSections else { return nil }

        if elementKind == UICollectionView.elementKindSectionHeader {
            return _headerAttributes[indexPath.section]
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            return _footerAttributes[indexPath.section]
        } else {
            return nil
        }
    }

    // Private method
    func findShortestColumnIn(section: Int) -> (column: Int, height: CGFloat) {
        let array = _columnHeights[section]
        var shortest: CGFloat = _columnHeights[section][0]
        var index: Int = 0
        for (column, height) in array.enumerated() {
            if shortest > height {
                shortest = height
                index = column
            }
        }
        return (index, shortest)
    }

    func findTallestColumnIn(section: Int) -> CGFloat {
        let array = _columnHeights[section]
        var tallest: CGFloat = _columnHeights[section][0]
        for height in array {
            if tallest < height {
                tallest = height
            }
        }
        return tallest
    }

}
