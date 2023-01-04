//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/12/2021.
//

import Fluent

struct CreatePost: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("posts")
            .id()
            .field("title", .string, .required)
            .field("content", .string, .required)
            .field("userID", .uuid, .required, .references("users", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("posts").delete()
    }
}
