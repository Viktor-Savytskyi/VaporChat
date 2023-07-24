//
//  File.swift
//  
//
//  Created by Developer on 20.07.2023.
//

import Fluent

//struct DeleteMessageSchema: Migration {
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        database.schema("messages").delete()
//    }
//    
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        fatalError("This migration cannot be reverted")
//    }
//}
//
//struct CreateMessagesSchema: Migration {
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//       database.schema("messages")
//            .id()
//            .field("senderID", .string, .required)
//            .field("receiverID", .string, .required)
//            .field("message", .string, .required)
//            .field("room", .custom(Room.self), .required)
//            .create()
//    }
//    
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        fatalError("This migration cannot be reverted")
//    }
//}

//struct AddNewFieldToTable: Migration {
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        database.schema("messages")
//            .field("room", .custom(Room.self), .required) // Додайте нове поле до таблиці з відповідним типом даних
//            .update()
//    }
//
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        database.schema("messages")
//            .deleteField("room") // Видаліть поле при відкаті міграції
//            .update()
//    }
//}
