import Foundation
import CoreData
import PusherPlatform

/// A provider which maintains a collection of messages for a given room which have been retrieved from
/// the web service.
public class RoomDetailsProvider {
    
    // MARK: - Properties
    
    /// The identifier of the room for which the provider manages a collection of messages.
    public let roomIdentifier: String
    
    /// The current state of the provider related to the real time web service.
    public private(set) var realTimeState: RealTimeCollectionState
    
    /// The current state of the provider related to the non-real time web service.
    public private(set) var pagedState: PagedCollectionState
    
    /// The object that is notified when the content of the maintained collection of messages changed.
    public weak var delegate: RoomDetailsProviderDelegate? {
        didSet {
            if delegate == nil {
                self.messageFactory.stopReceivingNewMessages()
            }
            else {
                self.messageFactory.startReceivingNewMessages()
            }
        }
    }
    
    private let roomManagedObjectID: NSManagedObjectID
    private let fetchedResultsController: FetchedResultsController<MessageEntity>
    private let messageFactory: MessageEntityFactory
    
    /// The array of messages for the given room.
    ///
    /// This array contains all messages for the given room and retrieved from the web service as a result
    /// of either an internal real time subscription to the web service or explicit calls triggered
    /// as a result of calling `fetchOlderMessages(numberOfMessages:completionHandler:)
    /// method.
    public var messages: [Message] {
        return self.fetchedResultsController.objects.compactMap { try? $0.snapshot() }
    }
    
    /// Returns the number of messages stored locally in the maintained collection of messages.
    public var numberOfMessages: Int {
        return self.fetchedResultsController.numberOfObjects
    }
    
    // MARK: - Initializers
    
    init(room: Room, currentUser: User, persistenceController: PersistenceController, completionHandler: @escaping CompletionHandler) {
        self.roomIdentifier = room.identifier
        self.realTimeState = .initializing
        self.pagedState = .initializing
        
        self.roomManagedObjectID = room.objectID
        self.messageFactory = MessageEntityFactory(roomID: self.roomManagedObjectID,
                                                   currentUserManagedObjectID: currentUser.objectID,
                                                   persistenceController: persistenceController)
        
        let context = persistenceController.mainContext
        let predicate = NSPredicate(format: "%K == %@", #keyPath(MessageEntity.room), self.roomManagedObjectID)
        let sortDescriptor = NSSortDescriptor(key: #keyPath(MessageEntity.identifier), ascending: true) { (lhs, rhs) -> ComparisonResult in
            guard let lhsString = lhs as? String, let lhs = Int(lhsString), let rhsString = rhs as? String, let rhs = Int(rhsString) else {
                return .orderedSame
            }
            
            return NSNumber(value: lhs).compare(NSNumber(value: rhs))
        }
        
        self.fetchedResultsController = FetchedResultsController(sortDescriptors: [sortDescriptor], predicate: predicate, context: context)
        self.fetchedResultsController.delegate = self
        
        self.fetchData(completionHandler: completionHandler)
    }
    
    // MARK: - Methods
    
    /// Returns the messages at the given index in the maintained collection of messages.
    /// - Parameters:
    ///     - index: The index of object that should be returned from the maintained collection of
    ///     messages.
    ///
    /// - Returns: An instance of `Message` from the maintained collection of messages or `nil`
    /// when the object could not be found.
    public func message(at index: Int) -> Message? {
        return (try? self.fetchedResultsController.object(at: index)?.snapshot()) ?? nil
    }
    
    /// Triggers an asynchronous call to the web service that retrieves a batch of historical
    /// currently not present in the maintained collection of messages.
    ///
    /// - Parameters:
    ///     - numberOfMessages: The maximum number of messages that should be retrieved from
    ///     the web service.
    ///     - completionHandler:An optional completion handler called when the call to the web
    ///     service finishes with either a successful result or an error.
    public func fetchOlderMessages(numberOfMessages: UInt, completionHandler: CompletionHandler? = nil) {
        guard self.pagedState == .partiallyPopulated, let lastMessageIdentifier = self.message(at: 0)?.identifier else {
            if let completionHandler = completionHandler {
                // TODO: Return error
                completionHandler(nil)
            }
            
            return
        }
        
        self.pagedState = .fetching
        
        self.messageFactory.receiveOldMessages(numberOfMessages: Int(numberOfMessages), lastMessageIdentifier: lastMessageIdentifier, delay: 1.0) {
            self.pagedState = .partiallyPopulated
            
            if let completionHandler = completionHandler {
                completionHandler(nil)
            }
        }
    }
    
    // MARK: - Private methods
    
    private func fetchData(completionHandler: @escaping CompletionHandler) {
        guard self.realTimeState == .initializing else {
            return
        }
        
        self.realTimeState = .online
        
        self.messageFactory.receiveInitialMessages(numberOfMessages: 10, delay: 1.0) {
            self.pagedState = .partiallyPopulated
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
}

// MARK: - FetchedResultsControllerDelegate

extension RoomDetailsProvider: FetchedResultsControllerDelegate {
    
    func fetchedResultsController<ResultType>(_ fetchedResultsController: FetchedResultsController<ResultType>, didInsertObjectsWithRange range: Range<Int>) where ResultType : NSManagedObject {
        self.delegate?.roomDetailsProvider(self, didReceiveMessagesAtIndexRange: range)
    }
    
    func fetchedResultsController<ResultType>(_ fetchedResultsController: FetchedResultsController<ResultType>, didUpdateObject: ResultType, at index: Int) where ResultType : NSManagedObject {
        guard let object = self.fetchedResultsController.object(at: index), let message = try? object.snapshot() else {
            return
        }
        
        self.delegate?.roomDetailsProvider(self, didUpdateMessageAtIndex: index, previousValue: message)
    }
    
    func fetchedResultsController<ResultType>(_ fetchedResultsController: FetchedResultsController<ResultType>, didDeleteObject: ResultType, at index: Int) where ResultType : NSManagedObject {
        guard let object = self.fetchedResultsController.object(at: index), let message = try? object.snapshot() else {
            return
        }
        
        self.delegate?.roomDetailsProvider(self, didRemoveMessageAtIndex: index, previousValue: message)
    }
    
}

// MARK: - Delegate

/// A delegate protocol that describes methods that will be called by the associated
/// `RoomDetailsProvider` when the maintainted collection of messages have changed.
public protocol RoomDetailsProviderDelegate: class {
    
    /// Notifies the receiver that new messages have been added to the maintened collection of messages.
    ///
    /// - Parameters:
    ///     - roomDetailsProvider: The `RoomDetailsProvider` that called the method.
    ///     - range: The range of added objects in the maintened collection of messages.
    func roomDetailsProvider(_ roomDetailsProvider: RoomDetailsProvider, didReceiveMessagesAtIndexRange range: Range<Int>)
    
    /// Notifies the receiver that a message from the maintened collection of messages have been updated.
    ///
    /// - Parameters:
    ///     - joinedRoomsProvider: The `RoomDetailsProvider` that called the method.
    ///     - index: The index of the updated object in the maintened collection of messages.
    ///     - previousValue: The value of the message prior to the update.
    func roomDetailsProvider(_ roomDetailsProvider: RoomDetailsProvider, didUpdateMessageAtIndex index: Int, previousValue: Message)
    
    /// Notifies the receiver that a room from the maintened collection of messages have been removed.
    ///
    /// - Parameters:
    ///     - joinedRoomsProvider: The `RoomDetailsProvider` that called the method.
    ///     - index: The index of the removed object in the maintened collection of messages.
    ///     - previousValue: The value of the message prior to the removal.
    func roomDetailsProvider(_ roomDetailsProvider: RoomDetailsProvider, didRemoveMessageAtIndex index: Int, previousValue: Message)
    
}