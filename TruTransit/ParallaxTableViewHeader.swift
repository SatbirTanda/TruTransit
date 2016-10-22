//
//  ViewParallaxTableHeader.swift
//  ParallaxTableViewHeader
//
//  Created by Lucas Louca on 11/06/15.
//  Copyright (c) 2015 Lucas Louca. All rights reserved.
//

import UIKit
import MapKit

class ParallaxTableHeaderView: UIView {
    let parallaxDeltaFactor: CGFloat = 0.50
    var defaultHeaderFrame: CGRect!
    var scrollView: UIScrollView!
    var subView: UIView!
    
    convenience init(size: CGSize, subView:UIView) {
        self.init(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        scrollView = UIScrollView(frame: self.bounds)
        self.subView = subView
        subView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleHeight, .flexibleWidth]
        scrollView.addSubview(self.subView)
        self.addSubview(self.scrollView)
        clipsToBounds = true
    }
    
    /**
     Layout the content of the header view to give the parallax feeling.
     - parameter contentOffset: scroll views content offset
     */
    func layoutForContentOffset(_ contentOffset: CGPoint) {
        var frame = scrollView.frame
        defaultHeaderFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        frame.origin.y = contentOffset.y * parallaxDeltaFactor
        scrollView.frame = frame
        for subview in self.subView.subviews {
            if let centerButton = subview as? CenterButtonView {
                var centerButtonFrame = centerButton.frame
                centerButtonFrame.origin.y = scrollView.frame.height - 1.7 * centerButton.frame.height - parallaxDeltaFactor * contentOffset.y
                centerButton.frame = centerButtonFrame
            }
        }
    }
}
