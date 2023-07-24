//
//  File.swift
//  
//
//  Created by Developer on 19.07.2023.
//

import Vapor
import Fluent

class MessageController {
    
    var app: Application
    var roomController: RoomController?
    var usersRoom: Room?
    
    init(app: Application) {
        self.app = app
        self.roomController = RoomController(db: app.db)
    }
     
    func connect() {
        app.webSocket("chat") { req, ws in
            let userID = "userID"
            let oponentID = "oponentID"
            guard let userID = try? req.query.get(String.self, at: userID),
                  let oponentID = try? req.query.get(String.self, at: oponentID) else { return }
            
            
            ws.onClose.whenComplete { _ in
                print("webSocket closed")
                self.roomController?.connections[userID] = nil
            }
            
            ws.onPing { ws, byte in
                if let rooms = try? await Room.query(on: req.db).all(),
                   let room = rooms.first(where: { room in
                       if userID != oponentID {
                          return room.users.contains(userID) && room.users.contains(oponentID)
                       } else {
                           return room.users.filter { user in
                                user == userID
                           }.count == 2
                       }
                   }) {
                    self.usersRoom = room
                } else {
                    self.usersRoom = Room(users: [userID, oponentID])
                    try? await self.app.db.withConnection { self.usersRoom?.save(on: $0) }
                }
                
                self.usersRoom?.users.forEach({ user in
                    if user == userID {
                        self.roomController?.addUser(userID: userID, ws: ws)
                    }
                })
                
                guard let messages = try? await UserMessage.query(on: req.db).all().filter({ message in
                    message.roomID == self.usersRoom?.id?.uuidString
                }) else { return }
                let decodedMessages = try! JSONEncoder().encode(messages)
                try? await ws.send(raw: decodedMessages, opcode: .binary)
            }
            
             ws.onBinary { ws, data in
                 guard let userMessage = try? JSONDecoder().decode(UserMessage.self, from: data),
                       let roomID = self.usersRoom?.id?.uuidString else { return }
                 userMessage.roomID = roomID                 
                 self.roomController?.saveAndSendMessage(userMessage: userMessage)
            }
        }
    }
    
    func createUserMessage(req: Request) async throws -> UserMessage {
        let userMessage = try req.content.decode(UserMessage.self)
        try await userMessage.create(on: req.db)
        return userMessage
    }
    
    func getAllMessages(req: Request) async throws -> [UserMessage] {
        let usersMessages = try await UserMessage.query(on: req.db).all()
        return usersMessages
    }
    
    func deleteAllMessages(req: Request) async throws -> [UserMessage] {
        try await UserMessage.query(on: req.db).delete()
        return [UserMessage]()
    }
}
