//
//  File.swift
//  
//
//  Created by Developer on 19.07.2023.
//

import Vapor
import Fluent

final class UserMessage: Model, Content {
    static let schema = "messages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "senderID")
    var senderID: String
    
    @Field(key: "receiverID")
    var receiverID: String
    
    @Field(key: "message")
    var message: String
    
    @OptionalParent(key: "roomID")
    var room: Room?
    
    @Timestamp(key: "createdAt", on: .create, format: .iso8601)
    var createdAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, senderID: String, receiverID: String, message: String, roomID: Room.IDValue?, createdAt: Date?) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.message = message
        self.$room.id = roomID
        self.createdAt = createdAt
    }
    enum CodingKeys: String, CodingKey {
           case id
           case senderID
           case receiverID
           case message
           case createdAt
       }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderID, forKey: .senderID)
        try container.encode(receiverID, forKey: .receiverID)
        
        try container.encode(message, forKey: .message)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString = dateFormatter.string(from: createdAt ?? Date())
        try container.encode(dateString, forKey: .createdAt)
    }

    required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Decode all properties except for "room"
            id = try container.decode(UUID.self, forKey: .id)
            senderID = try container.decode(String.self, forKey: .senderID)
            receiverID = try container.decode(String.self, forKey: .receiverID)
            message = try container.decode(String.self, forKey: .message)
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        }
    
    func convertToJsonData() throws -> Data {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            throw error
        }
    }
}
