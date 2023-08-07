//
//  File.swift
//  
//
//  Created by Developer on 19.07.2023.
//

import Vapor
import Fluent

class RoomController {
    var rooms: [Room]?
    var usersRoom: Room!
    var db: Database
    var connections: [String : WebSocket?]?
    var isNewRoom = false
    
    init(db: Database) {
        self.db = db
    }
    
    // send filtered by usersIDs rooms at first loading
    func sendRoomsWithAllMessages(ws: WebSocket, req: Request, userID: String) async {
        let filteredRooms = try? await Room.query(on: req.db).with(\.$messages).all().filter({ $0.users.contains(userID) && !$0.messages.isEmpty })
        let decodedRooms = try! JSONEncoder().encode(filteredRooms)
        do {
            try await ws.send(raw: decodedRooms, opcode: .binary)
        } catch {
            print("RoomController error:", error.localizedDescription)
        }
    }
    
    func saveMessageIntoRoom(userMessage: UserMessage) async throws {
        userMessage.room?.id = self.usersRoom.id
        do {
            try await usersRoom?.$messages.create(userMessage, on: db)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func sendRoomsDataForUsers(filteredRooms: [Room]) {
        connections?.forEach{ (user, webSocket) in
            if user == usersRoom.users.first || user == usersRoom.users.last {
                do {
                    let decodedRooms = try JSONEncoder().encode(filteredRooms)
                    webSocket?.send(raw: decodedRooms, opcode: .binary)
                    print(usersRoom as Any)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    
    //check is existing room, create new Room if need -- set result to var usersRoom: Room!
    func getUsersRoom(ws: WebSocket,
                      userID: String,
                      oponentID: String) async {
        if let currentRoom = await findCurrentRoom(userID: userID, oponentID: oponentID) {
            //if room existing
            usersRoom = currentRoom
        } else {
            //create new room for users and save it to DB
            usersRoom = Room(users: [userID, oponentID])
            do {
                try await usersRoom.save(on: db)
                isNewRoom = true
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func findCurrentRoom(userID: String, oponentID: String) async -> Room? {
        try? await Room.query(on: db).all().first(where: { room in
            if userID != oponentID {
                return room.users.contains(userID) && room.users.contains(oponentID)
            } else {
                // check is room twice containe userID (is it owner`s self chat)
                return room.users.filter { $0 == userID }.count == 2
            }
        })
    }
    
    func sendData(userMessage: UserMessage) async {
        guard let data = await convertObjectIntoData(userMessage: userMessage, isNewRoom: isNewRoom) else { return }
        connections?.forEach({ (user, webSocket) in
            if user == userMessage.senderID || user == userMessage.receiverID {
                webSocket?.send(raw: data, opcode: .binary)
                print(userMessage)
                self.isNewRoom = false
            }
        })
    }
    
    // convert incoming data into JSON
    func convertObjectIntoData(userMessage: UserMessage, isNewRoom: Bool) async -> Data? {
        if isNewRoom {
            //create dialoge room with new user
            let filteredRoom = try? await Room.query(on: self.db).with(\.$messages).all().first(where: { $0.id == self.usersRoom.id })
            let decodedRoom = try? JSONEncoder().encode(filteredRoom)
            return decodedRoom
        } else {
            // create message
            return try? userMessage.convertToJsonData()
        }
    }
    
    // MARK: -  Room requessts
    
    func getAllRooms(req: Request) async throws -> [Room] {
        let param = "id"
        guard let rooms = try? await Room.query(on: req.db).with(\.$messages).all() else { throw Abort(.badRequest) }
        if let reqParam = try? req.query.get(String.self, at: param) {
            return rooms.filter({ $0.users.contains(reqParam) })
        }
        return rooms
    }
    
    func deleteAllRooms(req: Request) async throws -> [Room] {
        try await Room.query(on: req.db).with(\.$messages).delete()
        return [Room]()
    }
}
