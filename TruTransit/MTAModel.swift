//
//  Nearby.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/14/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import Foundation

class MTAModel {
    
    var Buses = [[Bus]]()
    
    init(stops: [[String: AnyObject]]) {
        if stops.count > 0 {
            for stop in stops {
                let busStop = BusStop(stop: stop)
                if let routes = stop["routes"] as? [[String: AnyObject]] {
                    for route in routes {
                        let bus = Bus(route: route, busStop: busStop)
                        var flag = false
                        for index in 0..<Buses.count {
                            if Buses[index].first?.shortName == bus.shortName {
                                Buses[index].append(bus)
                                flag = true
                                break
                            }
                        }
                        if !flag {
                            Buses.append([bus])
                        }
                    }
                }
            }
        }
    }
    
    convenience init(buses: [[Bus]]) {
        self.init(stops: [])
        self.Buses = buses
    }
    
    deinit {
        Buses.removeAll()
    }
}
