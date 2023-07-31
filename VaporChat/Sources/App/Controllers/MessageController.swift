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
    var firstPing = true
    
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
                
                if self.firstPing {
                    await self.sendRoomMessagesHistory(ws: ws, req: req, userID: userID, oponentID: oponentID)
//                    self.firstPing = false
                } else {
                    self.checkIsUserOnline()
                }
            }
            
             ws.onBinary { ws, data in
                 do {
                     try JSONDecoder().decode(UserMessage.self, from: data)
                 } catch {
                     print(error)
                 }
                 guard let userMessage = try? JSONDecoder().decode(UserMessage.self, from: data),
                       let roomID = self.roomController?.usersRoom?.id else { return }
                 userMessage.room?.id = roomID
                 await self.roomController?.saveAndSendMessage(userMessage: userMessage)
            }
        }
    }
    
    func checkIsUserOnline() {
        
    }
    
    func sendRoomMessagesHistory(ws: WebSocket, req: Request, userID: String, oponentID: String) async {
        await createOrFindUserRoom(ws: ws, req: req, userID: userID, oponentID: oponentID)
        await sendRoomMessages(ws: ws, req: req)
    }
    
    func createOrFindUserRoom(ws: WebSocket, req: Request, userID: String, oponentID: String) async {
        if let rooms = try? await Room.query(on: req.db).all(),
           let room = rooms.first(where: { room in
               if userID != oponentID {
                  return room.users.contains(userID) && room.users.contains(oponentID)
               } else {
                   // check is room twice containe userID (is it owner`s self chat)
                   return room.users.filter { $0 == userID }.count == 2
               }
           }) {
            //if room existing
            roomController?.usersRoom = room
        } else {
            //create new room for users
            roomController?.usersRoom = Room(users: [userID, oponentID])
            try? await self.app.db.withConnection { self.roomController?.usersRoom?.save(on: $0) }
        }
        
       roomController?.usersRoom?.users.forEach({ user in
            if user == userID {
                self.roomController?.addUser(userID: userID, ws: ws)
            }
        })
    }
    
    
    func sendRoomMessages(ws: WebSocket, req: Request) async {
        guard let messages = try? await UserMessage.query(on: req.db).with(\.$room).all().filter({ message in          
            return message.room?.id == roomController?.usersRoom?.id
        }) else { return }
        let decodedMessages = try! JSONEncoder().encode(messages)
        try? await ws.send(raw: decodedMessages, opcode: .binary)
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
