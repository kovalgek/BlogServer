//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/12/2021.
//

import Fluent
import Vapor

final class User: Model, Content {
    
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    @Children(for: \.$user)
    var posts: [Post]
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, password: String) {
        self.id = id
        self.name = name
        self.username = username
        self.password = password
    }
    
    final class Public: Content {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        User.Public(id: id, name: name, username: username)
    }
}

extension EventLoopFuture where Value: User {
    func convertToPublic() -> EventLoopFuture<User.Public> {
        self.map { user in
            user.convertToPublic()
        }
    }
}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        self.map { $0.convertToPublic() }
    }
}

extension EventLoopFuture where Value == Array<User> {
    func convertToPublic() -> EventLoopFuture<[User.Public]> {
        self.map { $0.convertToPublic() }
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
