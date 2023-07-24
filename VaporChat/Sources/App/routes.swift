import Vapor
 

func routes(_ app: Application) throws {
   /* app.get { req async in
        "It works!"
    }
    
    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    */
    
    let userController = UserController()
    try app.register(collection: userController)
    let messageController = MessageController(app: app)
    messageController.connect()
    app.post("messages", use: messageController.createUserMessage)
    app.get("messages", use: messageController.getAllMessages)
    app.delete("messages", use: messageController.deleteAllMessages)
    app.get("rooms", use: RoomController.getAllRooms)
    app.delete("rooms", use: RoomController.deleteAllRooms)

    
}



