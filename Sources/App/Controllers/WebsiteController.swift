//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 07/01/2023.
//

import Foundation

import Vapor
import Leaf

struct IndexContext: Encodable {
    let title: String
    let posts: [Post]?
}

struct PostContext: Encodable {
    let title: String
    let post: Post
    let user: User
}

struct WebsiteController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
        routes.get("posts", ":postID", use: postHandler)
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        Post.query(on: req.db).all().flatMap { posts in
            let postsData = posts.isEmpty ? nil : posts
            let context = IndexContext(title: "Home page", posts: postsData)
            return req.view.render("index", context)
        }
    }
    
    func postHandler(_ req: Request) -> EventLoopFuture<View> {
        Post.find(req.parameters.get("postID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { post in
            post.$user.get(on: req.db).flatMap { user in
                let context = PostContext(title: post.title, post: post, user: user)
                return req.view.render("post", context)
            }
        }
    }
}

