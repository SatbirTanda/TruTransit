//
//  MTAView.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/7/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit

class MTAView: MaterialButton {
    
    fileprivate var buses: [Bus]?
    fileprivate var circleColor: UIColor?
    fileprivate var textColor: UIColor?
    fileprivate var mtaText: String?
    
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

    convenience init(frame: CGRect, buses: [Bus]) {
        self.init(frame: frame)
        self.buses = buses
        if let bus = buses.first {
            self.circleColor = UIColor.hexStringToUIColor(bus.color)
            self.textColor = UIColor.hexStringToUIColor(bus.textColor)
            self.mtaText = bus.shortName
            addMTAText(bus.shortName, textColor: UIColor.hexStringToUIColor(bus.textColor))
        }
        ripplePercent = 10
        rippleBackgroundColor = UIColor.clear
        shadowRippleRadius = 5
        buttonCornerRadius = Float(frame.width)/Float(2.0)
        rippleColor = circleColor?.lighter() ?? UIColor.goldColor()
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        let circlePath = UIBezierPath(ovalIn: rect)
        circlePath.lineWidth = 1.0
        circleColor?.setFill()
        circleColor?.setStroke()
        circlePath.stroke()
        circlePath.fill()
    }
    
    fileprivate func addMTAText(_ mtaText: String, textColor: UIColor) {
        let mtaLabel = UILabel(frame: self.bounds)
        let attributedString = NSMutableAttributedString(string: mtaText, attributes: [NSFontAttributeName: UIFont(name: "Verdana-Bold", size: bounds.width/3.0)!, NSForegroundColorAttributeName: textColor])
        mtaLabel.attributedText = attributedString
        mtaLabel.textAlignment = .center
        mtaLabel.adjustsFontSizeToFitWidth = true
        self.addSubview(mtaLabel)
    }
    
    func getBuses() -> [Bus] {
        return self.buses ?? []
    }

}
