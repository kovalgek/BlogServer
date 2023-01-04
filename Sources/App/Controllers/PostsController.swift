//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/12/2021.
//

import Vapor
import Fluent

struct CreatePostData: Content {
    let title: String
    let content: String
    let userID: UUID
}

struct PostsController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let postsRoutes = routes.grouped("api", "posts")

        postsRoutes.get(use: getAllHandler)
        postsRoutes.post(use: createHandler)
        postsRoutes.get(":postID", use: getHandler)
        postsRoutes.put(":postID", use: updateHandler)
        postsRoutes.delete(":postID", use: deleteHandler)
        postsRoutes.get("search", use: searchHandler)
        postsRoutes.get("first", use: getFirstHandler)
        postsRoutes.get("sorted", use: sortedHandler)

        postsRoutes.get(":postID", "user", use: getUserHandler)
        postsRoutes.post(":postID", "categories", ":categoryID", use: addCategoriesHandler)
        postsRoutes.get(":postID", "categories", use: getCategoriesHandler)
        postsRoutes.delete(":postID", "categories", ":categoryID", use: removeCategoriesHandler)
    }

    func getAllHandler(_ request: Request) throws -> EventLoopFuture<[Post]> {
        Post.query(on: request.db).all()
    }

    func createHandler(_ request: Request) throws -> EventLoopFuture<Post> {
        let data = try request.content.decode(CreatePostData.self)
        let post = Post(title: data.title, content: data.content, userID: data.userID)
        return post.save(on: request.db).map { post }
    }

    func getHandler(_ request: Request) throws -> EventLoopFuture<Post> {
        Post.find(request.parameters.get("postID"), on: request.db)
            .unwrap(or: Abort(.notFound))
    }

    func updateHandler(_ request: Request) throws -> EventLoopFuture<Post> {
        let updateData = try request.content.decode(CreatePostData.self)
        return Post.find(request.parameters.get("postID"), on: request.db)
            .unwrap(or: Abort(.notFound)).flatMap { post in
                post.title = updateData.title
                post.content = updateData.content
                post.$user.id = updateData.userID
                return post.save(on: request.db).map {
                    post
                }
            }
    }

    func deleteHandler(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
        Post.find(request.parameters.get("postID"), on: request.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { post in
                post.delete(on: request.db)
                    .transform(to: .noContent)
            }
    }

    func searchHandler(_ request: Request) throws -> EventLoopFuture<[Post]> {
        guard let searchTerm = request
                .query[String.self, at: "term"] else {
                    throw Abort(.badRequest)
                }
        return Post.query(on: request.db).group(.or) { or in
            or.filter(\.$title == searchTerm)
            or.filter(\.$content == searchTerm)
        }.all()
    }

    func getFirstHandler(_ request: Request) throws -> EventLoopFuture<Post> {
        return Post.query(on: request.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }

    func sortedHandler(_ request: Request) throws -> EventLoopFuture<[Post]> {
        return Post.query(on: request.db).sort(\.$title, .ascending).all()
    }

    func getUserHandler(_ request: Request) throws -> EventLoopFuture<User> {
        Post.find(request.parameters.get("postID"), on: request.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { post in
                post.$user.get(on: request.db)
            }
    }

    func addCategoriesHandler(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
        let postQuery = Post.find(request.parameters.get("postID"), on: request.db).unwrap(or: Abort(.notFound))
        let categoryQuery = Category.find(request.parameters.get("categoryID"), on: request.db).unwrap(or: Abort(.notFound))
        return postQuery.and(categoryQuery).flatMap { post, category in
            post.$categories.attach(category, on: request.db).transform(to: .created)
        }
    }

    func getCategoriesHandler(_ request: Request) throws -> EventLoopFuture<[Category]> {
        Post.find(request.parameters.get("postID"), on: request.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { post in
                post.$categories.query(on: request.db).all()
            }
    }

    func removeCategoriesHandler(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
        let postQuery = Post.find(request.parameters.get("postID"), on: request.db).unwrap(or: Abort(.notFound))
        let categoryQuery = Category.find(request.parameters.get("categoryID"), on: request.db).unwrap(or: Abort(.notFound))
        return postQuery.and(categoryQuery).flatMap { post, category in
            post.$categories.detach(category, on: request.db).transform(to: .noContent)
        }
    }
}
