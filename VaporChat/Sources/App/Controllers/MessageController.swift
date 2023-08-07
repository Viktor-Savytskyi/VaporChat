//
//  File.swift
//  
//
//  Created by Developer on 01.08.2023.
//

import Vapor
import Fluent

enum UserTypingState: String {
    case typing
    case stopTyping
}

enum MessageField: String {
    case message
    case senderID
    case receiverID
}

class MessageController {
    
    var connections: [String : WebSocket?]?

    func saveMessage(userMessage: UserMessage, db: Database) async {
        db.withConnection {
            userMessage.save(on: $0)
        }.whenComplete {  res in
            switch res {
            case .failure(_):
                print("Something went wrong save message.")
            case .success:
                print("message saved")
            }
        }
    }
    
    func sendMessage(text: String) {
        let dictMessage = text.convertToDict(text: text)
        guard let receiverID = dictMessage[MessageField.receiverID.rawValue],
              let senderID = dictMessage[MessageField.senderID.rawValue],
              let message = dictMessage[MessageField.message.rawValue] else { return }
        
        if message == UserTypingState.typing.rawValue {
            self.broadcastTypingIndicator(userTypingState: .typing,
                                          for: receiverID,
                                          senderID: senderID)
        } else if message == UserTypingState.stopTyping.rawValue {
            self.broadcastTypingIndicator(userTypingState: .stopTyping,
                                          for: receiverID,
                                          senderID: senderID)
        } else {
           //here may be handle another text messages
        }
    }
    
    func createUserMessage(req: Request) async throws -> UserMessage {
        let userMessage = try req.content.decode(UserMessage.self)
        try await userMessage.create(on: req.db)
        return userMessage
    }
    
    func getAllMessages(req: Request) async throws -> [UserMessage] {
        let usersMessages = try await UserMessage.query(on: req.db).all().sorted(by: { $0.createdAt ?? Date() > $1.createdAt ?? Date()})
        return usersMessages
    }
    
    func deleteAllMessages(req: Request) async throws -> [UserMessage] {
        try await UserMessage.query(on: req.db).delete()
        return [UserMessage]()
    }
    
    
    func broadcastTypingIndicator(userTypingState: UserTypingState, for receiverID: String, senderID: String) {
        guard let userWebSocket = connections?[receiverID] else { return }
        let typingMessage =
        ("""
                \(MessageField.senderID.rawValue) : \(senderID)
                \(MessageField.receiverID.rawValue) : \(receiverID)
                \(MessageField.message.rawValue) : \(userTypingState.rawValue)
         """)
        userWebSocket?.send(typingMessage)
    }
}
