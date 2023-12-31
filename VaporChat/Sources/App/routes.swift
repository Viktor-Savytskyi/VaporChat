import Vapor
 

func routes(_ app: Application) throws {
    let userController = UserController()
    let messageController = MessageController()
    let roomController = RoomController(db: app.db)
    try app.register(collection: userController)
    let connectionController = ConnectionController(app: app)
    connectionController.userController = userController
    connectionController.messageController = messageController
    connectionController.roomController = roomController
    connectionController.connect()
    app.post("messages", use: messageController.createUserMessage)
    app.get("messages", use: messageController.getAllMessages)
    app.delete("messages", use: messageController.deleteAllMessages)
    app.get("rooms", use: roomController.getAllRooms)
    app.delete("rooms", use: roomController.deleteAllRooms)
}



