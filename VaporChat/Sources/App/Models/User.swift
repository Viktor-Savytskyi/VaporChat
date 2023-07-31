//
//  File.swift
//  
//
//  Created by Developer on 14.07.2023.
//

import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "imageUrl")
    var imageUrl: String
    
    @Field(key: "firstName")
    var firstName: String
    
    @Field(key: "lastName")
    var lastName: String
    
    @Timestamp(key: "lastOnlineDate", on: .none, format: .iso8601)
    var lastOnlineDate: Date?
    
    init() {}
    
//    init(id: UUID? = nil, imageUrl: String, firstName: String, lastName: String, lastOnlineDate: Date?) {
//        self.id = id
//        self.imageUrl = imageUrl
//        self.firstName = firstName
//        self.lastName = lastName
//        self.lastOnlineDate = lastOnlineDate
//    }
}
