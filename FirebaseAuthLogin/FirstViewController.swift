//
//  FirstViewController.swift
//  FirebaseAuthLogin
//
//  Created by Nice on 6/8/18.
//  Copyright © 2018 eatigo. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func login(_ sender: Any) {
        let service = FirebaseAPIService()
        guard let email = emailTextField?.text, let password = passwordTextField?.text else {
            NSLog("Please fill in Email/Password")
            return
        }
        
        service.login(email: email, password: password) { token, error in
            if error == nil {
                NSLog("logged-in")
            } else {
                NSLog("error \(error?.localizedDescription ?? "")")
            }
        }
    }
}

