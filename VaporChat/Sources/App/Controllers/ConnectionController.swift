//
//  File.swift
//  
//
//  Created by Developer on 19.07.2023.
//

import Vapor
import Fluent

enum StringFields: String {
    case userID
    case oponentID
    case chat
}

class ConnectionController {
    
    var app: Application
    var roomController: RoomController?
    var messageController: MessageController?
    var userController: UserController?
    var isFirstPing = false
    var connections = [String : WebSocket?]() {
        didSet {
            roomController?.connections = connections
            userController?.connections = connections
            messageController?.connections = connections
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
        app.webSocket(PathComponent(stringLiteral: StringFields.chat.rawValue)) { req, ws in
            guard let userID = try? req.query.get(String.self,
                                                  at: StringFields.userID.rawValue) else { return }
            self.addUser(userID: userID, ws: ws)
            self.isFirstPing = true
            
            ws.onClose.whenComplete { _ in
                print("webSocket closed")
                self.connections[userID] = nil
                self.userController?.updateUserOfflineStatus(req: req,
                                                             id: userID,
                                                             isOnline: false)
            }
            
            ws.onPing { ws, byte in
                if self.isFirstPing {
                    
                    await self.roomController?.sendRoomsWithAllMessages(ws: ws,
                                                                        req: req,
                                                                        userID: userID)
                    self.userController?.updateUserOfflineStatus(req: req,
                                                                 id: userID,
                                                                 isOnline: true)
                    self.isFirstPing = false
                }
            }
            
            ws.onText { ws, text in
                self.messageController?.sendMessage(text: text)
            }
            
            ws.onBinary { ws, data in
                do {
                    let userMessage = try JSONDecoder().decode(UserMessage.self,
                                                               from: data)
                    //create or find room of users
                    await self.roomController?.getUsersRoom(ws: ws,
                                                            userID: userMessage.senderID,
                                                            oponentID: userMessage.receiverID)
                    //save created message to DB
                    await self.messageController?.saveMessage(userMessage: userMessage,
                                                              db: req.db)
                    
                    //set to created message parent RoomID and save message to array of Room messages
                    try await self.roomController?.saveMessageIntoRoom(userMessage: userMessage)
                    
                    await self.roomController?.sendData(userMessage: userMessage)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

