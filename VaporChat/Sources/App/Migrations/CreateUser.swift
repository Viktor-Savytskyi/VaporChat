//
//  File.swift
//  
//
//  Created by Developer on 14.07.2023.
//

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("imageUrl", .string, .required)
            .field("firstName", .string, .required)
            .field("lastName", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
