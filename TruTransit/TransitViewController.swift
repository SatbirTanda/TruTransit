//
//  ViewController.swift
//  NYCTransit
//
//  Created by Satbir Tanda on 9/1/16.
//  Copyright © 2016 Satbir Tanda. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON
import NVActivityIndicatorView

class TransitViewController: UIViewController, SegueHandlerType, DisplaysAlerts, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
        
    @IBOutlet weak var tableView: MTATableView! {
        didSet {
            tableView.backgroundColor = UIColor.blue
            tableView.delegate = self
            tableView.dataSource = self
            tableView.bounces = false
            tableView.layoutMargins = UIEdgeInsets.zero
            tableView.separatorInset = UIEdgeInsets.zero
            tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        }
    }
    
    var mapView = MKMapView() {
        didSet {
            mapView.delegate = self
            mapView.setUserTrackingMode(.follow, animated: false)
            Madd = true
        }
    }
    
    fileprivate var mtaModel: MTAModel! {
        didSet {
            refreshUI()
        }
    }
    
    fileprivate var mtaStops = [MTAView]() {
        didSet {
            refreshCarousel()
        }
    }  // only show 6 at a time
    
    fileprivate var mtaDataSource: MTADataSource? {
        didSet {
            if mtaDataSource != nil {
                refetch(scrollToBottom: true)
            }
        }
    }
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var tracker = TrackerView(frame: CGRect.zero) {
        didSet {
            Tadd = true
        }
    }
    fileprivate var activityIndicator = NVActivityIndicatorView(frame: CGRect.zero) {
        didSet {
            Aadd = true
        }
    }
    fileprivate var centerButton = CenterButtonView(frame: CGRect.zero) {
        didSet {
            if centerButton.frame != CGRect.zero {
                centerButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(centerButtonTapped(_:))))
                Cadd = true
            }
        }
    }
    fileprivate var configuration = Configuration()
    fileprivate let range = 0.0065
    fileprivate var refetchTimer: Timer?
    private var centerCoordinate: CLLocationCoordinate2D?
    private var Cadd = false
    private var Tadd = false
    private var Madd = false
    private var Aadd = false
    private var arrows = [UIView]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavBar()
        // refetch()
        if refetchTimer == nil {
            refetchTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(refetch), userInfo: nil, repeats: true)
            if refetchTimer != nil {
                if refetchTimer!.isValid {
                    refetchTimer!.fire()
                }
            }
        }
    }
    
    @IBAction func refreshButtonTapped(_ sender: UIBarButtonItem) {
        refetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let index = self.tableView.indexPathForSelectedRow{
            tableView.deselectRow(at: index, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSpinning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let trackerWidth = view.frame.width/17.5
        let trackerFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: trackerWidth, height: trackerWidth))
        let activityIndicatorFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: 2.0*trackerWidth, height: 2.0*trackerWidth))
        let trackerCenter = mapView.convert(mapView.centerCoordinate, toPointTo: mapView)
        let centerButtonOffset = view.frame.width/20.0
        tracker.isHidden = true
        if tracker.frame != trackerFrame {
            tracker = TrackerView(frame: trackerFrame)
            tracker.center = trackerCenter
            mapView.addSubview(tracker)
        }
        if centerButton.frame.width != centerButtonOffset*0.5 && centerButton.frame.width != mapView.frame.height - centerButtonOffset*5.0 && !Cadd {
            centerButton = CenterButtonView(frame: CGRect(x: centerButtonOffset*0.5, y: mapView.frame.height - centerButtonOffset*5.0, width: mapView.frame.width/8.0, height: mapView.frame.width/8.0))
            mapView.addSubview(centerButton)
        }
        if activityIndicator.frame != activityIndicatorFrame && !Aadd {
            activityIndicator = NVActivityIndicatorView(frame: activityIndicatorFrame, type: .ballClipRotate, color: UIColor.green, padding: nil)
            activityIndicator.center = trackerCenter
        }
        setupArrows()
    }
    
    // MARK: - Helpers
    
    fileprivate func reload() {
        tableView.reloadData()
    }
    
    fileprivate func startSpinning() {
        mapView.addSubview(activityIndicator)
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    fileprivate func stopSpinning() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    fileprivate func displaySettingsAlert() {
        self.displayAlertWithAction("Your Location Services are Disabled", message: "Your current location cannot be determined.  In Settings -> NYCTransit, make sure Location Serives are enabled and try again.", actionTitle: "Settings", withOk: true, actionHandler: { (action) in
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(settingsURL)
                }
            }
        })
    }
    
    fileprivate func displayShowNYCAlert() {
        self.displayAlertWithAction("No Data Available!", message: "We do not support data for your region yet!  Please contact us if you would like to be addded to our queue!", actionTitle: "OK", withOk: false, actionHandler: { (action) in
                self.displayNYC()
        })
    }
    
    fileprivate func displayNYC() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString("New York City") { (placemarks, error) in
            if (error != nil) {
                print("DisplayNYC Error -> \(error!.localizedDescription)")
            } else {
                if let placemarkCoordinate = placemarks?.last?.location?.coordinate {
                    let region = MKCoordinateRegion(center: placemarkCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                    self.mapView.setRegion(region, animated: false)
                    self.tracker.isHidden = false
                }
            }
        }
    }
    
    fileprivate func setupUI() {
        if let navOffset = navigationController?.navigationBar.frame.height {
            mapView = MKMapView(frame: CGRect(x: CGFloat(0), y: -navOffset/2.0, width: view.frame.width, height: view.frame.height - navOffset))
            let tableHeaderView = ParallaxTableHeaderView(size: CGSize(width: mapView.frame.width, height: mapView.frame.height), subView: mapView)
            tableView.tableHeaderView = tableHeaderView
            setupNavBar()
        }
    }
    
    fileprivate func setupNavBar() {
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.goldColor(), NSFontAttributeName: UIFont(name: "Verdana-Bold", size: view.frame.width/21.0)!]
        navigationController?.navigationBar.barTintColor = UIColor.blue
        navigationController?.navigationBar.tintColor = UIColor.goldColor()
        navigationItem.prompt = "Real-Time Data of the MTA"
    }
    
    fileprivate func setupArrows() {
        if arrows.count == 0 {
            let centerX = tracker.center.x
            let centerY = tracker.center.y
            let radiusWidth = mapView.frame.maxX/2.0
            let radiusHeight = mapView.frame.maxY/2.0
            let width = view.frame.width/10.0
            let height = view.frame.width/10.0
            let rightArrow = RightArrowView(frame: CGRect(x: centerX + radiusWidth*0.50, y: centerY + radiusHeight*0.25, width: width, height: height))
            let leftArrow = LeftArrowView(frame: CGRect(x: centerX - radiusWidth*0.50 - width, y: centerY + radiusHeight*0.25, width: width, height: height))
            rightArrow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rightArrowButtonTapped(_:))))
            leftArrow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(leftArrowButtonTapped(_:))))
            arrows.append(leftArrow)
            arrows.append(rightArrow)
        }
    }
    
    fileprivate func refreshUI() {
        //animate and refresh circle of stops
        if self.mtaModel != nil {
                UIView.animateKeyframes(withDuration: 0.25, delay: 0.0, options: .allowUserInteraction, animations: {
                    for mtaStop in self.mtaStops { mtaStop.alpha = 0.0 }
                    }, completion: { [weak self] (success) in
                        if self != nil {
                            if success && self!.mtaModel.Buses.count != 0
                            {
                                for mtaStop in self!.mtaStops { mtaStop.removeFromSuperview() }
                                var mtaStops = [MTAView]()
                                for (index, buses) in self!.mtaModel.Buses.enumerated() where index < 6 {
                                    let side = self!.view.frame.width/5.0
                                    let rect = CGRect(x: 0, y: 0, width: side, height: side)
                                    let mtaView = MTAView(frame: rect, buses: buses)
                                    mtaView.center = self!.tracker.center
                                    mtaView.addGestureRecognizer(UITapGestureRecognizer(target: self!, action: #selector(self!.mtaViewTapGesture(_:))))
                                    mtaStops.append(mtaView)
                                }
                                self!.mtaStops = mtaStops.reversed()
                            } else if !success {
                                print("error")
                            } else if self!.mtaModel.Buses.count == 0 {
                                print("count 0")
                            }
                        }
                })
        }
    }
    
    fileprivate func refreshCarousel(addArrows: Bool = true) {
        let centerX = tracker.center.x
        let centerY = tracker.center.y
        let radiusWidth = mapView.frame.maxX/2.0
        let radiusHeight = mapView.frame.maxY/2.0
        for (index, mtaStop) in mtaStops.enumerated() where index < 6 {
            mapView.addSubview(mtaStop)
            UIView.animateKeyframes(withDuration: 0.25, delay: 0.0, options: .allowUserInteraction, animations: {
                if index == 0 {
                    mtaStop.center = CGPoint(x: centerX + radiusWidth*0.25, y: centerY - radiusHeight*0.25)
                } else if index == 1 {
                    mtaStop.center = CGPoint(x: centerX + radiusWidth*0.50, y: centerY)
                } else if index == 2 {
                    mtaStop.center = CGPoint(x: centerX + radiusWidth*0.25, y: centerY + radiusHeight*0.25)
                } else if index == 3 {
                    mtaStop.center = CGPoint(x: centerX - radiusWidth*0.25, y: centerY + radiusHeight*0.25)
                } else if index == 4 {
                    mtaStop.center = CGPoint(x: centerX - radiusWidth*0.50, y: centerY)
                } else if index == 5 {
                    mtaStop.center = CGPoint(x: centerX - radiusWidth*0.25, y: centerY - radiusHeight*0.25)
                }
                }, completion: { [unowned self] (success) in
                    if success && self.mtaModel != nil {
                        if addArrows {
                            if self.mtaModel.Buses.count > 6 {
                                for arrow in self.arrows {
                                    self.mapView.addSubview(arrow)
                                }
                            } else {
                                for arrow in self.arrows {
                                    arrow.removeFromSuperview()
                                }
                            }
                        }
                    }
                })
        }
    }
    
    func refetch(scrollToBottom: Bool = false) {
        if mtaDataSource != nil {
            startSpinning()
            Bus.GetIncomingBuses(buses: self.mtaDataSource!.buses, configuration: self.configuration, skeleton: mtaDataSource!.skeleton, callback: { [unowned self] in
                self.stopSpinning()
                self.tableView.reloadData()
                if let section = self.mtaDataSource?.numberOfSections {
                    if let row = self.mtaDataSource?.numberOfRowsForSection(section: section) {
                        if scrollToBottom { self.scrollToItem(row, section: section - 1, position: .middle, animated: true) }
                    }
                }
            })
        }
    }
    
    // MARK: - Gestures
    
    func mtaViewTapGesture(_ gesture: UITapGestureRecognizer)  {
        if let mtaView = gesture.view as? MTAView {
            switch  gesture.state {
            case .began, .changed:
                mtaView.startedTap()
            default:
                mtaView.endedTap()
                Bus.GetSkeleton(buses: mtaView.getBuses(), configuration: configuration, callback: { [unowned self] (skeleton: SkeletonForRoute) in
                    self.mtaDataSource = MTADataSource(buses: mtaView.getBuses(), skeleton: skeleton)
                })
            }
        }
    }
    
    func centerButtonTapped(_ gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            centerButton.startedTap()
        default:
            centerButton.endedTap()
            switch CLLocationManager.authorizationStatus() {
            case .authorizedWhenInUse, .authorizedAlways:
                mapView.setUserTrackingMode(.follow, animated: true)
                tracker.isHidden = true
            default:
                displaySettingsAlert()
            }
        }
    }
    
    func rightArrowButtonTapped(_ gesture: UITapGestureRecognizer) {
        if let arrowView = gesture.view as? RightArrowView {
            switch  gesture.state {
            case .began, .changed:
                arrowView.startedTap()
            default:
                arrowView.endedTap()
                shiftRight()
            }
        }
    }
    
    func leftArrowButtonTapped(_ gesture: UITapGestureRecognizer) {
        if let arrowView = gesture.view as? LeftArrowView {
            switch  gesture.state {
            case .began, .changed:
                arrowView.startedTap()
            default:
                arrowView.endedTap()
                shiftLeft()
            }
        }
    }
    
    func shiftRight() {
        // shift mtaviews right
        if self.mtaModel != nil {
            if mtaModel.Buses.count > 6 {
                var shiftStops = [[Bus]]()
                for (index, bus) in mtaModel.Buses.enumerated() where index < 6 {
                    shiftStops.append(bus)
                }
                mtaModel.Buses.remove(at: 0)
                mtaModel.Buses.remove(at: 0)
                mtaModel.Buses.remove(at: 0)
                mtaModel.Buses.remove(at: 0)
                mtaModel.Buses.remove(at: 0)
                mtaModel.Buses.remove(at: 0)
                mtaModel.Buses.append(contentsOf: shiftStops)
                mtaModel = MTAModel(buses: mtaModel.Buses)
            }
        }
    }
    
    func shiftLeft() {
        // shift mtaviews left
        if self.mtaModel != nil {
            if mtaModel.Buses.count > 6 {
                var shiftStops = [[Bus]]()
                for (index, bus) in mtaModel.Buses.reversed().enumerated() where index < 6 {
                    shiftStops.append(bus)
                }
                mtaModel.Buses.remove(at: mtaModel.Buses.count - 1)
                mtaModel.Buses.remove(at: mtaModel.Buses.count - 1)
                mtaModel.Buses.remove(at: mtaModel.Buses.count - 1)
                mtaModel.Buses.remove(at: mtaModel.Buses.count - 1)
                mtaModel.Buses.remove(at: mtaModel.Buses.count - 1)
                mtaModel.Buses.remove(at: mtaModel.Buses.count - 1)
                shiftStops = shiftStops.reversed()
                shiftStops.append(contentsOf: mtaModel.Buses)
                mtaModel = MTAModel(buses: shiftStops)
            }
        }
    }
    
    // make a func that fades off mtaviews and removes them and then refreshesCarosol

    // MARK: - Core Location Delegate Methods
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            displayNYC()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            // let currentCoordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                if error != nil {
                    print("geocoder error ->\(error?.localizedDescription)")
                } else {
                    if let currentLocation = placemarks?.last {
                        if let zipcode = currentLocation.postalCode {
                            print("zipcode -> \(zipcode)")
                            if !Zipcodes.zipcodes.contains(zipcode) {
                                self.displayShowNYCAlert()
                            }
                        } else {
                            self.displayShowNYCAlert()
                        }
                    }
                }
            })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("DidFailWithError -> \(error.localizedDescription)")
        displayNYC()
    }
    
    // MARK: - Map View Delegate Methods
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if tracker.isHidden { tracker.isHidden = false }
        tracker.alpha = 0.5
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        tracker.alpha = 1.0
        // Get Train and Bus Info
        let currentCoordinate = mapView.centerCoordinate
        if centerCoordinate == nil {
            getNearestStops(currentCoordinate.latitude, longitude: currentCoordinate.longitude, latSpan: range, lonSpan: range)
        } else if !centerCoordinate!.isNear(currentCoordinate, by: 0.0001) {
            getNearestStops(currentCoordinate.latitude, longitude: currentCoordinate.longitude, latSpan: range, lonSpan: range)
        }
        centerCoordinate = currentCoordinate
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let header = tableView.tableHeaderView as? ParallaxTableHeaderView {
            header.layoutForContentOffset(tableView.contentOffset)
            self.tableView.tableHeaderView = header
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - HTTP Requests
    
    fileprivate func getNearestStops(_ latitude: CLLocationDegrees, longitude: CLLocationDegrees, latSpan: Double, lonSpan: Double) {
        if let url = "\(configuration.environment.stopsForLocationBaseURL)&lat=\(latitude)&lon=\(longitude)&latSpan=\(latSpan)&lonSpan=\(lonSpan)".stringByAddingPercentEncodingForRFC3986() {
            Alamofire.request(url).validate(statusCode: 200..<300).validate(contentType: ["application/json"]).responseJSON { [unowned self] response in
                switch response.result {
                case .success:
                    if let result = response.result.value as? [String: AnyObject] , response.result.isSuccess {
                        if let nearbyStops = result["data"]!["stops"] as? [[String: AnyObject]] {
                            // print("nearbyStops -> \(nearbyStops)")
                            self.mtaModel = MTAModel(stops: nearbyStops)
                        }
                    }
                case .failure(let error):
                    print("Error receiving nearby stops. -> \(error)")
                }
            }
        }
    }
    
    
    // MARK: - Table View DataSource Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return mtaDataSource?.numberOfSections ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // print("numberOfRowsInSection -> \(mtaDataSource?.numberOfRowsForSection(section: section))")
        return mtaDataSource?.numberOfRowsForSection(section: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MTATableViewCell
        if mtaDataSource != nil {
            cell.bus = mtaDataSource!.organizedBuses[indexPath.section][indexPath.row]
            cell.layoutMargins = UIEdgeInsets.zero
        }
        
        return cell
    }
    
    fileprivate func scrollToItem(_ item: Int, section: Int, position: UITableViewScrollPosition, animated: Bool = false) {
        let indexPath = IndexPath(item: item, section: section)
        tableView.scrollToRow(at: indexPath, at: position, animated: animated)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // set title to proper destination name
        return mtaDataSource?.titleForSection(section: section)
    }
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let titleLabel = UILabel()
//        titleLabel.text = mtaDataSource?.titleForSection(section: section)
//        titleLabel.textAlignment = .center
//        titleLabel.adjustsFontSizeToFitWidth = true
//        return titleLabel
//    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textAlignment = .center
            headerView.textLabel?.adjustsFontSizeToFitWidth = true
        }
    }
    
    
    
    // MARK: - Navigation
    
    enum SegueIdentifier: String {
        case Route
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifierForSegue(segue) {
        case .Route:
            if let rvc = segue.destination as? RouteViewController, let cell = sender as? MTATableViewCell {
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem
                rvc.bus = cell.bus
                rvc.skeleton = mtaDataSource?.skeleton
            }
        }
    }

}

extension CGPoint {
    func isNear(_ point: CGPoint, by distance: CGFloat) -> Bool {
        let xDistance = abs(self.x) - abs(point.x)
        let yDistance = abs(self.y) - abs(point.y)
        let distBetweenPoints = sqrt((xDistance*xDistance) + (yDistance*yDistance))
        if distBetweenPoints <= distance { return true }
        return false
    }
}

extension CLLocationCoordinate2D {
    func isNear(_ point: CLLocationCoordinate2D, by distance: Double) -> Bool {
        let latitudeDistance = abs(self.latitude) - abs(point.latitude)
        let longitudeDistance = abs(self.longitude) - abs(point.longitude)
        let distBetweenPoints = sqrt((latitudeDistance*latitudeDistance) + (longitudeDistance*longitudeDistance))
        if distBetweenPoints <= distance { return true }
        return false
    }
}

extension String {
    func stringByAddingPercentEncodingForRFC3986() -> String? {
        let unreserved = "-._~/?=&:"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return self.addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}

extension UIColor {
    class func hexStringToUIColor(_ hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespaces).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString = cString.substring(from: cString.characters.index(cString.startIndex, offsetBy: 1))
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor (
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    class func goldColor() -> UIColor {
        // return UIColor(colorLiteralRed: 252.0/255.0, green: 194.0/255.0, blue: 0, alpha: 1.0)
        return UIColor.white
    }
    
    class func gold() -> UIColor {
        return UIColor(colorLiteralRed: 252.0/255.0, green: 194.0/255.0, blue: 0, alpha: 1.0)
    }
    
    func lighter(percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust( percentage: abs(percentage) )
    }
    
    func darker(percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust( percentage: -1 * abs(percentage) )
    }
    
    func adjust(percentage:CGFloat=30.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0;
        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        } else {
            return nil
        }
    }
}
