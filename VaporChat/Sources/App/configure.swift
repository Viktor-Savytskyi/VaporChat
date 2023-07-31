import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.databases.use(.postgres(
        hostname: "127.0.0.1",
        port: 5432,
        username: "a12345",
        password: "",
        database: "postgres"
    ), as: .psql)

    
    app.migrations.add(CreateChatRoomsMigration5())
    app.migrations.add(CreateMessageMigration5())
//    app.migrations.add(CreateUser1())
    try await app.autoMigrate()
    
    app.logger.logLevel = .debug

    // register routes
    try routes(app)
}
