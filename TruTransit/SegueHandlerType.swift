//
//  SegueHandlerType.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/1/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit
import Foundation

protocol SegueHandlerType {
    associatedtype SegueIdentifier: RawRepresentable
}

// notice the cool use of where here to narrow down
// what could use these methods. 😍
extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
    
    func performSegueWithIdentifier(_ segueIdentifier: SegueIdentifier,
                                    sender: AnyObject?) {
        
        performSegue(withIdentifier: segueIdentifier.rawValue, sender: sender)
    }
    
    func segueIdentifierForSegue(_ segue: UIStoryboardSegue) -> SegueIdentifier {
        
        // still have to use guard stuff here, but at least you're
        // extracting it this time
        guard let identifier = segue.identifier,
            let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
                fatalError("Invalid segue identifier \(segue.identifier).") }
        
        return segueIdentifier
    }
}
