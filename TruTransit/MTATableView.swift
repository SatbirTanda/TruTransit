//
//  MTATableView.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/20/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit

class MTATableView: UITableView {

    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if (point.y < 0){
            return nil
        }
        return hitView
    }

}
