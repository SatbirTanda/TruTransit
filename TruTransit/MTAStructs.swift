//
//  MTAStructs.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/13/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import Polyline
import Alamofire
import Foundation
import CoreLocation

class Bus {
    var color: String!
    var description: String!
    var id: String!
    var longName: String!
    var shortName: String!
    var textColor: String!
    var busStop: BusStop!
    
    var directionRef: String?
    var destinationName: String? {
        didSet {
            if destinationName != nil {
                if destinationName?.components(separatedBy: "via").count != 0 {
                    if let destinationName = destinationName?.components(separatedBy: "via").first {
                        self.destinationName = destinationName
                    }
                } else if destinationName?.components(separatedBy: "Via").count != 0 {
                    if let destinationName = destinationName?.components(separatedBy: "Via").first {
                        self.destinationName = destinationName
                    }
                }
            }
        }
    }
    
    
    var incomingBuses: [IncomingBus] = []

    init(route: [String: AnyObject], busStop: BusStop, callback: (() -> ())? = nil) {
        self.busStop = busStop
        if let color = route["color"] as? String {
            self.color = color
        }
        if let description = route["description"] as? String {
            self.description = description
        }
        if let id = route["id"] as? String {
            self.id = id
        }
        if let longName = route["longName"] as? String {
            self.longName = longName
        }
        if let shortName = route["shortName"] as? String {
            self.shortName = shortName
        }
        if let textColor = route["textColor"] as? String {
            self.textColor = textColor
        }
        if let direction = busStop.direction {
            if let destination = longName {
                var destination = destination
                if direction.hasPrefix("N") || direction.hasPrefix("W") {
                    if destination.components(separatedBy: "-").count > 1 {
                        destination = destination.components(separatedBy: "-")[1].trim()
                    }
                } else if direction.hasPrefix("S") || direction.hasPrefix("E"){
                    destination = destination.components(separatedBy: "-")[0].trim()
                }
                self.destinationName = destination
            }
        }
    }
    
    class func GetIncomingBuses(buses: [Bus], configuration: Configuration, skeleton: SkeletonForRoute, callback: (() -> ())? = nil) {
        var buses = buses
        var configuration = configuration
        if let bus = buses.first {
            if let monitoringRef = bus.busStop.code, let lineRef = bus.id {
                if let url = "\(configuration.environment.stopMonitoringBaseURL)&MonitoringRef=\(monitoringRef)&LineRef=\(lineRef)".stringByAddingPercentEncodingForRFC3986() {
                    Alamofire.request(url).validate(statusCode: 200..<300).validate(contentType: ["application/json"]).responseJSON { response in
                        switch response.result {
                        case .success:
                            if let result = response.result.value as? [String: AnyObject] , response.result.isSuccess {
                                if let serviceDelivery = result["Siri"]!["ServiceDelivery"] as? [String: AnyObject] {
                                    if let stopMonitoringDelivery = serviceDelivery["StopMonitoringDelivery"] as? [[String: AnyObject]] {
                                        if let monitoredStopVisit = stopMonitoringDelivery.first?["MonitoredStopVisit"] as? [[String: AnyObject]] {
                                            bus.incomingBuses.removeAll()
                                            for monitoredStop in monitoredStopVisit {
                                                if let incomingBus = monitoredStop["MonitoredVehicleJourney"] as? [String: AnyObject] {
                                                    let ib = IncomingBus(incomingBus: incomingBus)
                                                    bus.incomingBuses.append(ib)
                                                }
                                            }
                                            buses.remove(at: 0)
                                            Bus.GetIncomingBuses(buses: buses, configuration: configuration, skeleton: skeleton, callback: callback)
                                        }
                                    }
                                }
                            }
                        case .failure(let error):
                            print("Error receiving nearby stops. -> \(error)")
                        }
                    }
                }
            }
        } else {
            callback?()
        }
    }
    
    // class func Get

    class func GetSkeleton(buses: [Bus], configuration: Configuration, callback: ((_ skeleton: SkeletonForRoute) -> ())? = nil) {
        var configuration = configuration
        if let bus = buses.first {
            if let id = bus.id {
                if let url = "\(configuration.environment.stopsForRouteURL)\(id).json?key=\(configuration.environment.siriKey)&version=2&includePolylines=true".stringByAddingPercentEncodingForRFC3986() {
                    Alamofire.request(url).validate(statusCode: 200..<300).validate(contentType: ["application/json"]).responseJSON { response in
                        switch response.result {
                        case .success:
                            if let result = response.result.value as? [String: AnyObject] , response.result.isSuccess {
                                if let entry = result["data"]!["entry"] as? [String: AnyObject], let references = result["data"]!["references"] as? [String: AnyObject] {
                                    if let stopGroupings = entry["stopGroupings"] as? [[String: AnyObject]], let stops = references["stops"] as? [[String: AnyObject]] {
                                        for group in stopGroupings {
                                            if let stopGroups = group["stopGroups"] as? [[String: AnyObject]] {
                                                if let polylines = entry["polylines"] as? [[String: AnyObject]] {
                                                    let skeletonForRoute = SkeletonForRoute(destinations: stopGroups, stops: stops, routePolylines: polylines)
                                                    // print("skeleton -> \(skeletonForRoute)")
                                                    callback?(skeletonForRoute)
                                                }
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        case .failure(let error):
                            print("Fetch Error -> \(error)")
                        }
                    }
                }
            }
        }
    }
    
}

struct SkeletonForRoute {
    
    struct Destination {
        var directionRef: String!
        var name: String!
        var stopIds: [String]!
        var routePolylines: [RoutePolyline]!
    }
    
    struct Stop {
        var name: String!
        var longitude: Double!
        var latitude: Double!
        var direction: String!
        var id: String!
        var destinationName: String? {
            didSet {
                if destinationName != nil {
                    if destinationName?.components(separatedBy: "via").count != 0 {
                        if let destinationName = destinationName?.components(separatedBy: "via").first {
                            self.destinationName = destinationName
                        }
                    } else if destinationName?.components(separatedBy: "Via").count != 0 {
                        if let destinationName = destinationName?.components(separatedBy: "Via").first {
                            self.destinationName = destinationName
                        }
                    }
                }
            }
        }
    }
    
    struct RoutePolyline {
        var coordinates: [CLLocationCoordinate2D]!
    }
    
    var destinations = [Destination]()
    var stops = [Stop]()
    
    init(destinations: [[String: AnyObject]], stops: [[String: AnyObject]], routePolylines: [[String: AnyObject]]) {
        for stop in stops {
            if let name = stop["name"] as? String {
                if let lon = stop["lon"] as? Double {
                    if let lat = stop["lat"] as? Double {
                        if let direction = stop["direction"] as? String {
                            if let id = stop["id"] as? String {
                                self.stops.append(Stop(name: name, longitude: lon, latitude: lat, direction: direction, id: id, destinationName: nil))
                            }
                        }
                    }
                }
            }
        }
        for destination in destinations {
            if let directionRef = destination["id"] as? String, let stopIds = destination["stopIds"] as? [String] {
                if let nameObj = destination["name"] as? [String: AnyObject] {
                    if let name = nameObj["name"] as? String {
                        var name = name
                        if name.components(separatedBy: "via").count != 0 {
                            if let destinationName = name.components(separatedBy: "via").first {
                                name = destinationName
                            }
                        } else if name.components(separatedBy: "Via").count != 0 {
                            if let destinationName = name.components(separatedBy: "Via").first {
                                name = destinationName
                            }
                        }
                        if let routePolylines = destination["polylines"] as? [[String: AnyObject]] {
                            var newPolylines = [RoutePolyline]()
                            for routePolyline in routePolylines {
                                if let encodedPolylinePoints = routePolyline["points"] as? String {
                                    newPolylines.append(RoutePolyline(coordinates: decodePolyline(encodedPolylinePoints)))
                                }
                            }
                            self.destinations.append(Destination(directionRef: directionRef, name: name, stopIds: stopIds, routePolylines: newPolylines))
                        }
                    }
                }
            }
        }
        for index in 0..<self.stops.count {
            for index2 in 0..<self.destinations.count {
                if self.destinations[index2].stopIds.contains(self.stops[index].id) {
                    self.stops[index].destinationName = self.destinations[index2].name
                    break
                }
            }
        }
    }
}


struct IncomingBus {
    var destinationName: String?
    var arrivalProximityText: String!
    var expectedArrivalTime: String?
    var vehicleRef: String!
    var longitude: Double!
    var latitude: Double!
    var directionRef: String!
    
    init(incomingBus: [String: AnyObject]) {
        if let destinationNames = incomingBus["DestinationName"] as? [String] {
            if let destinationName = destinationNames.first {
                self.destinationName = destinationName
            }
        }
        if let monitoredCall = incomingBus["MonitoredCall"] as? [String: AnyObject] {
            if let arrivalProximityText = monitoredCall["ArrivalProximityText"] as? String {
                self.arrivalProximityText = arrivalProximityText
            }
            if let expectedArrivalTime = monitoredCall["ExpectedArrivalTime"] as? String {
                self.expectedArrivalTime = expectedArrivalTime
            }
        }
        
        if let vehicleRef = incomingBus["VehicleRef"] as? String {
            self.vehicleRef = vehicleRef
        }
        
        if let directionRef = incomingBus["DirectionRef"] as? String {
            self.directionRef = directionRef
        }
        
        if let vehicleLocation = incomingBus["VehicleLocation"] as? [String: AnyObject] {
            if let longitude = vehicleLocation["Longitude"] as? Double {
                self.longitude = longitude
            }
            if let latitude = vehicleLocation["Latitude"] as? Double {
                self.latitude = latitude
            }
        }
    }
}

struct BusStop {
    var direction: String!
    var id: String!
    var code: String!
    var longitude: Double!
    var latitude: Double!
    var name: String!
    
    init(stop: [String: AnyObject]) {
        if let direction = stop["direction"] as? String {
            self.direction = direction
        }
        if let id = stop["id"] as? String {
            self.id = id
        }
        if let code = stop["code"] as? String {
            self.code = code
        }
        if let longitude = stop["lon"] as? Double {
            self.longitude = longitude
        }
        if let latitude = stop["lat"] as? Double {
            self.latitude = latitude
        }
        if let name = stop["name"] as? String {
            self.name = name
        }
    }
}

struct TruBus {
    var name: String!
    var destinationName: String!
    var directionRef: String!
    var longitude: Double!
    var latitude: Double!
    var vehicleRef: String!
}

