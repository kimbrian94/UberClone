//
//  ViewController.swift
//  Uber
//
//  Created by Brian Kim on 2020-08-07.
//  Copyright © 2020 Brian Kim. All rights reserved.
//
// This is the initial log in / sign up view controller

//import Firebase libraries
import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    // Outlet declarations
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var riderDriverSwitch: UISwitch!
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var topButton: UIButton!
    @IBOutlet weak var bottomButton: UIButton!
    
    // Boolean for checking if user is in sign up mode
    // Default is true
    var signUpMode = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // Action for Login/Signup button
    @IBAction func topTapped(_ sender: Any) {
        // Check if the text fields are not nil
        if emailTextField.text == "" || passwordTextField.text == "" {
            displayAlert(title: "Missing Information", message: "You must provide both a email and password")
        } else {
            // Unwrap the email and password from text fields
            if let email = emailTextField.text {
                if let password = passwordTextField.text {
                    // if sign up mode is true
                    if signUpMode {
                        // SIGN UP
                        // Create a firebase user using Auth.auth().createUser with completion handler
                        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                            if error != nil {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            } else {
                                // Sign Up Success
                                
                                if self.riderDriverSwitch.isOn {
                                    // DRIVER
                                    // Create a profile change request and commit that request
                                    let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                    req?.displayName = "Driver"
                                    req?.commitChanges(completion: nil)
                                    
                                    // Perform segueway to the DriverTableViewController
                                    self.performSegue(withIdentifier: "driverSegue", sender: nil)
                                } else {
                                    // RIDER
                                    let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                    req?.displayName = "Rider"
                                    req?.commitChanges(completion: nil)
                                    
                                    // Perform segueway to the RiderViewController
                                    self.performSegue(withIdentifier: "riderSegue", sender: nil)
                                }
                            }
                        }
                    // if the sign up mode is false. User is trying to log in
                    } else {
                        // LOG IN
                        // Sign in using the email and password using Auth.auth().signIn() with completion handler
                        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                            if error != nil {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            } else {
                                // Log In Success
                                // Perform segue according to their user displayName
                                if user?.user.displayName == "Driver" {
                                    // DRIVER
                                    self.performSegue(withIdentifier: "driverSegue", sender: nil)
                                } else {
                                    // RIDER
                                    self.performSegue(withIdentifier: "riderSegue", sender: nil)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // function for displaying alert with title and message passed
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Action for the bottom Switch to Login / Sign up button
    // switches signUpMode between true and false and all the buttons to its accordance
    @IBAction func buttomTapped(_ sender: Any) {
        if signUpMode {
            topButton.setTitle("Log In", for: .normal)
            bottomButton.setTitle("Switch to Sign Up", for: .normal)
            riderLabel.isHidden = true
            driverLabel.isHidden = true
            riderDriverSwitch.isHidden = true
            signUpMode = false
        } else {
            topButton.setTitle("Sign Up", for: .normal)
            bottomButton.setTitle("Switch to Log In", for: .normal)
            riderLabel.isHidden = false
            driverLabel.isHidden = false
            riderDriverSwitch.isHidden = false
            signUpMode = true
        }
    }
}

