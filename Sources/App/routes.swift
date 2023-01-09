import Fluent
import Vapor

func routes(_ app: Application) throws {

    let postsController = PostsController()
    try app.register(collection: postsController)

    let usersController = UsersController()
    try app.register(collection: usersController)

    let categoriesController = CategoriesController()
    try app.register(collection: categoriesController)
    
    let websiteController = WebsiteController()
    try app.register(collection: websiteController)
}
