//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 08/01/2023.
//

import Vapor
import Fluent

final class Token: Model, Content {
    static let schema = "tokens"
    
    @ID
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "userID")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
    
    final class Public: Content {
        var id: UUID?
        var value: String
        var userID: String
        
        init(id: UUID?, value: String, userID: String) {
            self.id = id
            self.value = value
            self.userID = userID
        }
    }
}

extension Token {
    func convertToPublic() -> Token.Public {
        Token.Public(id: id, value: value, userID: self.$user.id.uuidString)
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = [UInt8].random(count: 16).base64
        return try Token(value: random, userID: user.requireID())
    }
}

extension Token: ModelTokenAuthenticatable {
    static let valueKey = \Token.$value
    static let userKey = \Token.$user
    typealias User = App.User
    var isValid: Bool {
        true
    }
}
