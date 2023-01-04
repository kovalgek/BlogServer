//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/12/2021.
//

import Fluent
import Vapor

final class PostCategoryPivot: Model {

    static let schema = "post-category-pivot"

    @ID
    var id: UUID?

    @Parent(key: "postID")
    var post: Post

    @Parent(key: "categoryID")
    var category: Category

    init() {}

    init(id: UUID? = nil, post: Post, category: Category) throws {
        self.id = id
        self.$post.id = try post.requireID()
        self.$category.id = try category.requireID()
    }
}
