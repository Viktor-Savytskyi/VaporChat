//
//  File.swift
//  
//
//  Created by Developer on 23.07.2023.
//

import Vapor
import Fluent

struct CreateChatRooms: AsyncMigration {
    func prepare(on database: FluentKit.Database) async throws {
        try await database.schema("rooms")
            .id()
            .field("users", .array(of: .string), .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("rooms").delete()
    }
}
