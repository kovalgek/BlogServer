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
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":userID", use: getHandler)
        usersRoute.get(":userID", "posts", use: getPostsHandler)
        
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
    }

    func createHandler(_ request: Request) throws -> EventLoopFuture<User.Public> {
        let user = try request.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)
        return user.save(on: request.db).map { user.convertToPublic() }
    }

    func getAllHandler(_ request: Request) throws -> EventLoopFuture<[User.Public]> {
        User.query(on: request.db).all().convertToPublic()
    }

    func getHandler(_ request: Request) throws -> EventLoopFuture<User.Public> {
        User.find(request.parameters.get("userID"), on: request.db)
            .unwrap(or: Abort(.notFound))
            .convertToPublic()
    }

    func getPostsHandler(_ request: Request) throws -> EventLoopFuture<[Post]> {
        User.find(request.parameters.get("userID"), on: request.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$posts.get(on: request.db)
            }
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token.Public> {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req.db).map { token.convertToPublic() }
    }
}
