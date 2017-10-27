//
//  MasterViewController.swift
//  Interview Exercise
//
//  Created by mike davis on 9/11/16.
//  Copyright © 2016 mike davis. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    /// Shows a persons detail information and a list of friends
    var detailViewController: DetailViewController? = nil
    
    /// Provider object for web services. Note, not a weak var because we are the only reference
    /// to the class and it does not maintain any reference to this view controller.
    var personDataProviderDelegate: PersonDataProvider? = nil
    
    /// Backing store for people with the key being the row number. A dictionary is used because with
    /// scrolling it is possible to have gaps in the indices where we never need to retrieve people.
    fileprivate var persons = [Int : Person]()

    /// Backing store for images for people with the key being the person ID. A dictionary is used
    /// because with scrolling it is possible to have gaps in the indices where we never need to
    /// retrieve images.
    /// TODO: determine how often we need to clear this cache.
    fileprivate var personImages = [String : UIImage]()
    
    /// Backing store for friends for people with the key being the person ID. A dictionary is used
    /// because with scrolling it is possible to have gaps in the indices where we never need to
    /// retrieve images.
    /// TODO: determine how often we need to clear this cache.
    fileprivate var personFriends = [String : [Person]]()
    
    /// Count of the number of persons that are in the tableView so far.
    fileprivate var personCount = 0
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Consider injecting the PersonDataProviderService instance.
        self.personDataProviderDelegate = PersonDataProviderService()
        
        // When the split view interface is expanded, this property contains two view controllers; when
        // it is collapsed, this property contains only one view controller. The first view controller
        // in the array is always the primary (or master) view controller. If a second view controller
        // is present, that view controller is the secondary (or detail) view controller.
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers.last as! UINavigationController).topViewController as? DetailViewController
        }
        
        // Set up pull-down refresh.
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(self.resetPeopleData), for: UIControlEvents.valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
       self.clearsSelectionOnViewWillAppear = self.splitViewController?.isCollapsed ?? true
       super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.personImages = [:]
        self.personFriends = [:]
        self.resetPeopleData()
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            // Get a copy of the person's data if we have it.
            if let indexPath = self.tableView.indexPathForSelectedRow,
                let person = self.persons[(indexPath as NSIndexPath).row] {
                    let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                
                    // TODO: localized representation of name.
                    controller.title = person.firstName + " " + person.lastName
                    controller.person = person
                    controller.image = self.personImages[person.id]

                    if let friends = self.personFriends[person.id] {
                        controller.friends = friends
                    }
                    else {
                        // Only request friends from the server if looking at a person's detail and we haven't cached.
                        controller.friends = nil
                        self.loadPersonFriendsFromServer(person.id)
                    }
                
                    controller.friendActionDelegate = self
                    controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                    controller.navigationItem.leftItemsSupplementBackButton = true
                    self.detailViewController = controller
            }
        }
    }

    // MARK: - Helper Methods
    
    /// Select a person in the tableView.
    func selectPerson(_ number: Int) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: number, section: 0)
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
            self.performSegue(withIdentifier: "showDetail", sender: self)
        }
    }
    
    /// Reset cached person data for all people and reload tableView. Note, does not reset
    /// image cache or friends cache.
    @objc func resetPeopleData() {
        // personImages and personFriends are keyed by person.id so we do not need to reset.
        // because the identifier is unique and not dependent on the tableView row order.
        self.personCount = 0
        self.persons = [:]
        DispatchQueue.main.async {
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    /// Load data and image using the PersonDataProvider delegate.
    /// TODO: Refactor to better handle (and differentiate) the use of personNumber vs. number.
    fileprivate func loadPersonDataFromServer(_ personNumber: Int) {
        // Fire off server call to get person data.
        self.personDataProviderDelegate?.requestPersonData(personNumber) {
            (person, number, error) in
            if let error = error {
                // TODO: retry.
                print("Person data error: \(error.localizedDescription)")
            }
            else if let person = person {
                
                // See if we need to get an image from the server.
                if self.personImages[person.id] == nil,
                    let urlPath = person.imageURL
                    , urlPath.isEmpty == false {
                        self.loadPersonImageFromServer(person.id, urlPath: urlPath)
                }
                self.persons[number] = person
                self.personCount += 1

                // Reload the table on return of person data. Because we are caching the person data we
                // can simply reload all rows visible (plus a few) in the table each time.
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            }
        }
    }

    /// Load an image for a person using the PersonDataProvider delegate.
    fileprivate func loadPersonImageFromServer(_ identifier: String, urlPath: String) {
        // Fire off server call for image.
        self.personDataProviderDelegate?.requestPersonImageData(identifier, urlPath: urlPath) {
            (data, number, error) in
            if let error = error {
                // TODO: retry?
                print("Person id \(identifier) image error: \(error.localizedDescription)")
            }
            else if let data = data,
                let image = UIImage(data: data) {
                self.personImages[identifier] = image
                
                // Reload the table on return of a person's image. Because we are caching the
                // person data and images we can simply reload all rows visible (plus a few)
                // each time.
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            }
            else {
                // TODO: retry?
                print("Person id \(identifier) image error: no image data or invalid image")
            }
        }
    }
    
    /// Load list of friends using the PersonDataProvider delegate.
    fileprivate func loadPersonFriendsFromServer(_ personId: String) {
        // Fire off server call to get person data.
        self.personDataProviderDelegate?.requestPersonFriends(personId) {
            (friends, id, error) in
            if let error = error {
                // TODO: retry.
                print("Person friends error: \(error.localizedDescription)")
            }
            else if let friends = friends {
                
                // See if we need to get images from the server.
                for person in friends {
                    if self.personImages[person.id] == nil,
                        let urlPath = person.imageURL
                        , urlPath.isEmpty == false {
                        self.loadPersonImageFromServer(person.id, urlPath: urlPath)
                    }
                }
                self.personFriends[personId] = friends
                
                // Tell the detail VC to reload its friends tableView.
                // Note that it is possible that by the time this completion handler
                // executes that a different person is selected so check first.
                if self.detailViewController?.person?.id == personId {
                    DispatchQueue.main.async{
                        self.detailViewController?.friends = friends
                    }
                    // TODO: if there was a server call to get person data for a
                    // specific person or set of people then we might use that here
                    // to preload all of the person data and images for friends.
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Always include an extra row which will cause an attempt to load person data from the server.
        return self.personCount + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeopleTableViewCell", for: indexPath) as! PeopleTableViewCell
        let personNumber = (indexPath as NSIndexPath).row
        
        // Get a copy of the person's data if we already have it cached.
        // TODO: move this code into the cell class and inject the strings and image.
        if let person = self.persons[personNumber] {
            // TODO: localized representation of name.
            cell.personNameLabel?.text = person.lastName + ", " + person.firstName
            cell.personImageView?.image = self.personImages[person.id]
            // TODO: localizd friend count.
            switch person.friendCount {
            case 0:
                cell.friendsCountLabel?.text = nil
            case 1:
                cell.friendsCountLabel?.text = "\(person.friendCount) friend"
            default:
                cell.friendsCountLabel?.text = "\(person.friendCount) friends"
            }
            cell.isUserInteractionEnabled = true
        }
        // Otherwise we must make a server call.
        else {
            cell.personNameLabel?.text = nil
            cell.personImageView?.image = nil
            cell.friendsCountLabel?.text = nil
            cell.isUserInteractionEnabled = false
            // Fire off server call for person data.
            self.loadPersonDataFromServer(personNumber)
        }

        return cell
    }
}

// MARK: - Friend Action Delegate for DetailViewController

extension MasterViewController: FriendActionDelegate {

    /// Return a cached image if one exists.
    func imageForFriend(_ identifier: String) -> UIImage? {
        return self.personImages[identifier]
    }

    /// Select a friend in the tableView if that person has already been retrieved
    /// from the server.
    func selectFriend(_ identifier: String) {
        // Make a copy of self.persons because it is a mutable array and we don't want
        // it changing within the enumeration. Copy is not expensive because each person
        // in dictionary is an object so reference is copied.
        let copyOfPersons = self.persons
        var hasFound = false
        for number in copyOfPersons.keys {
            if let person = copyOfPersons[number]
                , identifier == person.id {
                    hasFound = true
                    self.selectPerson(number)
                    break
            }
        }
        // TODO: handle friend not found?
        if hasFound == false { }
    }
}

