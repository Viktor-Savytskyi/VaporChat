//
//  File.swift
//  
//
//  Created by Developer on 01.08.2023.
//

import Vapor
import Fluent

class MessageController {
    
    func sendRoomMessages(ws: WebSocket, req: Request, roomID: UUID?) async {
        guard let messages = try? await UserMessage.query(on: req.db).with(\.$room).all().filter({ message in
            return message.room?.id == roomID
        }).sorted(by: { $0.createdAt ?? Date() < $1.createdAt ?? Date()}) else { return }

        let decodedMessages = try! JSONEncoder().encode(messages)
        do {
            try await ws.send(raw: decodedMessages, opcode: .binary)
        } catch {
            print("Error is", error.localizedDescription)
        }

    }
    func createUserMessage(req: Request) async throws -> UserMessage {
        let userMessage = try req.content.decode(UserMessage.self)
        try await userMessage.create(on: req.db)
        return userMessage
    }
    
    func getAllMessages(req: Request) async throws -> [UserMessage] {
        let usersMessages = try await UserMessage.query(on: req.db).all().sorted(by: { $0.createdAt ?? Date() > $1.createdAt ?? Date()})
        return usersMessages
    }
    
    func deleteAllMessages(req: Request) async throws -> [UserMessage] {
        try await UserMessage.query(on: req.db).delete()
        return [UserMessage]()
    }
}
