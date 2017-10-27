//
//  DetailViewController.swift
//  Interview Exercise
//
//  Created by mike davis on 9/11/16.
//  Copyright © 2016 mike davis. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var stateAndZipLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var friendsTableView: UITableView!
    
    @IBOutlet weak var friendsSpacerAbove: UIView!
    @IBOutlet weak var friendsHeaderLabel: UILabel!
    @IBOutlet weak var friendsSpacerBelow: UIView!
    
    /// Delegate for providing support for actions on friends of a person.
    weak var friendActionDelegate: FriendActionDelegate? = nil
    
    /// Person shown in view controller.
    var person: Person? {
        didSet {
            self.configureText()
        }
    }
    
    /// Image of person shown in view controller.
    var image: UIImage? {
        didSet {
            self.configureImage()
        }
    }
    
    /// List of friends for person shown in view controller.
    var friends: [Person]? {
        didSet {
            self.configureTable()
        }
    }
    
    // MARK: - Helper Methods
    
    fileprivate func configureText() {
        self.usernameLabel?.text = self.person?.username
        self.emailLabel?.text = self.person?.email
        self.phoneLabel?.text = self.person?.phoneNumber
        self.addressLabel?.text = self.person?.address

        switch (self.person?.state, self.person?.zipCode) {
        case (nil, nil):
            self.stateAndZipLabel?.text = nil
        case (let state, nil):
            self.stateAndZipLabel?.text = state
        case (nil, let zipcode):
            self.stateAndZipLabel?.text = zipcode
        case (let state, let zipcode):
            self.stateAndZipLabel?.text = state! + ", " + zipcode!
        }
    }
    
    fileprivate func configureImage() {
        self.imageView?.image = self.image
    }
    
    fileprivate func configureTable() {
        if let friends = self.friends
            , friends.isEmpty == false {
                self.friendsSpacerAbove?.isHidden = false
                self.friendsSpacerBelow?.isHidden = false
                self.friendsHeaderLabel?.isHidden = false
                self.friendsTableView?.separatorStyle = UITableViewCellSeparatorStyle.singleLine
                self.friendsTableView?.reloadData()
        }
        else {
            // Note that you must change priority of height constraints to less
            // than 1000 in IB for this to not cause runtime constraint warnings.
            self.friendsSpacerAbove?.isHidden = true
            self.friendsSpacerBelow?.isHidden = true
            self.friendsHeaderLabel?.isHidden = true
            self.friendsTableView?.separatorStyle = UITableViewCellSeparatorStyle.none
        }
    }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureText()
        self.configureImage()
        self.configureTable()
    }
}

// MARK: - TableView DataSource

extension DetailViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friends?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendTableViewCell", for: indexPath) as! FriendTableViewCell
        let index = (indexPath as NSIndexPath).row
        
        if let friend = self.friends?[index] {
            // TODO: localized representation of name.
            cell.friendNameLabel?.text = friend.lastName + ", " + friend.firstName
            cell.friendImageView?.image = self.friendActionDelegate?.imageForFriend(friend.id)
            cell.isUserInteractionEnabled = true
        }
        return cell
    }
}

// MARK: - TableView Delegate

extension DetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = (indexPath as NSIndexPath).row
        if let friend = self.friends?[index] {
            self.friendActionDelegate?.selectFriend(friend.id)
        }
    }
}

// MARK: - Protocol for actions on friends.

protocol FriendActionDelegate: class {
    func imageForFriend(_ identifier: String) -> UIImage?
    func selectFriend(_ identifier: String)
}

