//
//  File.swift
//  
//
//  Created by Developer on 14.07.2023.
//

import Vapor

class UserController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: getUsers)
        users.post(use: createUser)
    }
    
    func getUsers(req: Request) async throws -> [User] {
        let users = try await User.query(on: req.db).all()
        return users
    }
    
    func createUser(req: Request) async throws -> User {
        let user = try req.content.decode(User.self)
        try await user.create(on: req.db)
        return user
    }
}
