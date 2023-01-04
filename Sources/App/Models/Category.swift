//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/12/2021.
//

import Fluent
import Vapor

final class Category: Model, Content {

    static let schema = "categories"

    @ID
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Siblings(through: PostCategoryPivot.self, from: \.$category, to: \.$post)
    var posts: [Post]

    init() {}

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
