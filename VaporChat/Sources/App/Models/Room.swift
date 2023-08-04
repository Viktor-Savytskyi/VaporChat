//
//  File.swift
//  
//
//  Created by Developer on 23.07.2023.
//

import Vapor
import Fluent

final class Room: Model, Content {    
    static let schema = "rooms"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "users")
    var users: [String]
    
    @Children(for: \.$room)
    var messages: [UserMessage]
    
    init() { }
    
    init(id: UUID? = UUID(), users: [String]) {
        self.id = id
        self.users = users
    }
    
    func convertToJsonData() throws -> Data {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            throw error
        }
    }
}
