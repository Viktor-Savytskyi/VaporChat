//
//  File.swift
//  
//
//  Created by Developer on 20.07.2023.
//

import Fluent

struct CreateMessage: AsyncMigration {
    func prepare(on database: FluentKit.Database) async throws {
        try await database.schema("messages")
            .id()
            .field("senderID", .string, .required)
            .field("receiverID", .string, .required)
            .field("message", .string, .required)
            .field("roomID", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("messages").delete()
    }
}
