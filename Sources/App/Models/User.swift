//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/12/2021.
//

import Fluent
import Vapor

final class User: Model {
    
    static let schema = "users"

    @ID
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "username")
    var username: String

    @Children(for: \.$user)
    var posts: [Post]

    init() {}

    init(id: UUID? = nil, name: String, username: String) {
      self.id = id
      self.name = name
      self.username = username
    }
}

extension User: Content {}
