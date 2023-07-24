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
    
    @Field(key: "roomID")
    var roomID: String?
    
    init() {}
    
    init(id: UUID? = nil, senderID: String, receiverID: String, message: String, roomID: String?) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.message = message
        self.roomID = roomID
    }
    
    func convertToJsonData() throws -> Data {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            throw error
        }
    }
}
