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
    var firstPing = true
    let userID = "userID"
    let oponentID = "oponentID"
    var connections = [String : WebSocket?]() {
        didSet {
            roomController?.connections = connections
        }
    }

    
    init(app: Application) {
        self.app = app
        self.roomController = RoomController(db: app.db)
        self.messageController = MessageController()
        self.userController = UserController()
    }
    
    func addUser(userID: String, ws: WebSocket?) {
        connections[userID] = ws
        print("Users CONNECTIONS: \(connections)")
    }
     
    func connect() {
        app.webSocket("chat") { req, ws in
            guard let userID = try? req.query.get(String.self, at: self.userID),
                  let oponentID = try? req.query.get(String.self, at: self.oponentID) else { return }
            
            ws.onClose.whenComplete { _ in
                print("webSocket closed")
                self.connections[userID] = nil
                //here add logic to set offline status for user
            }
            
            
            await self.sendRoomMessagesHistory(ws: ws, req: req, userID: userID, oponentID: oponentID)
            
            ws.onPing { ws, byte in
                
                if self.firstPing {
                    await self.sendRoomMessagesHistory(ws: ws, req: req, userID: userID, oponentID: oponentID)
                    await self.userController?.updateUserOfflineStatus(db: self.app.db, id: userID, isOnline: true)
                    self.firstPing = false
                } else {
//                    self.checkIsUserOnline()
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
    
    func sendRoomMessagesHistory(ws: WebSocket, req: Request, userID: String, oponentID: String) async {
        await roomController?.createOrFindUserRoom(ws: ws, req: req, userID: userID, oponentID: oponentID, completion: {
            roomController?.usersRoom?.users.forEach({ user in
                 if user == userID {
                     addUser(userID: userID, ws: ws)
                 }
             })
        })
        await messageController?.sendRoomMessages(ws: ws, req: req, roomID: roomController?.usersRoom?.id)
    }
}
