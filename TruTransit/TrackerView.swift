//
//  TrackerView.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/3/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit

class TrackerView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = 7
        self.layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
        self.layer.shouldRasterize = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code

        let whitePath = UIBezierPath(ovalIn: rect)
        whitePath.lineWidth = 1.0
        UIColor.white.setFill()
        UIColor.white.setStroke()
        whitePath.stroke()
        whitePath.fill()
        let colorPath = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: (rect.width)*0.1875, y: (rect.height)*0.1875), size: CGSize(width: rect.width*0.625, height: rect.height*0.625)))
        colorPath.lineWidth = 1.0
        UIColor.gold().setFill()
        UIColor.gold().setStroke()
        colorPath.stroke()
        colorPath.fill()
    }
 
    var onDidSetHidden: ((Bool) -> ())?
    
    override var isHidden: Bool {
        didSet {
            onDidSetHidden?(self.isHidden)
        }
    }
}
