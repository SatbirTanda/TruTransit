//
//  MaterialButton.swift
//  TruTransit
//
//  Created by Satbir Tanda on 10/12/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable
public class MaterialButton: UIView {
    
    @IBInspectable public var ripplePercent: Float = 0.8 {
        didSet {
            setupRippleView()
        }
    }
    
    @IBInspectable public var rippleColor: UIColor = UIColor(white: 0.9, alpha: 1) {
        didSet {
            rippleView.backgroundColor = rippleColor
        }
    }
    
    @IBInspectable public var rippleBackgroundColor: UIColor = UIColor(white: 0.95, alpha: 1) {
        didSet {
            rippleBackgroundView.backgroundColor = rippleBackgroundColor
        }
    }
    
    @IBInspectable public var buttonCornerRadius: Float = 0 {
        didSet{
            layer.cornerRadius = CGFloat(buttonCornerRadius)
        }
    }
    
    @IBInspectable public var rippleOverBounds: Bool = false
    @IBInspectable public var shadowRippleRadius: Float = 1
    @IBInspectable public var shadowRippleEnable: Bool = true
    @IBInspectable public var trackTouchLocation: Bool = false
    @IBInspectable public var touchUpAnimationTime: Double = 0.6
    
    let rippleView = UIView()
    let rippleBackgroundView = UIView()
    
    private var tempShadowRadius: CGFloat = 0
    private var tempShadowOpacity: Float = 0
    private var touchCenterLocation: CGPoint?
    
    private var rippleMask: CAShapeLayer? {
        get {
            if !rippleOverBounds {
                let maskLayer = CAShapeLayer()
                maskLayer.path = UIBezierPath(roundedRect: bounds,
                                              cornerRadius: layer.cornerRadius).cgPath
                return maskLayer
            } else {
                return nil
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        setupRippleView()
        
        rippleBackgroundView.backgroundColor = rippleBackgroundColor
        rippleBackgroundView.frame = bounds
        layer.addSublayer(rippleBackgroundView.layer)
        rippleBackgroundView.layer.addSublayer(rippleView.layer)
        rippleBackgroundView.alpha = 0
        
        layer.shadowRadius = 0
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowColor = UIColor(white: 0.0, alpha: 0.5).cgColor
    }
    
    private func setupRippleView() {
        let size: CGFloat = bounds.width * CGFloat(ripplePercent)
        let x: CGFloat = (bounds.width/2) - (size/2)
        let y: CGFloat = (bounds.height/2) - (size/2)
        let corner: CGFloat = size/2
        
        rippleView.backgroundColor = rippleColor
        rippleView.frame = CGRect(x: x, y: y, width: size, height: size)
        rippleView.layer.cornerRadius = corner
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if trackTouchLocation {
                touchCenterLocation = touch.location(in: self)
            } else {
                touchCenterLocation = nil
            }
        }
        startedTap()
        super.touchesBegan(touches, with: event)
    }
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endedTap()
        super.touchesCancelled(touches, with: event)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endedTap()
        super.touchesEnded(touches, with: event)
    }
    
    func startedTap() {
        
        UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
            self.rippleBackgroundView.alpha = 1
            }, completion: nil)
        
        rippleView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        
        UIView.animate(withDuration: 0.7, delay: 0, options: [UIViewAnimationOptions.curveEaseOut, UIViewAnimationOptions.allowUserInteraction],
                       animations: {
                        self.rippleView.transform =  CGAffineTransform.identity
            }, completion: nil)
        
        if shadowRippleEnable {
            tempShadowRadius = layer.shadowRadius
            tempShadowOpacity = layer.shadowOpacity
            
            let shadowAnim = CABasicAnimation(keyPath:"shadowRadius")
            shadowAnim.toValue = shadowRippleRadius
            
            let opacityAnim = CABasicAnimation(keyPath:"shadowOpacity")
            opacityAnim.toValue = 1
            
            let groupAnim = CAAnimationGroup()
            groupAnim.duration = 0.7
            groupAnim.fillMode = kCAFillModeForwards
            groupAnim.isRemovedOnCompletion = false
            groupAnim.animations = [shadowAnim, opacityAnim]
            
            layer.add(groupAnim, forKey:"shadow")
        }
    }
    
    func endedTap() {
        animateToNormal()
    }

    
    private func animateToNormal() {
        UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
            self.rippleBackgroundView.alpha = 1
            }, completion: {(success: Bool) -> () in
                UIView.animate(withDuration: self.touchUpAnimationTime, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                    self.rippleBackgroundView.alpha = 0
                    }, completion: nil)
        })
        
        
        UIView.animate(withDuration: 0.7, delay: 0,
                                   options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                                   animations: {
                                    self.rippleView.transform =  CGAffineTransform.identity
                                    
                                    let shadowAnim = CABasicAnimation(keyPath:"shadowRadius")
                                    shadowAnim.toValue = self.tempShadowRadius
                                    
                                    let opacityAnim = CABasicAnimation(keyPath:"shadowOpacity")
                                    opacityAnim.toValue = self.tempShadowOpacity
                                    
                                    let groupAnim = CAAnimationGroup()
                                    groupAnim.duration = 0.7
                                    groupAnim.fillMode = kCAFillModeForwards
                                    groupAnim.isRemovedOnCompletion = false
                                    groupAnim.animations = [shadowAnim, opacityAnim]
                                    
                                    self.layer.add(groupAnim, forKey:"shadowBack")
            }, completion: nil)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        setupRippleView()
        if let knownTouchCenterLocation = touchCenterLocation {
            rippleView.center = knownTouchCenterLocation
        }
        
        rippleBackgroundView.layer.frame = bounds
        rippleBackgroundView.layer.mask = rippleMask
    }
    
}
