//
//  Configurations.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/1/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import Foundation

enum Environment: String {
    case Debug = "debug"
    case Release = "release"
    
    var vehicleMonitoringBaseURL: String {
        switch self {
        case .Debug:
            return "http://bustime.mta.info/api/siri/vehicle-monitoring.json?key=\(siriKey)&version=2"
            // add LineRef=MTA%20NYCT_Q43&DirectionRef=0
        case .Release:
            return "http://bustime.mta.info/api/siri/vehicle-monitoring.json?key=\(siriKey)&version=2"
        }
    }
    
    var stopMonitoringBaseURL: String {
        switch self {
        case .Debug: return "http://bustime.mta.info/api/siri/stop-monitoring.json?key=\(siriKey)&version=2&StopMonitoringDetailLevel=basic&OperatorRef=MTA&MaximumStopVisits=3&MinimumStopVisitsPerLine=1"
        // add &MonitoringRef=502096&LineRef=MTA%20NYCT_Q43
        case .Release: return "http://bustime.mta.info/api/siri/stop-monitoring.json?key=\(siriKey)&version=2&StopMonitoringDetailLevel=basic&OperatorRef=MTA&MaximumStopVisits=3&MinimumStopVisitsPerLine=1"
        }
    }
    
    var stopsForLocationBaseURL: String {
        switch self {
        case .Debug:
            return "http://bustime.mta.info/api/where/stops-for-location.json?key=\(siriKey)"
        // add lat=40.748433&lon=-73.985656&latSpan=0.005&lonSpan=0.005
        case .Release:
            return "http://bustime.mta.info/api/where/stops-for-location.json?key=\(siriKey)"
        }
    }
    
    var stopsForRouteURL: String {
        switch self {
        case .Debug:
            return "http://bustime.mta.info/api/where/stops-for-route/"
            // add MTA%20NYCT_Q43.json?key=6e785cfa-d3b5-4629-b54f-a297b8184c42&version=2&includePolylines=false
        case .Release:
            return "http://bustime.mta.info/api/where/stops-for-route/"
        }
    }
    
    var siriKey: String {
        switch self {
        case .Debug:
            return "6e785cfa-d3b5-4629-b54f-a297b8184c42"
        case .Release:
            return "6e785cfa-d3b5-4629-b54f-a297b8184c42"
        }
    }
}

struct Configuration {
    lazy var environment: Environment = {
        if let configuration = Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String {
            print("Configuration -> \(configuration)")
            if configuration.range(of: "Debug") != nil {
                return Environment.Debug
            }
        }
        
        return Environment.Release
    }()
    
    init() {
        
    }
}
