//
//  RightArrowView.swift
//  TruTransit
//
//  Created by Satbir Tanda on 10/16/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit

class RightArrowView: MaterialButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
//        self.layer.shadowColor = UIColor.lightGray.cgColor
//        self.layer.shadowOpacity = 1
//        self.layer.shadowOffset = CGSize.zero
//        self.layer.shadowRadius = 7
//        self.layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
//        self.layer.shouldRasterize = true
        ripplePercent = 0.5
        rippleBackgroundColor = UIColor.clear
        shadowRippleRadius = 2
        buttonCornerRadius = Float(frame.width)/Float(4.0)
        rippleColor = UIColor.white.lighter(percentage: 50) ?? UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
//        let body = UIBezierPath(roundedRect: rect, cornerRadius: rect.width*0.25)
//        UIColor.blue.setStroke()
//        UIColor.blue.setFill()
//        body.stroke()
//        body.fill()
        let width = rect.width
        let height = rect.height
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: width*0.125, y: height*0.375))
        arrowPath.addLine(to: CGPoint(x: width*0.625, y: height*0.375))
        arrowPath.addLine(to: CGPoint(x: width*0.625, y: height*0.25))
        arrowPath.addLine(to: CGPoint(x: width*0.875, y: height*0.50))
        arrowPath.addLine(to: CGPoint(x: width*0.625, y: height*0.75))
        arrowPath.addLine(to: CGPoint(x: width*0.625, y: height*0.625))
        arrowPath.addLine(to: CGPoint(x: width*0.125, y: height*0.625))
        arrowPath.close()
        UIColor.blue.setStroke()
        UIColor.blue.setFill()
        arrowPath.stroke()
        arrowPath.fill()
    }
 

}
