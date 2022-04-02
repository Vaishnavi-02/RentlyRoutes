//
//  LocationManager.swift
//  RouteFinder
//
//  Created by Vaishnavi B on 2022-04-02.
//

import Foundation
import CoreLocation

class LocationManager {
    static let shared = LocationManager()
    
    typealias completion = ((Bool, [Location]) -> Void)
    
    //To find the location coordinates using address string
    public func findLocation(locationName: String, completion: @escaping completion) {
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(locationName) { places, error in
            guard let places = places, error == nil else {
                completion(false, [])
                return
            }
            let locations: [Location] = places.compactMap { place in
                let result = Location(locationName: place.name ?? "", locationCoordinate: place.location?.coordinate ?? CLLocationCoordinate2D())
                return result
            }
            completion(true, locations)
        }
    }
}
