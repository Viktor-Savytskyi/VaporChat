//
//  File.swift
//  
//
//  Created by Developer on 27.07.2023.
//

import Foundation
import FluentKit

class CreateMessageThirdMigration: AsyncMigration {
    func prepare(on database: FluentKit.Database) async throws {
        try await database.schema("messages")
            .id()
            .field("senderID", .string, .required)
            .field("receiverID", .string, .required)
            .field("message", .string, .required)
            .field("roomID", .string, .required)
            .field("createdAt", .string)
            .create()
    }
    
    func revert(on database: FluentKit.Database) async throws {
        try await database.schema("messages").delete()
    }
    
    
}
