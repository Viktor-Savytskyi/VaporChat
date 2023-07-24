//
//  File.swift
//  
//
//  Created by Developer on 19.07.2023.
//

import Vapor
import Fluent

class RoomController {
    
    var db: Database
     var connections = [String : WebSocket?]()

    init(db: Database) {
        self.db = db
    }
    
    func addUser(userID: String, ws: WebSocket?) {
            connections[userID] = ws
        print("Users CONNECTIONS: \(connections)")
    }
    
    func saveAndSendMessage(userMessage: UserMessage) {
        db.withConnection {
            userMessage.save(on: $0)
        }.whenComplete {  res in
            switch res {
            case .failure(_):
                print("Something went wrong save message.")
            case .success:
            print("message saved")
                self.sendData(userMessage: userMessage)
            }
        }
    }
    
    func sendData(userMessage: UserMessage) {
        print("ALL Users CONNECTIONS: \(connections)")
        connections.forEach({ (user, webSocket) in
            if user == userMessage.senderID || user == userMessage.receiverID {
                print("Send message to \(user)")
                do {
                    let data = try userMessage.convertToJsonData()
                    webSocket?.send(raw: data, opcode: .binary)
                    print(userMessage)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        })
    }
    
    static func getAllRooms(req: Request) async throws -> [Room] {
        let rooms = try await Room.query(on: req.db).all()
        return rooms
    }
    
    static func deleteAllRooms(req: Request) async throws -> [Room] {
        try await Room.query(on: req.db).delete()
        return [Room]()
    }
}
