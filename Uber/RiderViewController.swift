//
//  RiderViewController.swift
//  Uber
//
//  Created by Brian Kim on 2020-08-08.
//  Copyright © 2020 Brian Kim. All rights reserved.
//

// Import neccessary libraries
import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

// Inherit CLLocationManagerDelegate
class RiderViewController: UIViewController, CLLocationManagerDelegate {
    // Outlets
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callAnUberButton: UIButton!
    
    // Object declarations
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var uberHasBeenCalled = false
    var driverOnTheWay = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set location manager up with default setting
        // Start updating location of user
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let email = Auth.auth().currentUser?.email {
            // Query through the database child 'RideRequests' to find an entry with the user's emails
            // Completion handler
            Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded) { (snapshot) in
                // In this completion handler, set uberHasBeenCalled to true, set title of call button to cancel button
                // And remove the observer from the database
                self.uberHasBeenCalled = true
                self.callAnUberButton.setTitle("Cancel Uber", for: [])
                Database.database().reference().child("RideRequests").removeAllObservers()
                
                // Checks to see if this snapshot (ride request) has been accepted by a driver nearby
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                        if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                            // If there is a driver set for this request, set the values accordingly
                            // Also call displayDriverAndRider function in order to set up the map in its accordance
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            self.driverOnTheWay = true
                            self.displayDriverAndRider()
                            
                            // Query through the database to observe if the entry with the current user's email has been updated
                            // ie. if the assigned driver's location has been updated in database
                            if let email = Auth.auth().currentUser?.email {
                                Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged) { (snapshot) in
                                    if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                                        if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                                            if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                                                // Update the driver's location and display it 
                                                self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                                self.driverOnTheWay = true
                                                self.displayDriverAndRider()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // function that update the informations that show the locations of driver and rider if they are matched
    func displayDriverAndRider() {
        // Update the button's title with the distance between the rider and driver
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        callAnUberButton.setTitle("Your driver is \(roundedDistance)km away!", for: [])
        map.removeAnnotations(map.annotations)
        
        // Readjust the map's region's center with the user's location and update the delta of region with the
        // new distance between the driver and the rider
        let latDelta = abs(driverLocation.latitude - userLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - userLocation.longitude) * 2 + 0.005
        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        map.setRegion(region, animated: true)
        
        // Readjust the rider's location annotation
        let riderAnnotation = MKPointAnnotation()
        riderAnnotation.coordinate = userLocation
        riderAnnotation.title = "Your Location"
        map.addAnnotation(riderAnnotation)
        
        // Readjust the driver's location annotation
        let driverAnnotation = MKPointAnnotation()
        driverAnnotation.coordinate = driverLocation
        driverAnnotation.title = "Your Driver"
        map.addAnnotation(driverAnnotation)
    }
    
    // Every time user moves (updates locations), run this function
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Update the user location variable using the location manager's location
        if let coord = manager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            userLocation = center
            
            // if uber has been called and driver has been designated run displayDriverAndRider method
            if uberHasBeenCalled && driverOnTheWay {
                displayDriverAndRider()
            // if uber has not been called or driver has not been designated update the map region center to user location
            } else {
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                map.setRegion(region, animated: true)
                map.removeAnnotations(map.annotations)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "Your Location"
                map.addAnnotation(annotation)
            }
        }
    }
    
    // Action for pressing the Call Uber button
    @IBAction func callUberTapped(_ sender: Any) {
        if let email = Auth.auth().currentUser?.email {
            // If there is no driver assigned yet
            if !driverOnTheWay {
                if uberHasBeenCalled {
                    // Cancel Uber
                    uberHasBeenCalled = false
                    callAnUberButton.setTitle("Call An Uber", for: [])
                    
                    // Query through the RideRequests objects to find the user's request and remove it from database
                    Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded) { (snapshot) in
                        snapshot.ref.removeValue()
                        Database.database().reference().child("RideRequests").removeAllObservers()
                    }
                } else {
                    // Call Uber
                    uberHasBeenCalled = true
                    callAnUberButton.setTitle("Cancel Uber", for: [])
                    
                    // Add the ride request entry into the rideRequestDictionary with the user's email, latitude and longitude
                    // Also set the value of the database child 'RideRequests' to the dictionary
                    let rideRequestDictionary: [String:Any] = ["email":email, "lat":userLocation.latitude, "lon":userLocation.longitude]
                    Database.database().reference().child("RideRequests").childByAutoId().setValue(rideRequestDictionary)
                }
            }
        }
    }
    
    // Action for pressing the log out button
    @IBAction func logoutTapped(_ sender: Any) {
        // Try and sign out using Auth.auth().signOut()
        try? Auth.auth().signOut()
        
        // Exit out of the current nagivation controller using .dismiss()
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
