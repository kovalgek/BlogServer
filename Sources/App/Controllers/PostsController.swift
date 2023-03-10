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
}

struct PostsController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let postsRoutes = routes.grouped("api", "posts")

        postsRoutes.get(use: getAllHandler)
        postsRoutes.get(":postID", use: getHandler)
        postsRoutes.get("search", use: searchHandler)
        postsRoutes.get("first", use: getFirstHandler)
        postsRoutes.get("sorted", use: sortedHandler)
        postsRoutes.get(":postID", "user", use: getUserHandler)
        postsRoutes.get(":postID", "categories", use: getCategoriesHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = postsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(":postID", "categories", ":categoryID", use: removeCategoriesHandler)
        tokenAuthGroup.put(":postID", use: updateHandler)
        tokenAuthGroup.post(":postID", "categories", ":categoryID", use: addCategoriesHandler)
        tokenAuthGroup.delete(":postID", use: deleteHandler)
    }

    func getAllHandler(_ request: Request) throws -> EventLoopFuture<[Post]> {
        Post.query(on: request.db).all()
    }

    func createHandler(_ request: Request) throws -> EventLoopFuture<Post> {
        let data = try request.content.decode(CreatePostData.self)
        let user = try request.auth.require(User.self)
        let post = try Post(title: data.title, content: data.content, userID: user.requireID())
        return post.save(on: request.db).map { post }
    }

    func getHandler(_ request: Request) throws -> EventLoopFuture<Post> {
        Post.find(request.parameters.get("postID"), on: request.db)
            .unwrap(or: Abort(.notFound))
    }

    func updateHandler(_ request: Request) throws -> EventLoopFuture<Post> {
        let updateData = try request.content.decode(CreatePostData.self)
        let user = try request.auth.require(User.self)
        let userID = try user.requireID()

        return Post.find(request.parameters.get("postID"), on: request.db)
            .unwrap(or: Abort(.notFound)).flatMap { post in
                post.title = updateData.title
                post.content = updateData.content
                post.$user.id = userID
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

    func getUserHandler(_ request: Request) throws -> EventLoopFuture<User.Public> {
        Post.find(request.parameters.get("postID"), on: request.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { post in
                post.$user.get(on: request.db).convertToPublic()
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
