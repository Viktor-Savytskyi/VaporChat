//
//  File.swift
//  
//
//  Created by Developer on 19.07.2023.
//

import Vapor
import Fluent

class RoomController {
    
    var usersRoom: Room?
    var db: Database
    var connections: [String : WebSocket?]?

    init(db: Database) {
        self.db = db
    }
    
    func createOrFindUserRoom(ws: WebSocket, req: Request, userID: String, oponentID: String, completion: (() -> Void)) async {
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
            usersRoom = room
        } else {
            //create new room for users and save it to DB
            usersRoom = Room(users: [userID, oponentID])
            try? await db.withConnection { self.usersRoom?.save(on: $0) }
        }
        
       completion()
    }
    
    func saveAndSendMessage(userMessage: UserMessage) async {
        do {
            try await usersRoom?.$messages.create(userMessage, on: db)
        } catch {
            print(error)
        }
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
        print("ALL ROOM Users CONNECTIONS: \(connections)")
        connections?.forEach({ (user, webSocket) in
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
        let param = "id"
        guard let rooms = try? await Room.query(on: req.db).with(\.$messages).all() else { throw Abort(.badRequest) }
        if let reqParam = try? req.query.get(String.self, at: param) {
            return rooms.filter({ $0.users.contains(reqParam) }).sorted { room1, room2 in
                let lastMessageDate1 = room1.messages.last?.createdAt ?? Date.distantPast
                let lastMessageDate2 = room2.messages.last?.createdAt ?? Date.distantPast
                return lastMessageDate1 > lastMessageDate2
            }
        } 
        return rooms
    }
    
    static func deleteAllRooms(req: Request) async throws -> [Room] {
        try await Room.query(on: req.db).with(\.$messages).delete()
        return [Room]()
    }
}
