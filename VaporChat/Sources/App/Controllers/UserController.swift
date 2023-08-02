//
//  File.swift
//  
//
//  Created by Developer on 14.07.2023.
//

import Vapor
import Fluent

class UserController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: getUsers)
        users.post(use: createUser)
        users.delete(use: deleteAllUsers)
    }
    
    func getUsers(req: Request) async throws -> [User] {
        let param = "id"
        let users = try await User.query(on: req.db).all()
        if let reqParam = try? req.query.get(String.self, at: param) {
            guard let user = try await User.query(on: req.db).filter(\.$id == UUID(uuidString: reqParam)!).first() else { throw Abort(.badRequest) }
            return [user]
        }
        return users
    }
    
    func createUser(req: Request) async throws -> User {
        let user = try req.content.decode(User.self)
        try await user.create(on: req.db)
        return user
    }
    
    func updateUserOfflineStatus(db: Database, id: String?, isOnline: Bool) async {
        let onlineStatus = isOnline ? nil : Date()
        let user = try? await User.query(on: db).all().first(where: { $0.id?.uuidString == id })
        user?.lastOnlineDate = onlineStatus
        try? await user?.update(on: db)
    }
    
    
    func deleteAllUsers(req: Request) async throws -> [User] {
        try await User.query(on: req.db).delete()
        return [User]()
    }
}
