//
//  TableViewCell.swift
//  MZTableView
//
//  Created by 曾龙 on 2021/12/20.
//

import UIKit

class TableViewCell: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    lazy var titleLB: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    func setup() {
        self.addSubview(titleLB)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.titleLB.frame = self.bounds
    }

}
