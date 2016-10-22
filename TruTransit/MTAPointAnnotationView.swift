//
//  MTAStopAnnotationView.swift
//  TruTransit
//
//  Created by Satbir Tanda on 10/11/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit
import MapKit

class MTAPointAnnotationView: MKAnnotationView {
    
    private var color: UIColor!
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(annotation: MKAnnotation?, reuseIdentifier: String?, color: UIColor, width: CGFloat) {
        self.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: width))
        self.color = color
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        let coloredPath = UIBezierPath(ovalIn: rect)
        coloredPath.lineWidth = 1.0
        color.setFill()
        color.setStroke()
        coloredPath.stroke()
        coloredPath.fill()
        let whitePath = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: (rect.width)*0.1875, y: (rect.height)*0.1875), size: CGSize(width: rect.width*0.625, height: rect.height*0.625)))
        whitePath.lineWidth = 1.0
        UIColor.white.setFill()
        UIColor.white.setStroke()
        whitePath.stroke()
        whitePath.fill()
    }
    

}
