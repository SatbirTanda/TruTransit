//
//  MTABusAnnotationView.swift
//  TruTransit
//
//  Created by Satbir Tanda on 10/11/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit
import MapKit

class MTABusAnnotationView: MKAnnotationView {

    private var color: UIColor = UIColor.blue

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(annotation: MKAnnotation?, reuseIdentifier: String?, width: CGFloat) {
        self.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: width))
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        let cornerRadius = rect.width*0.20
        let body = CGRect(origin: rect.origin, size: CGSize(width: rect.size.width*0.80, height: rect.size.height*0.90))
        let bodyPath = UIBezierPath(roundedRect: body, cornerRadius: cornerRadius)
        bodyPath.lineWidth = 1.0
        color.setFill()
        color.setStroke()
        bodyPath.stroke()
        bodyPath.fill()
        let windowWidth = body.width *  0.65
        let windowHeight = body.height * 0.40
        let windowX = body.width/2.0 - windowWidth/2.0
        let windowY = body.height/2.0 - body.height/2.5
        let window = CGRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
        let windowPath = UIBezierPath(rect: window)
        UIColor.white.setFill()
        windowPath.fill()
        let lightWidth = body.width*0.20
        let lightHeight = body.height*0.20
        let lightLX = body.width*0.25 - lightWidth/2.0
        let lightRX = body.width*0.75 - lightWidth/2.0
        let lightY = rect.height/2.0 + lightHeight/2.0
        let lightL = UIBezierPath(ovalIn: CGRect(x: lightLX, y: lightY, width: lightWidth, height: lightHeight))
        let lightR = UIBezierPath(ovalIn: CGRect(x: lightRX, y: lightY, width: lightWidth, height: lightHeight))
        lightL.fill()
        lightR.fill()
        let wheelWidth = body.width*0.20
        let wheelHeight = body.height*0.20
        let wheelY = body.height * 0.90
        let wheelL = CGRect(x: lightLX, y: wheelY, width: wheelWidth, height: wheelHeight)
        let wheelR = CGRect(x: lightRX, y: wheelY, width: wheelWidth, height: wheelHeight)
        let wheelLPath = UIBezierPath(roundedRect: wheelL, cornerRadius: cornerRadius)
        let wheelRPath = UIBezierPath(roundedRect: wheelR, cornerRadius: cornerRadius)
        color.setFill()
        wheelLPath.fill()
        wheelRPath.fill()
    }
}
