//
//  DriverTableViewController.swift
//  
//
//  Created by Brian Kim on 2020-08-08.
//

// Import necessary libraries
import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit

// Inherit CLLocationManagerDelegate
class DriverTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    // Object declarations
    // rideRequests is an array of all the ride request data snapshots of the database
    var rideRequests:[DataSnapshot] = []
    var locationManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the location manager to start updating location of the current driver
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Query the database to get the tuples in the RideRequests to check if any ride request has a driver assigned
        Database.database().reference().child("RideRequests").observe(.childAdded) { (snapshot) in
            // Each of the snapshots is each object. In this case 'ride request'
            // Unwrap the
            if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                    
                } else {
                    // if there is a driver assigned to this ride request data snapshot, append it to the rideRequests array
                    self.rideRequests.append(snapshot)
                    self.tableView.reloadData()
                }
            }
        }
        
        // Set up a timer to reload the tableView data every 3 seconds
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            self.tableView.reloadData()
        }
    }
    
    // If the current driver user's location change, update that coordinate to the driverLocation variable
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate {
            driverLocation = coord
        }
    }
    
    // Set the table view's number of rows to the number of items in rideRequests array
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rideRequests.count
    }
    
    // Set up each cell in table view
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Unwrap snapshot's value as a dictionary to unwrap its email and coordinates
        let snapshot = rideRequests[indexPath.row]
        if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
            if let email = rideRequestDictionary["email"] as? String {
                if let lat = rideRequestDictionary["lat"] as? Double {
                    if let lon = rideRequestDictionary["lon"] as? Double {
                        // With the information unwrapped from the dictionary, calculate the distance between the rider's location and the driver's location
                        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                        let riderCLLocation = CLLocation(latitude: lat, longitude: lon)
                        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
                        let roundedDistance = round(distance * 100) / 100
                        
                        // Display the rider's email and the distance between rider and current driver's locations
                        cell.textLabel?.text = "\(email) - \(roundedDistance)km away"
                    }
                }
            }
        }
        
        return cell
    }
    
    // When the cell is selected perform segueway to the AcceptRequestViewController and send the data snapshot of the selected cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let snapshot = rideRequests[indexPath.row]
        performSegue(withIdentifier: "acceptSegue", sender: snapshot)
    }
    
    // Prepare function for performing segue -- runs before every performSegue()
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Unwrap the passed sender object and its email and coordinate values and assign them to the AcceptRequestViewController's location variables
        if let acceptVC = segue.destination as? AcceptRequestViewController {
            if let snapshot = sender as? DataSnapshot {
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                    if let email = rideRequestDictionary["email"] as? String {
                        if let lat = rideRequestDictionary["lat"] as? Double {
                            if let lon = rideRequestDictionary["lon"] as? Double {
                                acceptVC.requestEmail = email
                                
                                let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                acceptVC.requestLocation = location
                                acceptVC.driverLocation = driverLocation
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Logout Function
    @IBAction func logoutTapped(_ sender: Any) {
        try? Auth.auth().signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
