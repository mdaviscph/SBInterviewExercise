//
//  Person.swift
//  Interview Exercise
//
//  Created by mike davis on 9/11/16.
//  Copyright © 2016 mike davis. All rights reserved.
//

import Foundation

/// Represents a person. Required fields are email, id, first & last name, username.
struct Person {
    let address: String?
    let city: String?
    let email: String
    let firstName: String
    let friendCount: Int    // this will likely get out of date and cause a mismatch UX
    let id: String
    let imageURL: String?
    let lastName: String
    let phoneNumber: String?
    let state: String?
    let username: String
    let zipCode: String?

    init?(jsonDict: [String : AnyObject]) {
        guard let email = jsonDict["email"] as? String,
            let firstName = jsonDict["firstName"] as? String,
            let id = jsonDict["id"] as? String,
            let lastName = jsonDict["lastName"] as? String,
            let username = jsonDict["username"] as? String
        else {
            return nil
        }
        
        self.email = email
        self.firstName = firstName
        self.id = id
        self.lastName = lastName
        self.username = username
        
        self.address = jsonDict["address"] as? String
        self.city = jsonDict["city"] as? String
        self.friendCount = jsonDict["friendCount"] as? Int ?? 0
        self.imageURL = jsonDict["imageURL"] as? String
        self.phoneNumber = jsonDict["phoneNumber"] as? String
        self.state = jsonDict["state"] as? String
        self.zipCode = jsonDict["zipCode"] as? String
    }
}
