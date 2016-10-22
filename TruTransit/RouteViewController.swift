//
//  RouteViewController.swift
//  TruTransit
//
//  Created by Satbir Tanda on 10/10/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit
import MapKit
import Alamofire

class RouteViewController: UIViewController, MKMapViewDelegate {
    
    var bus: Bus?
    var skeleton: SkeletonForRoute?
    var configuration = Configuration()
    private var truBuses = [TruBus]() {
        didSet {
            addTruBusesAnnotations(oldValue)
        }
    }
    
    private var truBusAnnotations: [MTABusAnnotation]?

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(.follow, animated: true)
        }
    }
    
    private let locationDelta = 0.015
    private let MTAPOINT_IDENTIFIER = "MTAPOINT"
    private let MTABUS_IDENTIFIER = "MTABUS"
    private var centerCoordinate: CLLocationCoordinate2D?
    private var centerAnnotation: MTAPointAnnotation?
    private var refreshTimer: Timer?
    private var centerButton = CenterButtonView(frame: CGRect.zero) {
        didSet {
            if centerButton.frame != CGRect.zero {
                centerButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(centerButtonTapped(_:))))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        drawCenterButton()
    }

    private func setupUI() {
        if bus != nil, bus?.destinationName != nil {
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.hexStringToUIColor(bus!.textColor), NSFontAttributeName: UIFont(name: "Verdana-Bold", size: view.frame.width/21.0)!]
            navigationController?.navigationBar.barTintColor = UIColor.hexStringToUIColor(bus!.color)
            navigationController?.navigationBar.tintColor = UIColor.hexStringToUIColor(bus!.textColor)
            navigationItem.title = bus!.shortName
            navigationItem.prompt = "Toward \(bus!.destinationName!)"
            // self.navigationItem.titleView = setTitle(title: bus!.shortName, subtitle: "Toward \(bus!.destinationName!)")
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
            centerButton.tintColor = UIColor.hexStringToUIColor(bus!.color)
            drawRoute()
            updateMap()
            addTimer()
            fetchBusLocations(bus!)
        }
    }
    
    func refresh() {
        if bus != nil {
            fetchBusLocations(bus!)
        }
    }
    
    private func addTimer() {
        if refreshTimer == nil {
            refreshTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
            if refreshTimer != nil {
                if refreshTimer!.isValid {
                    refreshTimer!.fire()
                }
            }
        }
    }
    
    private func drawCenterButton() {
        let centerButtonOffset = view.frame.width/25.0
        centerButton = CenterButtonView(frame: CGRect(x: centerButtonOffset*0.5, y: mapView.frame.height - centerButtonOffset*5.0, width: mapView.frame.width/8.0, height: mapView.frame.width/8.0))
        mapView.addSubview(centerButton)
    }
    
    private func updateMap(_ flag: Bool = false) {
        if bus != nil {
            centerCoordinate = CLLocationCoordinate2D(latitude: bus!.busStop.latitude, longitude: bus!.busStop.longitude)
            let region = MKCoordinateRegion(center: centerCoordinate!, span: MKCoordinateSpan(latitudeDelta: locationDelta, longitudeDelta: locationDelta))
            mapView.setRegion(region, animated: flag)
        }
    }
    
    private func drawRoute() {
        if skeleton != nil, bus != nil {
            var annotations = [MTAPointAnnotation]()
            for stop in skeleton!.stops {
                if stop.destinationName == bus!.destinationName {
                    let location = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
                    let annotation = MTAPointAnnotation()
                    annotation.coordinate = location
                    annotation.title = stop.name
                    annotation.subtitle = "Direction: \(stop.direction!)"
                    annotations.append(annotation)
                    if annotation.title == bus?.busStop.name { self.centerAnnotation = annotation }
                }
                mapView.addAnnotations(annotations)
                if centerAnnotation != nil { mapView.selectAnnotation(centerAnnotation!, animated: true) }
            }
            for destination in skeleton!.destinations {
                if bus!.destinationName == destination.name {
                    for routePolyline in destination.routePolylines {
                        addRouteOverlay(routeCoordinates: routePolyline.coordinates)
                    }
                    break
                }
            }
        }
    }
    
    private func addTruBusesAnnotations(_ oldValue: [TruBus]) {
        // if truBusAnnotations != nil { mapView.removeAnnotations(truBusAnnotations!) }
        var annotations = [MTABusAnnotation]()
        var oldAnnotations = [MTABusAnnotation]()
        for truBus in truBuses {
            let annotation = MTABusAnnotation()
            annotation.truBus = truBus
            var flag = false
            if truBusAnnotations != nil {
                for (index, oldAnnotation) in truBusAnnotations!.enumerated() {
                    if oldAnnotation.truBus?.vehicleRef == annotation.truBus?.vehicleRef {
                        UIView.animate(withDuration: 1.0, animations: { 
                            oldAnnotation.coordinate = CLLocationCoordinate2D(latitude: truBus.latitude, longitude: truBus.longitude)
                        })
                        oldAnnotations.append(oldAnnotation)
                        truBusAnnotations?.remove(at: index)
                        flag = true
                    }
                }
            }
            if !flag { annotations.append(annotation) }
        }
        
        if truBusAnnotations != nil { mapView.removeAnnotations(truBusAnnotations!) }
        mapView.addAnnotations(annotations)
        annotations.append(contentsOf: oldAnnotations)
        self.truBusAnnotations = annotations
    }

    private func fetchBusLocations(_ bus: Bus?, callback: (() -> ())? = nil) {
        if let lineRef = bus?.id, let directionRef = bus?.directionRef {
            if let url = "\(configuration.environment.vehicleMonitoringBaseURL)&LineRef=\(lineRef)&DirectionRef=\(directionRef)".stringByAddingPercentEncodingForRFC3986() {
                Alamofire.request(url).validate(statusCode: 200..<300).validate(contentType: ["application/json"]).responseJSON { [unowned self] response in
                    switch response.result {
                    case .success:
                        if let result = response.result.value as? [String: AnyObject] , response.result.isSuccess {
                            if let serviceDelivery = result["Siri"]!["ServiceDelivery"] as? [String: AnyObject] {
                                if let vehicleMonitoringDelivery = serviceDelivery["VehicleMonitoringDelivery"] as? [[String: AnyObject]] {
                                    if let first = vehicleMonitoringDelivery.first {
                                        if let vehicleActivity = first["VehicleActivity"] as? [[String: AnyObject]] {
                                            var truBuses = [TruBus]()
                                            for vehicle in vehicleActivity {
                                                if let truBus = self.getTruBus(vehicle) {
                                                    truBuses.append(truBus)
                                                }
                                            }
                                            self.truBuses = truBuses
                                        }
                                    }
                                }
                            }
                            callback?()
                        }
                    case .failure(let error):
                        print("Fetch Error -> \(error)")
                    }
                }
            }
        }
    }
    
    private func getTruBus(_ vehicle: [String: AnyObject]) -> TruBus? {
        if let journey = vehicle["MonitoredVehicleJourney"] as? [String: AnyObject] {
            if let destinationArr = journey["DestinationName"] as? [String] {
                if let destinationName = destinationArr.first,
                let directionRef = journey["DirectionRef"] as? String,
                let vehicleRef = journey["VehicleRef"] as? String {
                    if let location = journey["VehicleLocation"] as? [String: AnyObject] {
                        if let longitude = location["Longitude"] as? Double, let latitude = location["Latitude"] as? Double {
                            if let nameArr = journey["PublishedLineName"] as? [String] {
                                if let name = nameArr.first {
                                    let truBus = TruBus(name: name, destinationName: destinationName, directionRef: directionRef, longitude: longitude, latitude: latitude, vehicleRef: vehicleRef)
                                    return truBus
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func addRouteOverlay(routeCoordinates: [CLLocationCoordinate2D]) {
        let routeline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        mapView.add(routeline)
    }
    
    //  MARK: - Map View Delegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView?
        if bus != nil {
            if let point = annotation as? MTAPointAnnotation {
                if let pointView = mapView.dequeueReusableAnnotationView(withIdentifier: MTAPOINT_IDENTIFIER) as? MTAPointAnnotationView {
                    view = pointView
                } else {
                    view = MTAPointAnnotationView(annotation: point, reuseIdentifier: MTAPOINT_IDENTIFIER, color: UIColor.hexStringToUIColor(bus!.color), width: self.view.frame.width/30.0)
                    view?.annotation = annotation // yes, this happens twice if no dequeue
                }
            } else if let buss = annotation as? MTABusAnnotation {
                if let busView = mapView.dequeueReusableAnnotationView(withIdentifier: MTABUS_IDENTIFIER) as? MTABusAnnotationView {
                    view = busView
                } else {
                    view = MTABusAnnotationView(annotation: buss, reuseIdentifier: MTABUS_IDENTIFIER, width: self.view.frame.width/7.5)
                    view?.annotation = annotation // yes, this happens twice if no dequeue
                }
            }
        }
        view?.canShowCallout = true
        // prepare and (if not too expensive) load up accessory views here
        // or reset them and wait until mapView(didSelectAnnotationView:) to load actual data
        return view
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline && bus != nil {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.hexStringToUIColor(bus!.color)
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func centerButtonTapped(_ gesture: UITapGestureRecognizer) {
        switch gesture.state {
            case .began, .changed:
                centerButton.startedTap()
            default:
                centerButton.endedTap()
            if centerCoordinate != nil {
                updateMap(true)
                if centerAnnotation != nil { mapView.selectAnnotation(centerAnnotation!, animated: false) }
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}
