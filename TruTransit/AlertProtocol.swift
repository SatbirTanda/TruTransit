//
//  AlertProtocol.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/1/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit

protocol DisplaysAlerts { }

extension DisplaysAlerts where Self: UIViewController {
    
    func displayAlertWithAction(_ title: String, message: String, actionTitle: String?, withOk flag: Bool, actionHandler: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if flag { alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil)) }
        alertController.addAction(UIAlertAction(title: actionTitle, style: .default, handler: actionHandler))
        present(alertController, animated: true, completion: nil)
    }
    
}
