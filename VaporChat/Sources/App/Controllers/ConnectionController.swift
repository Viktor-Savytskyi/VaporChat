//
//  File.swift
//  
//
//  Created by Developer on 19.07.2023.
//

import Vapor
import Fluent

class ConnectionController {
    
    var app: Application
    var roomController: RoomController?
    var messageController: MessageController?
    var userController: UserController?
    let userID = "userID"
    let oponentID = "oponentID"
    var isNewRoom = false
    var connections = [String : WebSocket?]() {
        didSet {
            roomController?.connections = connections
        }
    }
    
    init(app: Application) {
        self.app = app
    }
    
    func addUser(userID: String, ws: WebSocket?) {
        connections[userID] = ws
        print("Users CONNECTIONS: \(connections)")
    }
     
    func connect() {
        var firstPing = true

        app.webSocket("chat") { req, ws in
            guard let userID = try? req.query.get(String.self, at: self.userID) else { return }
            self.addUser(userID: userID, ws: ws)
            
            ws.onClose.whenComplete { _ in
                print("webSocket closed")
                self.connections[userID] = nil
                firstPing = true
                //here add logic to set offline status for user
            }
            
            ws.onPing { ws, byte in
                
//                if firstPing {
                    await self.roomController?.sendRoomsWithAllMessages(ws: ws, req: req, userID: userID)
//                    await self.sendRoomMessagesHistory(ws: ws, req: req, userID: userID)
//                    await self.userController?.updateUserOfflineStatus(db: self.app.db, id: userID, isOnline: true)
//                    self.firstPing = false
//                } else {
//                    self.checkIsUserOnline()
//                }
            }
            
             ws.onBinary { ws, data in
                 do {
                     let userMessage = try JSONDecoder().decode(UserMessage.self, from: data)
                     await self.roomController?.createOrFindUserRoom(ws: ws, userID: userMessage.senderID, oponentID: userMessage.receiverID) { newRoom in
                         self.isNewRoom = newRoom
                     }
                     await self.roomController?.saveMessage(userMessage: userMessage) {
                         userMessage.room?.id = self.roomController?.usersRoom.id
                     }
                     do {
                         try await self.roomController?.usersRoom?.$messages.create(userMessage, on: req.db)
                     } catch {
                         print(error.localizedDescription)
                     }
                     
                     
                     await self.roomController?.sendData(userMessage: userMessage, isNewRoom: self.isNewRoom)
                     self.isNewRoom = false
                 } catch {
                     print(error.localizedDescription)
                 }
            }
        }
    }
}
