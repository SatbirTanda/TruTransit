//
//  CenterButtonView.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/23/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit

class CenterButtonView: MaterialButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = 7
        self.layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
        self.layer.shouldRasterize = true
        ripplePercent = 0.5
        rippleBackgroundColor = UIColor.clear
        shadowRippleRadius = 2
        buttonCornerRadius = Float(frame.width)/Float(4.0)
        rippleColor = UIColor.goldColor().lighter(percentage: 50) ?? UIColor.goldColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        let body = UIBezierPath(roundedRect: rect, cornerRadius: rect.width*0.25)
        UIColor.white.setStroke()
        UIColor.white.setFill()
        body.stroke()
        body.fill()
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: rect.width*0.25, y: rect.height*0.50))
        arrowPath.addLine(to: CGPoint(x: rect.width/2.0, y: rect.height/2.0))
        arrowPath.addLine(to: CGPoint(x: rect.width*0.50, y: rect.height*0.75))
        arrowPath.addLine(to: CGPoint(x: rect.width*0.75, y: rect.height*0.25))
        arrowPath.close()
            
        UIColor.blue.setStroke()
        UIColor.blue.setFill()
        arrowPath.stroke()
        arrowPath.fill()
    }
}
