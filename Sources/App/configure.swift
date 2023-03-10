import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

public func configure(_ app: Application) throws {

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)

    app.views.use(.leaf)
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreatePost())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreatePostCategoryPivot())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateAdminUser())
    app.migrations.add(TestDataPopulation(dataDirectory: app.directory.resourcesDirectory))

    app.logger.logLevel = .debug

    try app.autoMigrate().wait()

    try routes(app)
}
