//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/12/2021.
//

import Vapor

struct UsersController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        usersRoute.post(use: createHandler)
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":userID", use: getHandler)
        usersRoute.get(":userID", "posts", use: getPostsHandler)
    }

    func createHandler(_ request: Request) throws -> EventLoopFuture<User> {
        let user = try request.content.decode(User.self)
        return user.save(on: request.db).map { user }
    }

    func getAllHandler(_ request: Request) throws -> EventLoopFuture<[User]> {
        User.query(on: request.db).all()
    }

    func getHandler(_ request: Request) throws -> EventLoopFuture<User> {
        User.find(request.parameters.get("userID"), on: request.db)
            .unwrap(or: Abort(.notFound))
    }

    func getPostsHandler(_ request: Request) throws -> EventLoopFuture<[Post]> {
        User.find(request.parameters.get("userID"), on: request.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$posts.get(on: request.db)
            }
    }
}
