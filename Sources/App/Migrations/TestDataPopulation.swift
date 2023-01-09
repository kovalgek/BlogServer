//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/01/2023.
//

import Fluent
import Foundation
import Vapor

struct TestDataPopulation: Migration {
    
    var dataDirectory: String = ""
    
    func data(for file: String) -> [String : AnyObject] {
  
        let url = URL(fileURLWithPath: dataDirectory, isDirectory: true).appendingPathComponent(file)
        
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String:AnyObject] else {
            return [:]
        }

        return plist
    }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
                
        var futures: [EventLoopFuture<Void>] = []
        let passwords = ["123456", "password", "111111", "qwerty", "abc123", "iloveyou", "password1"]

        var userIDs = Set<UUID>()
        let userPlist = (data(for: "users.plist")["data"] as! NSArray) as Array
        userPlist.forEach {
            let userID = UUID()
            userIDs.insert(userID)
            let encryptedPassword = try! Bcrypt.hash(passwords.randomElement()!)
            let user = User(id: userID, name: $0["name"] as! String, username: $0["username"] as! String, password: encryptedPassword)
            futures.append(user.create(on: database))
        }
        
        var categories: [Category] = []
        let categoryPlist = (data(for: "categories.plist")["data"] as! NSArray) as Array
        categoryPlist.forEach {
            let category = Category(name: $0 as! String)
            categories.append(category)
            futures.append(category.create(on: database))
        }
        
        var posts: [Post] = []
        let postPlist = (data(for: "posts.plist")["data"] as! NSArray) as Array
        postPlist.forEach {
            let userID = userIDs.randomElement() ?? UUID()
            let post = Post(title: $0["title"] as! String, content: $0["content"] as! String, userID: userID)
            posts.append(post)
            futures.append(post.create(on: database))
        }
        
        return EventLoopFuture<Void>.andAllSucceed(futures, on: database.eventLoop).flatMap {
            let addCategoryToPostFutures = posts.map {
                $0.$categories.attach(categories.randomElement()!, on: database)
            }
            return EventLoopFuture<Void>.andAllSucceed(addCategoryToPostFutures, on: database.eventLoop)
        }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        
        let formNames = [
            "powder",
            "seed",
            "whole",
            "granules"
        ]
       
        let futures = formNames.map { name in
            return User.query(on: database).delete()
        }
        return EventLoopFuture<Void>.andAllSucceed(futures, on: database.eventLoop)
    }
}
