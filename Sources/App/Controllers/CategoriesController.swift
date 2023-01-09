//
//  File.swift
//  
//
//  Created by Anton Kovalchuk on 04/12/2021.
//

import Vapor

struct CategoriesController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let categoriesRoute = routes.grouped("api", "categories")
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.get(":categoryID", use: getHandler)
        categoriesRoute.get(":categoryID", "posts", use: getPostsHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = categoriesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
    }

    func createHandler(_ request: Request) throws -> EventLoopFuture<Category> {
        let category = try request.content.decode(Category.self)
        return category.save(on: request.db).map { category }
    }

    func getAllHandler(_ request: Request) throws -> EventLoopFuture<[Category]> {
        Category.query(on: request.db).all()
    }

    func getHandler(_ request: Request) throws -> EventLoopFuture<Category> {
        Category.find(request.parameters.get("categoryID"), on: request.db).unwrap(or: Abort(.notFound))
    }

    func getPostsHandler(_ request: Request) throws -> EventLoopFuture<[Post]> {
        Category.find(request.parameters.get("categoryID"), on: request.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$posts.get(on: request.db)
            }
    }
}
