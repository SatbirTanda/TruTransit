//
//  MTABusAnnotation.swift
//  TruTransit
//
//  Created by Satbir Tanda on 10/10/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit
import MapKit

class MTABusAnnotation: MKPointAnnotation {
    var truBus: TruBus? {
        didSet {
            if truBus != nil {
                coordinate = CLLocationCoordinate2D(latitude: truBus!.latitude, longitude: truBus!.longitude)
                title = "\(truBus!.name!)"
                subtitle = "Toward \(truBus!.destinationName!)"
            }
        }
    }
}
