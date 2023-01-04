//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/12/2021.
//

import Vapor
import Fluent

final class Post: Model {

    static let schema = "posts"

    @ID
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "content")
    var content: String

    @Parent(key: "userID")
    var user: User

    @Siblings(through: PostCategoryPivot.self, from: \.$post, to: \.$category)
    var categories: [Category]

    init() {}

    init(id: UUID? = nil, title: String, content: String, userID: User.IDValue) {
      self.id = id
      self.title = title
      self.content = content
      self.$user.id = userID
    }
}

extension Post: Content {}
