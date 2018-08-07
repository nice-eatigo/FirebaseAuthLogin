//
//  SecondViewController.swift
//  FirebaseAuthLogin
//
//  Created by Nice on 6/8/18.
//  Copyright © 2018 eatigo. All rights reserved.
//

import UIKit
import Firebase

class SecondViewController: UIViewController {
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            self.reload()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    func reload() {
        guard let currentUser = Auth.auth().currentUser else {
            NSLog("hasn't logged in yet.")
            return
        }
        
        currentUser.getIDTokenResult { result, error in
            let token = result?.token
            let expired = result?.expirationDate
            self.infoLabel?.text = "\(currentUser.email ?? "")\nExpired=\(expired?.debugDescription ?? "")\n\nToken=\(token ?? "")"
        }
    }
}

