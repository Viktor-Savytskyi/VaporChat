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
    let messageController = MessageController()
    try app.register(collection: userController)
    let connectionController = ConnectionController(app: app)
    connectionController.connect()
    app.post("messages", use: messageController.createUserMessage)
    app.get("messages", use: messageController.getAllMessages)
    app.delete("messages", use: messageController.deleteAllMessages)
    app.get("rooms", use: RoomController.getAllRooms)
    app.delete("rooms", use: RoomController.deleteAllRooms)

    
}



