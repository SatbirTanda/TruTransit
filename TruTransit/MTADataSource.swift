//
//  MTADataSource.swift
//  TruTransit
//
//  Created by Satbir Tanda on 10/5/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import Foundation


// add uitableviewdatasource delegate refactor
class MTADataSource {
    
    var buses: [Bus]!
    var numberOfSections: Int!
    var organizedBuses = [[Bus]]()
    var skeleton: SkeletonForRoute!
    
    init(buses: [Bus], skeleton: SkeletonForRoute) {
        self.buses = buses
        self.skeleton = skeleton
        // get number of sections
        // get number of rows per section
        // get names of rows per section
        for bus in buses {
            for destination in skeleton.destinations {
                if destination.stopIds.contains(bus.busStop.id) {
                    bus.directionRef = destination.directionRef
                    bus.destinationName = destination.name
                    break
                }
            }
            var flag = false
            for index in 0..<organizedBuses.count {
                if bus.destinationName == organizedBuses[index].first?.destinationName {
                    organizedBuses[index].append(bus)
                    flag = true
                    break
                }
            }
            if !flag {
                organizedBuses.append([bus])
            }
        }
        numberOfSections = organizedBuses.count
    }
    
    func numberOfRowsForSection(section: Int) -> Int {
        if section < organizedBuses.count {
            return organizedBuses[section].count
        }
        return 0
    }
    
    func titleForSection(section: Int) -> String? {
        if let bus = organizedBuses[section].first {
            if let destinationName = bus.destinationName {
                return bus.shortName + " towards " + destinationName
            }
        }
        return nil
    }

}
