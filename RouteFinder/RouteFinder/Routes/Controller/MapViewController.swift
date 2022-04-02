//
//  MapViewController.swift
//  RouteFinder
//
//  Created by Vaishnavi B on 2022-04-02.
//

import UIKit
import MapKit
import CoreLocation

enum AlertType {
    case alert
    case openSettings
}

class MapViewController: UIViewController {

    @IBOutlet weak var stopTextfield: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager?
    var locations = [Location]()
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager = CLLocationManager()
        self.mapView.delegate = self
        self.checkForLocationPermissions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.mapView = nil
        self.locationManager = nil
    }

    //MARK: - Location Settings
    func checkForLocationPermissions() {
        self.locationManager?.requestAlwaysAuthorization()
    }
    
    func showAlert(title: String, description: String, alertType: AlertType) {
        let alertController = UIAlertController(title: title, message: description, preferredStyle: .alert)
        
        if alertType == .openSettings {
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancel)
            
            let settings = UIAlertAction(title: "Open Settings", style: .default) { action in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            alertController.addAction(settings)
        } else if alertType == .alert {
            let cancel = UIAlertAction(title: "Okay", style: .default, handler: nil)
            alertController.addAction(cancel)
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - Find Destination Location
    func findLocationAndAddStopFor(location: String) {
        LocationManager.shared.findLocation(locationName: location) { isSuccess, locations in
            guard let location = locations.first else {
                self.showAlert(title: "", description: enterLocation, alertType: .alert)
                return
            }
            self.addDestination(forLocation: location)
            self.locations.append(location)
        }
    }
    
    //MARK: - Render routes on Map
    //Add Destination
    func addDestination(forLocation location: Location) {
        let annotation = MKPointAnnotation()
        annotation.title = location.locationName
        annotation.coordinate = location.locationCoordinate
        self.mapView.addAnnotation(annotation)
        self.mapView.setRegion(MKCoordinateRegion(center: location.locationCoordinate , span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)), animated: true)
    }
    
    //Adding direction overlay between source and destination
    func renderRouteForLocations(source: Location, destination: Location) {
        let sourcePlacemark = MKPlacemark(coordinate: source.locationCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destination.locationCoordinate)
        let request = MKDirections.Request()
        request.transportType = .automobile
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)

        let direction = MKDirections(request: request)
        direction.calculate { response, error in
            guard let route = response?.routes.first else {
                self.showAlert(title: "", description: error?.localizedDescription ?? somethingWentWrong, alertType: .alert)
                return
            }
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
        }
    }
    
    //Render routes for array of locations
    func renderMapRoutes() {
        for index in 0..<self.locations.count-1 {
            self.renderRouteForLocations(source: locations[index], destination: locations[index+1])
        }
    }
    
    //MARK: - IBAction
    @IBAction func renderRoutes_Action(_ sender: Any) {
        guard self.locationManager?.authorizationStatus != .authorizedAlways || self.locationManager?.authorizationStatus != .authorizedWhenInUse else {
            self.showAlert(title: openSettingsTitle, description: openSettingsDescription, alertType: .openSettings)
            return
        }
        guard self.locations.count > 1 else {
            self.showAlert(title: "", description: addMultipleLocations, alertType: .alert)
            return
        }
        self.renderMapRoutes()
    }
    
    @IBAction func addStops_Action(_ sender: Any) {
        guard let stop = self.stopTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines), stop.count > 0 else {
            self.showAlert(title: "", description: enterLocation, alertType: .alert)
            return
        }
        self.findLocationAndAddStopFor(location: stop)
    }
}

//MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .purple
        renderer.lineWidth = 5
        return renderer
    }
}

//MARK: - UITextFieldDelegate
extension MapViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
