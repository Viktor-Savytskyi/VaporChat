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
    
    init(db: Database) {
        self.db = db
    }
    
    func sendRoomsWithAllMessages(ws: WebSocket, req: Request, userID: String) async {
        let filteredRooms = try? await Room.query(on: req.db).with(\.$messages).all().filter({ $0.users.contains(userID) && $0.messages.count > 0 })
        let decodedRooms = try! JSONEncoder().encode(filteredRooms)
        do {
            try await ws.send(raw: decodedRooms, opcode: .binary)
        } catch {
            print("Error is", error.localizedDescription)
        }
    }
    
//    func saveAndSendRoomData(userMessage: UserMessage) async {
//        guard let filteredRooms = try? await Room.query(on: db).with(\.$messages).all().filter({ $0.users.contains(userMessage.senderID) || $0.users.contains(userMessage.receiverID) }) else { return }
//        do {
//            //            try await usersRoom.update(on: db)
//            try await usersRoom?.$messages.create(userMessage, on: db)
//        } catch {
//            print(error)
//        }
//        db.withConnection {
//            userMessage.save(on: $0)
//        }.whenComplete {  res in
//            switch res {
//            case .failure(_):
//                print("Something went wrong save message.")
//            case .success:
//                print("message saved")
//
//                self.sendRoomData(filteredRooms: filteredRooms)
//            }
//        }
//    }
    
    func sendRoomData(filteredRooms: [Room]) {
        print("ALL ROOM Users CONNECTIONS: \(connections)")
        connections?.forEach{ (user, webSocket) in
            if user == usersRoom.users.first || user == usersRoom.users.last {
                do {
                    let decodedRooms = try JSONEncoder().encode(filteredRooms)
                    webSocket?.send(raw: decodedRooms, opcode: .binary)
                    print(usersRoom)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
            
            //            if user == userMessage.senderID || user == userMessage.receiverID {
            //                print("Send message to \(user)")
            //                do {
            //                    let data = try userMessage.convertToJsonData()
            //                    webSocket?.send(raw: data, opcode: .binary)
            //                    print(userMessage)
            //                } catch let error {
            //                    print(error.localizedDescription)
            //                }
            //            }
        }
    }
    
    func createOrFindUserRoom(ws: WebSocket,
                              userID: String,
                              oponentID: String,
                              completion: @escaping ((Bool) -> Void)) async {
        
        if let rooms = try? await Room.query(on: db).all(),
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
            do {
                try await usersRoom.save(on: db)
                completion(true)
            } catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
    func saveMessage(userMessage: UserMessage, completion: @escaping (() -> Void)) async {
        do {
            db.withConnection {
                userMessage.save(on: $0)
            }.whenComplete {  res in
                switch res {
                case .failure(_):
                    print("Something went wrong save message.")
                case .success:
                    print("message saved")
                    completion()
//                    self.sendData(userMessage: userMessage)
                }
            }
        } catch {
            print(error)
        }
        
    }
    
    func sendData(userMessage: UserMessage, isNewRoom: Bool) async {
        let newRoom = await newRoom()
        print("ALL ROOM Users CONNECTIONS: \(connections)")
        connections?.forEach({ (user, webSocket) in
            if user == userMessage.senderID || user == userMessage.receiverID {
                print("Send message to \(user)")
                do {
                    var data: Data!
                    if isNewRoom {
                        data = newRoom
                    } else {
                         data = try userMessage.convertToJsonData()
                    }
                    webSocket?.send(raw: data, opcode: .binary)

                    print(userMessage)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        })
    }
    
    func newRoom() async -> Data? {
        let filteredRoom = try? await Room.query(on: self.db).with(\.$messages).all().first(where: { $0.id == self.usersRoom.id })
        let decodedRoom = try? JSONEncoder().encode(filteredRoom)
        return decodedRoom
    }
    
    func getAllRooms(req: Request) async throws -> [Room] {
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
    
    func deleteAllRooms(req: Request) async throws -> [Room] {
        try await Room.query(on: req.db).with(\.$messages).delete()
        return [Room]()
    }
}
