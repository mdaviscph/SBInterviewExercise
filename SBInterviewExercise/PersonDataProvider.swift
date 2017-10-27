//
//  PersonDataProvider.swift
//  Interview Exercise
//
//  Created by mike davis on 9/11/16.
//  Copyright © 2016 mike davis. All rights reserved.
//

import Foundation

protocol PersonDataProvider: class {
    func requestPersonData(_ personNumber: Int, completion: @escaping (_ person: Person?, _ number: Int, _ error: Error?) -> Void)
    func requestPersonImageData(_ identifier: String, urlPath: String, completion: @escaping (_ data: Data?, _ identifier: String, _ error: Error?) -> Void)
    func requestPersonFriends(_ personId: String, completion: @escaping (_ friends: [Person]?, _ id: String, _ error: Error?) -> Void)
}

class PersonDataProviderService: PersonDataProvider {

    fileprivate struct Constants {
        /// Number of persons per page for GET call.
        static let peopleApiParamPersonsPerPage = 10
        /// REST API call people path format string
        /// TODO: format the URL using NSURLComponents or use String URL path formatting.
        static let peopleApiPathFormat = "https://interview-api.somecompany.com/people?page=%d&perPage=%d"
        /// REST API call friends path format string
        /// TODO: format the URL using NSURLComponents or use String URL path formatting.
        static let friendsApiPathFormat = "https://interview-api.somecompany.com/friends?personID=%@"
        /// Domain used when creating NSError objects.
        static let errorDomain = "com.somecompany.mdaviscph.exercise"
    }
    
    fileprivate enum ErrorCode: Int {
        case badHttpStatus = 100
        case badJsonFormat = 101
        case badImagePath  = 102
        var code: Int {
            return self.rawValue
        }
    }
    
    fileprivate var pageRequestPending = [Int : Date]()
    
    /// Request data for person. Note that based on how the REST API call works we will actually be 
    /// requesting a "page" of people where number of people in page is defined as a query parameter.
    /// The first request for a page will result in a call to the completion closure for each person
    /// and additional requests for the page (prior to a return of data) will immediately return.
    func requestPersonData(_ personNumber: Int, completion: @escaping (_ person: Person?, _ number: Int, _ error: Error?) -> Void) {
        
        /// 0 to N page number. Note that REST API call uses 1 to N+1.
        let page = Int(personNumber / Constants.peopleApiParamPersonsPerPage)
        
        // Check to see if we have recently requested people for the page that this person is "on".
        // If so then ignore as there is a pending recent request.
        if let _ = self.pageRequestPending[page] {
            return
        }
        self.pageRequestPending[page] = Date()
        
        /// Path and query parameter for retrieving a page of person data.
        let urlPath = String(format: Constants.peopleApiPathFormat, page + 1, Constants.peopleApiParamPersonsPerPage)
        print(urlPath)
        
        if let url = URL(string: urlPath) {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: request) {
                (data: Data?, response: URLResponse?, error: Error?) in
                if let error = error {
                    // TODO: create new error with additional info in userInfo.
                    completion(nil, personNumber, error)
                }
                else if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    if (200...203 ~= statusCode) == false {
                        // TODO: add additional info including status code to userInfo.
                        let error = NSError(domain: Constants.errorDomain, code: ErrorCode.badHttpStatus.code, userInfo: nil)
                        completion(nil, personNumber, error)
                    }
                    else if let data = data {
                        do {
                            // Format is a dictionary with key of "people" which is an array of dictionaries.
                            if let objectDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject],
                                let people = objectDict["people"] as? [[String : AnyObject]] {
                                    for (index, personDict) in people.enumerated() {
                                        if let person = Person(jsonDict: personDict) {
                                            let number = page * Constants.peopleApiParamPersonsPerPage + index
                                            //print("\(person.lastName), \(person.firstName) number: \(number)")
                                            completion(person, number, nil)
                                        }
                                    }
                            }
                            else {
                                // JSON data not if form expected.
                                // TODO: add additional info to userInfo.
                                let error = NSError(domain: Constants.errorDomain, code: ErrorCode.badJsonFormat.code, userInfo: nil)
                                completion(nil, personNumber, error)
                            }
                        } catch let error as NSError {
                            // JSON data cannot be serialized.
                            // TODO: add additional info to userInfo.
                            completion(nil, personNumber, error)
                        }
                    }
                }
                self.pageRequestPending[page] = nil
            }
            task.resume()
        }
        else {
            // Unable to create an NSURL object. Should never happen.
            fatalError("Unable to create an NSURL object using: <\(urlPath)>")
        }
    }
    
    // Request image for a person. Separate request for each person since each person's imageURL is different.
    func requestPersonImageData(_ identifier: String, urlPath: String, completion: @escaping (_ data: Data?, _ identifier: String, _ error: Error?) -> Void) {
        
        if let url = URL(string: urlPath) {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: request) {
                (data: Data?, response: URLResponse?, error: Error?) in
                if let error = error {
                    // TODO: create new error with additional info in userInfo.
                    completion(nil, identifier, error)
                }
                else if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    if (200...203 ~= statusCode) == false {
                        // TODO: add additional info including status code to userInfo.
                        let error = NSError(domain: Constants.errorDomain, code: ErrorCode.badHttpStatus.code, userInfo: nil)
                        completion(nil, identifier, error)
                    }
                    else if let data = data {
                        completion(data, identifier, nil)
                    }
                }
            }
            task.resume()
        }
        else {
            // Unable to create an NSURL object. Possible since path is from the server.
            // TODO: add additional info such as image path to userInfo.
            print("Unable to create an NSURL object using: <\(urlPath)>")
            let error = NSError(domain: Constants.errorDomain, code: ErrorCode.badImagePath.code, userInfo: nil)
            completion(nil,  identifier, error)
        }
    }
    
    // Request a list of friends for a person.
    func requestPersonFriends(_ personId: String, completion: @escaping (_ friends: [Person]?, _ id: String, _ error: Error?) -> Void) {
        
        /// Path and query parameter for retrieving a list of friends.
        let urlPath = String(format: Constants.friendsApiPathFormat, personId)
        print(urlPath)
        
        if let url = URL(string: urlPath) {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: request) {
                (data: Data?, response: URLResponse?, error: Error?) in
                if let error = error {
                    // TODO: create new error with additional info in userInfo.
                    completion(nil, personId, error)
                }
                else if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    if (200...203 ~= statusCode) == false {
                        // TODO: add additional info including status code to userInfo.
                        let error = NSError(domain: Constants.errorDomain, code: ErrorCode.badHttpStatus.code, userInfo: nil)
                        completion(nil, personId, error)
                    }
                    else if let data = data {
                        do {
                            // Format is a dictionary with key of "friends" which is an array of dictionaries.
                            if let objectDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject],
                                let people = objectDict["friends"] as? [[String : AnyObject]] {
                                var friends = [Person]()
                                for personDict in people {
                                    if let friend = Person(jsonDict: personDict) {
                                        friends.append(friend)
                                    }
                                }
                                completion(friends, personId, nil)
                            }
                            else {
                                // JSON data not if form expected.
                                // TODO: add additional info to userInfo.
                                let error = NSError(domain: Constants.errorDomain, code: ErrorCode.badJsonFormat.code, userInfo: nil)
                                completion(nil, personId, error)
                            }
                        } catch let error as NSError {
                            // JSON data cannot be serialized.
                            // TODO: add additional info to userInfo.
                            completion(nil, personId, error)
                        }
                    }
                }
            }
            task.resume()
        }
        else {
            // Unable to create an NSURL object. Possible since path is from the server.
            // TODO: add additional info such as image path to userInfo.
            print("Unable to create an NSURL object using: <\(urlPath)>")
            let error = NSError(domain: Constants.errorDomain, code: ErrorCode.badImagePath.code, userInfo: nil)
            completion(nil, personId, error)
        }
    }
}
