//
//  ViewController.swift
//  MZTableView
//
//  Created by 曾龙 on 2021/12/20.
//

import UIKit

let SCREEN_WIDTH = UIScreen.main.bounds.size.width

class ViewController: UIViewController, MZTableViewDelegate {
    func tableView(numberOfColumnsIn tableView: MZTableView) -> Int {
        return self.count
    }
    
    func tableView(_ tableView: MZTableView, cellAt column: Int) -> UIView {
        if tableView == otherTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OtherTableViewCell") as! OtherTableViewCell
            cell.imageView.image = self.images[column % 3]
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") as! TableViewCell
            cell.titleLB.text = "第\(column + 1)列"
            cell.titleLB.backgroundColor = self.colors[column % 4]
            return cell
        }
    }
    
    func tableView(_ tableView: MZTableView, widthAt column: Int) -> CGFloat {
        if tableView == otherTableView {
            return 150
        }
        return CGFloat(column % 3) * 50.0 + 100.0
    }
    
    func tableView(_ tableView: MZTableView, didSelectAt column: Int) {
        if tableView == otherTableView {
            print("otherTableView的第\(column+1)行被点击了")
        } else {
            print("tableView的第\(column+1)行被点击了")
        }
    }
    

    lazy var tableView: MZTableView = {
        let tableView = MZTableView(frame: CGRect(x: 0, y: 100, width: SCREEN_WIDTH, height: 100))
        tableView.delegate = self
        tableView.isPagingEnabled = true
        tableView.register(TableViewCell.classForCoder(), forCellReuseIdentifier: "TableViewCell")
        return tableView
    }()
    
    @IBOutlet weak var otherTableView: MZTableView!
    
    var count: Int = 1000
    var images: [UIImage?] = [UIImage(named: "0"), UIImage(named: "1"), UIImage(named: "2")]
    var colors: [UIColor] = [.black, .brown, .orange, .gray]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
        otherTableView.register(UINib(nibName: "OtherTableViewCell", bundle: nil), forCellReuseIdentifier: "OtherTableViewCell")
        otherTableView.delegate = self
    }

    @IBAction func refreshData(_ sender: Any) {
        self.count = 300
        self.images = [UIImage(named: "4"), UIImage(named: "5"), UIImage(named: "6")]
        self.colors = [.magenta, .blue, .cyan, .purple]
        self.tableView.reloadData()
        self.otherTableView.reloadData(true)
    }
}

