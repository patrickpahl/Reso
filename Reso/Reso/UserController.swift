//
//  UserController.swift
//  MyPets
//
//  Created by Nathan on 6/8/16.
//  Copyright © 2016 Falcone Development. All rights reserved.
//

import Foundation
import Firebase

class UserController {
    
    static let currentUserKey = "currentUser"
    static let currentUserIdKey = "currentUserIdentifier"
    
//    var currentUserId = "currentUser" // TODO: replace with actual current user id
    
    static let shared = UserController()
    
    // TODO: Uncomment when we have a user object
    var currentUser = UserController.loadFromDefaults()
    
    static var userRef: FIRDatabaseReference {
        return FirebaseController.ref.child("users")
    }
    
    var currentUserId: String {
        guard let currentUser = currentUser, currentUserId = currentUser.identifier else {
            fatalError("Could not retrieve current user id")
        }
        return currentUserId
    }
    
    static func createUser(firstName: String, lastName: String, photoUrl: String, email: String, password: String, completion: (user: User?) -> Void) {
        FIRAuth.auth()?.createUserWithEmail(email, password: password, completion: { (user, error) in
            if let error = error {
                print("There was error while creating user: \(error.localizedDescription)")
                completion(user: nil)
            } else if let firebaseUser = user {
                var user = User(firstName: firstName, lastName: lastName, photoUrl: photoUrl, identifier: firebaseUser.uid)
                user.save()
                UserController.shared.currentUser = user
                UserController.saveUserInDefaults(user)
                completion(user: user)
            } else {
                completion(user: nil)
            }
        })
    }
    
    static func authUser(email: String, password: String, completion: (user: User?) -> Void) {
        FIRAuth.auth()?.signInWithEmail(email, password: password, completion: { (firebaseUser, error) in
            if let error = error {
                print("Wasn't able log user in: \(error.localizedDescription)")
                completion(user: nil)
            } else if let firebaseUser = firebaseUser {
                UserController.fetchUserForIdentifier(firebaseUser.uid, completion: { (user) in
                    guard let user = user else {
                        completion(user: nil)
                        return
                    }
                    UserController.shared.currentUser = user
                    UserController.saveUserInDefaults(user)
                    completion(user: user)
                })
            } else {
                completion(user: nil)
            }
        })
    }
    
    static func fetchUserForIdentifier(identifier: String, completion: (user: User?) -> Void) {
        FirebaseController.ref.child("users").child(identifier).observeSingleEventOfType(.Value, withBlock: { data in
            guard let dataDict = data.value as? [String: AnyObject],
                user = User(dictionary: dataDict, identifier: data.key) else {
                    completion(user: nil)
                    return
            }
            completion(user: user)
        })
    }
    
    static func fetchAllUsers(completion: (users: [User]) -> Void) {
        userRef.observeSingleEventOfType(.Value, withBlock: { (data) in
            guard let userDicts = data.value as? [String: [String: AnyObject]] else {
                completion(users: [])
                return
            }
            let users = userDicts.flatMap { User(dictionary: $1, identifier: $0) }
            completion(users: users)
        })
    }
    
    private static func saveUserInDefaults(user: User) {
        NSUserDefaults.standardUserDefaults().setObject(user.dictionaryCopy, forKey: UserController.currentUserKey)
        NSUserDefaults.standardUserDefaults().setObject(user.identifier!, forKey: currentUserIdKey)
    }
    
    private static func loadFromDefaults() -> User? {
        let defaults = NSUserDefaults.standardUserDefaults()
        guard let userDict = defaults.objectForKey(currentUserKey) as? [String: AnyObject], userId = defaults.objectForKey(currentUserIdKey) as? String, user = User(dictionary: userDict, identifier: userId) else {
            return nil
        }
        return user
    }
}