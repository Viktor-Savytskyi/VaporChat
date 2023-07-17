import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.databases.use(.postgres(
        hostname: "localhost",
        port: 5432,
        username: "a12345",
        password: "",
        database: "postgres"
    ), as: .psql)

    app.migrations.add(CreateUser())
    try await app.autoMigrate()
    app.logger.logLevel = .debug

    // register routes
    try routes(app)
}
