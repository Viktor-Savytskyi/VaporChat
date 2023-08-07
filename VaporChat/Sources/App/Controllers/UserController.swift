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
    
    var connections: [String : WebSocket?]?
    
    func updateUserOfflineStatus(req: Request, id: String?, isOnline: Bool) {
        guard let stringID = id, let id = UUID(uuidString: stringID) else { return }
        Task {
            do {
                let users = try await User.query(on: req.db).all()
                let user = users.first(where: { user in user.id == id })
                user?.lastOnlineDate = isOnline ? nil : Date()
                _ = try await user?.save(on: req.db)
                guard let connections else { return }
                let onlineUsers = createOnlineUsersStringArray(from: users)
                connections.forEach({ key, ws in
                    ws?.send(onlineUsers)
                })
            } catch {
                print("Error saving last online date: \(error)")
            }
        }
    }
    
    func createOnlineUsersStringArray(from users: [User]) -> String {
        users.map {
            guard let id = $0.id?.uuidString,
                  let date = $0.lastOnlineDate else { return "" }
            return "\(id)" + " : " + "\(date)" }.joined(separator: "\n")
    }
    
    //MARK: - Users requests
    
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
    
    func deleteAllUsers(req: Request) async throws -> [User] {
        try await User.query(on: req.db).delete()
        return [User]()
    }
}

