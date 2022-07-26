//
//  MZTableView.swift
//  MZTableView
//
//  Created by 曾龙 on 2021/12/20.
//

import UIKit

@objc
public protocol MZTableViewDelegate: NSObjectProtocol {
    
    /// tableView列数
    /// - Parameter tableView: MZTableView
    func tableView(numberOfColumnsIn tableView: MZTableView) -> Int
    
    /// column列对应的cell
    /// - Parameters:
    ///   - tableView: MZTableView
    ///   - column: 列数
    func tableView(_ tableView: MZTableView, cellAt column: Int) -> UIView
    
    /// column列的宽度
    /// - Parameters:
    ///   - tableView: MZTableView
    ///   - column: 列数
    func tableView(_ tableView: MZTableView, widthAt column: Int) -> CGFloat
    
    /// column列被点击了
    /// - Parameters:
    ///   - tableView: MZTableView
    ///   - column: 列数
    @objc optional func tableView(_ tableView: MZTableView, didSelectAt column: Int)
}

open class MZTableView: UIView, UIScrollViewDelegate {
    
    /// 代理
    public weak var delegate: MZTableViewDelegate?
    
    /// 按照页面宽度滚动
    public var isPagingEnabled: Bool = false {
        didSet {
            contentView.isPagingEnabled = isPagingEnabled
        }
    }
    
    /// 额外可见cell个数，用来适配scrollview滚动时cell显示的连续性
    private var extraVisibleCount: Int = 2
    
    /// 滚动组件
    private lazy var contentView: UIScrollView = {
        let contentView = UIScrollView()
        contentView.bounces = false
        contentView.delegate = self
        contentView.showsHorizontalScrollIndicator = false
        return contentView
    }()
    
    /// 可见cell数组，已添加到scrollview中的cell
    private lazy var visibleCellArray: [UIView] = [UIView]()
    
    /// 不可见cell数组，类似复用池的功能
    private lazy var unVisibleCellArray: [UIView] = [UIView]()
    
    /// 存储注册的class
    private lazy var registerDictionary: [String: AnyObject] = [String: AnyObject]()
    
    /// 存储注册的nib
    private lazy var nibForClassDictionary: [String: AnyClass] = [String: AnyClass]()
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        self.addSubview(self.contentView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = self.bounds
        for cell in self.contentView.subviews {
            var frame = cell.frame
            frame.size.height = self.bounds.height
            cell.frame = frame
        }
        self.reloadData()
    }
    
    
    /// 额外可见cell个数，用来适配scrollview滚动时cell显示的连续性
    private func getExtraVisibleCount() -> Int {
        return self.extraVisibleCount
    }
    
    /// 注册class,实现cell复用功能
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - identifier: cell标签
    public func register(_ cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        self.registerDictionary[identifier] = cellClass
    }
    
    /// 注册nib,实现cell复用功能
    /// - Parameters:
    ///   - nib: cell相关nib
    ///   - identifier: cell标签
    public func register(_ nib: UINib?, forCellReuseIdentifier identifier: String) {
        self.registerDictionary[identifier] = nib
        let classObject: AnyClass? = (nib?.instantiate(withOwner: nib, options: nil).first as AnyObject).classForCoder
        self.nibForClassDictionary[identifier] = classObject
    }
    
    /// 通过已组册的identifier来获取cell
    /// - Parameter identifier: cell标签
    /// - Returns: cell
    public func dequeueReusableCell(withIdentifier identifier: String) -> UIView {
        guard let object = self.registerDictionary[identifier] else {
            return UIView()
        }
        
        if object.isKind(of: UINib.classForCoder()) {
            var cell: UIView?
            for index in 0..<self.unVisibleCellArray.count {
                let unVisibleCell = self.unVisibleCellArray[index]
                if unVisibleCell.isKind(of: self.nibForClassDictionary[identifier]!) {
                    cell = unVisibleCell
                    self.unVisibleCellArray.remove(at: index)
                    break
                }
            }
            if cell == nil {
                let nib = object as! UINib
                cell = nib.instantiate(withOwner: nib, options: nil).first as? UIView
            }
            return cell!
        } else {
            var cell: UIView?
            for index in 0..<self.unVisibleCellArray.count {
                let unVisibleCell = self.unVisibleCellArray[index]
                if unVisibleCell.isKind(of: object as! AnyClass) {
                    cell = unVisibleCell
                    self.unVisibleCellArray.remove(at: index)
                    break
                }
            }
            if cell == nil {
                let classObject = object as! UIView.Type
                cell = classObject.init()
            }
            return cell!
        }
    }
    
    
    /// 刷新数据
    /// - Parameter toLeft: 是否滚动到最左边
    public func reloadData(_ toLeft:Bool = false) {
        self.contentView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        
        self.unVisibleCellArray.append(contentsOf: self.visibleCellArray)
        self.visibleCellArray.removeAll()
        
        if toLeft {
            self.contentView.setContentOffset(CGPoint.zero, animated: false)
        }
        
        var width:CGFloat = 0
        var minWidth:CGFloat = self.frame.width
        for i in 0..<(self.delegate?.tableView(numberOfColumnsIn: self))! {
            let itemWidth = (self.delegate?.tableView(self, widthAt: i))!
            if width >= self.contentView.contentOffset.x - itemWidth && width <= self.frame.width + self.contentView.contentOffset.x {
                let cell = (self.delegate?.tableView(self, cellAt: i))!
                self.setupTapGesture(for: cell)
                cell.frame = CGRect(x: width, y: 0, width: itemWidth, height: self.frame.height)
                self.contentView.addSubview(cell)
                self.visibleCellArray.append(cell)
            }
            width += (self.delegate?.tableView(self, widthAt: i))!
            if itemWidth < minWidth {
                minWidth = itemWidth
            }
        }
        self.contentView.contentSize = CGSize(width: width, height: 0)
        
        self.extraVisibleCount = Int(self.frame.width / 2.0 / minWidth) + 1
        if self.extraVisibleCount < 2 {
            self.extraVisibleCount = 2
        }
    }
    
    /// 如果cell未添加过点击事件，则给cell添加点击事件
    private func setupTapGesture(for cell: UIView) {
        if cell.gestureRecognizers == nil || cell.gestureRecognizers?.count == 0 {
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapClicked(_:)))
            cell.addGestureRecognizer(tap)
        }
    }
    
    /// cell点击事件
    @objc private func tapClicked(_ tap: UITapGestureRecognizer) {
        let cell = tap.view!
        let column = self.getColumn(for: cell)
        if self.delegate != nil && self.delegate!.responds(to: #selector(MZTableViewDelegate.tableView(_:didSelectAt:))) {
            self.delegate?.tableView?(self, didSelectAt: column)
        }
    }
    
    //MARK:- UIScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateUI(with: scrollView.contentOffset)
    }
    
    /// 根据scrollview的偏移量来更新UI
    /// - Parameter contentOffset: 偏移量
    func updateUI(with contentOffset: CGPoint) {
        if self.visibleCellArray.count > 0 {
            //如果左边被覆盖的cell个数小于额外可见数，则添加不足的cell到scrollview中，并添加到visibleCellArray中，如果cell是从unVisibleCellArray中取出，则把cell从unVisibleCellArray中移除
            let firstCell = self.visibleCellArray.first!
            let first = self.getFirstColumn(by: contentOffset.x)
            let firstColumn = self.getColumn(for: firstCell)
            if first >= 0 && first <= firstColumn {
                let start = (first - self.getExtraVisibleCount()) >= 0 ? (first - self.getExtraVisibleCount()) : 0
                var originX = -1.0
                for i in (start..<firstColumn).reversed(){
                    if originX < 0.0 {
                        originX = self.getCellOriginX(by: i)
                    }
                    let itemWidth = (self.delegate?.tableView(self, widthAt: i))!
                    let cell = (self.delegate?.tableView(self, cellAt: i))!
                    self.setupTapGesture(for: cell)
                    cell.frame = CGRect(x: originX, y: 0, width: itemWidth, height: self.frame.height)
                    self.contentView.addSubview(cell)
                    self.visibleCellArray.insert(cell, at: 0)
                    for index in 0..<self.unVisibleCellArray.count {
                        let item = self.unVisibleCellArray[index]
                        if item == cell {
                            self.unVisibleCellArray.remove(at: index)
                            break
                        }
                    }
                    originX -= itemWidth
                }
            }
            
            //如果右边被覆盖的cell个数小于额外可见数，则添加不足的cell到scrollview中，并添加到visibleCellArray中，如果cell是从unVisibleCellArray中取出，则把cell从unVisibleCellArray中移除
            let lastCell = self.visibleCellArray.last!
            let last = self.getLastColumn(by: contentOffset.x)
            let columnCount = (self.delegate?.tableView(numberOfColumnsIn: self))!
            if last <= columnCount - 1 && last >= self.getColumn(for: lastCell) {
                let end = last + self.getExtraVisibleCount() < columnCount ? last + self.getExtraVisibleCount() : columnCount
                var originX = -1.0
                for i in (self.getColumn(for: lastCell) + 1)..<end {
                    if originX < 0.0 {
                        originX = self.getCellOriginX(by: i)
                    }
                    let itemWidth = (self.delegate?.tableView(self, widthAt: i))!
                    let cell = (self.delegate?.tableView(self, cellAt: i))!
                    self.setupTapGesture(for: cell)
                    cell.frame = CGRect(x: originX, y: 0, width: itemWidth, height: self.frame.height)
                    self.contentView.addSubview(cell)
                    self.visibleCellArray.append(cell)
                    for index in 0..<self.unVisibleCellArray.count {
                        let item = self.unVisibleCellArray[index]
                        if item == cell {
                            self.unVisibleCellArray.remove(at: index)
                            break
                        }
                    }
                    originX += itemWidth
                }
            }
        }
        
        if self.visibleCellArray.count >= self.getExtraVisibleCount() {
            //如果左边被覆盖的cell个数超过额外可见数，则从scrollview中移除超过的cell，从visibleCellArray中移除该对象，并将该对象添加到unVisibleCellArray
            var i:Int = (self.getExtraVisibleCount() - 1)
            while i < self.visibleCellArray.count {
                let cell = self.visibleCellArray[i]
                if cell.frame.minX < contentOffset.x {
                    let unVisibleCell = self.visibleCellArray[i - (self.getExtraVisibleCount() - 1)]
                    unVisibleCell.removeFromSuperview()
                    self.unVisibleCellArray.append(unVisibleCell)
                    self.visibleCellArray.remove(at: i - (self.getExtraVisibleCount() - 1))
                } else {
                    i += 1
                }
            }
        }
        
        if self.visibleCellArray.count > self.getExtraVisibleCount() {
            //如果右边被覆盖的cell个数超过额外可见数，则从scrollview中移除超过的cell，从visibleCellArray中移除该对象，并将该对象添加到unVisibleCellArray
            var i: Int = self.visibleCellArray.count-self.getExtraVisibleCount()
            while i >= 0 {
                let cell = self.visibleCellArray[i]
                if cell.frame.maxX > contentOffset.x + self.frame.width {
                    let unVisibleCell = self.visibleCellArray[i + (self.getExtraVisibleCount() - 1)]
                    unVisibleCell.removeFromSuperview()
                    self.unVisibleCellArray.append(unVisibleCell)
                    self.visibleCellArray.remove(at: i + (self.getExtraVisibleCount() - 1))
                }
                i -= 1
            }
        }
    }
    
    //MARK:- Private Method
    
    /// 根据scrollview的偏移量来获取屏幕最左边显示的是第几列
    /// - Parameter contentOffset: 偏移量
    /// - Returns: 第几列
    private func getFirstColumn(by contentOffset: CGFloat) -> Int {
        var totalWidth:CGFloat = 0
        for i in 0..<(self.delegate?.tableView(numberOfColumnsIn: self))! {
            let width = (self.delegate?.tableView(self, widthAt: i))!
            if totalWidth <= contentOffset && (totalWidth + width) > contentOffset{
                return i
            } else {
                totalWidth += width
            }
        }
        return 0
    }
    
    /// 根据scrollview的偏移量来获取屏幕最右边显示的是第几列
    /// - Parameter contentOffset: 偏移量
    /// - Returns: 第几列
    private func getLastColumn(by contentOffset: CGFloat) -> Int {
        var totalWidth:CGFloat = 0
        for i in 0..<(self.delegate?.tableView(numberOfColumnsIn: self))! {
            let width = (self.delegate?.tableView(self, widthAt: i))!
            if totalWidth <= (contentOffset + self.frame.width) && (totalWidth + width) > (contentOffset + self.frame.width) {
                return i
            } else {
                totalWidth += width
            }
        }
        return 0
    }
    
    /// 根据cell对象来获取改cell是第几列
    /// - Parameter cell: cell对象
    /// - Returns: 第几列
    private func getColumn(for cell: UIView) -> Int {
        var totalWidth: CGFloat = 0
        for i in 0..<(self.delegate?.tableView(numberOfColumnsIn: self))! {
            totalWidth += (self.delegate?.tableView(self, widthAt: i))!
            if cell.frame.maxX == totalWidth {
                return i
            }
        }
        return 0
    }
    
    /// 根据cell列数获取到cell的x
    /// - Parameter column: 列数
    /// - Returns: cell的其实位置
    private func getCellOriginX(by column: Int) -> CGFloat {
        var x: CGFloat = 0
        for i in 0..<column {
            x += (self.delegate?.tableView(self, widthAt: i))!
        }
        return x
    }
}
