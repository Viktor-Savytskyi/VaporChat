//
//  File.swift
//  
//
//  Created by Developer on 14.07.2023.
//

import Fluent

struct CreateUser1: AsyncMigration {
    func prepare(on database: FluentKit.Database) async throws {
        try await database.schema("users")
            .id()
            .field("imageUrl", .string, .required)
            .field("firstName", .string, .required)
            .field("lastName", .string, .required)
            .field("lastOnlineDate", .string)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
