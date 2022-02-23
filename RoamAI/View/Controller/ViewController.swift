//
//  ViewController.swift
//  RoamAI
//
//  Created by Sumit Bangarwa on 18/02/22.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var startEndButton: UIButton!
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var placesClient: GMSPlacesClient?
    var preciseLocationZoomLevel: Float = 15.0
    var approximateLocationZoomLevel: Float = 10.0
    let geoCoder = CLGeocoder()
    var geoMarker = GMSMarker()
    var viewModel = MapsViewModel()
    var timer = Timer()
    var tripStarted = false
    var tripStartedTimeStamp = ""
    var currentTimeStamp: String {
        return "\(Int64(Date().timeIntervalSince1970 * 1000))"
    }
    
    var tripId = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNav()
        initiallLocationSetUPSetup()
    }
    
    
    func initiallLocationSetUPSetup() {
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .notDetermined, .restricted, .denied:
                showAlert(title: "Request", msg: "Please go to Settings and turn on the location permissions", buttonTitle: "Cancel")
            case .authorizedAlways, .authorizedWhenInUse:
                setUpView()
            @unknown default:
                break
            }
        }
    }
    
    func setupNav() {
        let navigationBar = navigationController?.navigationBar
        let navigationBarAppearance = UINavigationBarAppearance()
//        navigationBarAppearance.shadowColor = .clear
        navigationBar?.scrollEdgeAppearance = navigationBarAppearance
        navigationBar?.topItem?.title = "Roam.AI"
        
        
    }
    
    func setUpView() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50
        
        mapView.delegate = self
        placesClient = GMSPlacesClient.shared()
        startEndButton.setTitle("Start Trip", for: .normal)
        startEndButton.backgroundColor = .green
        startEndButton.layer.cornerRadius = 20
    }
    
    func startTrip() {
        tripStarted = true
        locationManager = CLLocationManager()
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.delegate = self
    }
    
    func endTrip(){
        timer.invalidate()
        locationManager.stopUpdatingLocation()
        startEndButton.setTitle("Start Trip", for: .normal)
        startEndButton.backgroundColor = .green
        let endDataModel = TripDataModel.init(id: "\(tripId)", startTrip: tripStartedTimeStamp, endTrip: currentTimeStamp, data: viewModel.locationdataModel!)
        viewModel.updateTripData(data: endDataModel)
        DispatchQueue.main.async {
            let data =  self.viewModel.createJsonData()
            let retrive = UserDefaults.standard.value(forKey: USER_DEFAULTS.saveTripData)

            print("JSON",data, "KeyData",retrive )
        }
    }
    
    
    
    
    func showAlert(title:String = "",msg:String,buttonTitle:String,singleButton:Bool = false) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
            }
        }
        let cancelAction = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        if !singleButton {
            alertController.addAction(cancelAction)
        }
        alertController.addAction(settingsAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func startEndJourneyAction(sender: UIButton) {
        
        if sender.isSelected {
            sender.isSelected = false
            endTrip()
        }else{
            sender.isSelected = true
            startEndButton.setTitle("End Trip", for: .selected)
            startEndButton.backgroundColor = .red
            tripId += 1
            tripStartedTimeStamp = currentTimeStamp
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { (_) in
                print("Timer Started")
                self.startTrip()
            })
        }
        
    }
    @IBAction func exportDataToPhone(_ sender: Any) {
        
        showAlert(msg: "Your Trip Data stored in your device", buttonTitle: "OK",singleButton: true)
        viewModel.storeJsonToDevice()
    }
    
    
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation: CLLocation = locations.last!
        print("Location last: \(lastLocation), accuracy : \(locationManager.accuracyAuthorization)")
        currentLocation = CLLocation(latitude: lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude)
        let zoomLevel = locationManager.accuracyAuthorization == .fullAccuracy ? preciseLocationZoomLevel : approximateLocationZoomLevel
        let camera = GMSCameraPosition.camera(withLatitude: lastLocation.coordinate.latitude,
                                              longitude: lastLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        
        mapView.camera = camera
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        
        if tripStarted {
            let locationModel = LocationDataModel.init(lat: "\(lastLocation.coordinate.latitude)", lon: "\(lastLocation.coordinate.longitude)", accuracy: "\(locationManager.accuracyAuthorization)", time: currentTimeStamp)
            viewModel.updateLocationData(data: locationModel)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Failed  to update") //show alert
    }
    
}

//MARK: - map Events Delegates
extension ViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        geoMarker.map = nil
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geoMarker = GMSMarker(position: coordinate)
        geoMarker.position = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) { [self] (placeMarkers, error) in
            if let arrayOfPlaces = placeMarkers {
                if let placemark: CLPlacemark = arrayOfPlaces.first {
                    self.geoMarker.map = mapView
                    self.geoMarker.title = placemark.name
                    self.geoMarker.isTappable = true
                    self.geoMarker.appearAnimation = GMSMarkerAnimation.pop
                    self.geoMarker.isFlat = true
                    self.geoMarker.snippet = placemark.subLocality
                    mapView.selectedMarker = self.geoMarker
                }
                
            }
        }
    }
}


