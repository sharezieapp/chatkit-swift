import XCTest
import PusherPlatform
@testable import PusherChatkit

class UserTests: XCTestCase {
    
    // MARK: - Properties
    
    var persistenceController: PersistenceController!
    
    var firstTestURL: URL!
    var secondTestURL: URL!
    
    var firstTestMetadata: Metadata!
    var secondTestMetadata: Metadata!
    
    var firstTestManagedObjectID: NSManagedObjectID!
    var secondTestManagedObjectID: NSManagedObjectID!
    
    // MARK: - Tests lifecycle
    
    override func setUp() {
        super.setUp()
        
        guard let url = Bundle.current.url(forResource: "Model", withExtension: "momd"), let model = NSManagedObjectModel(contentsOf: url) else {
            assertionFailure("Unable to locate test model.")
            return
        }
        
        let storeDescription = NSPersistentStoreDescription(inMemoryPersistentStoreDescription: ())
        storeDescription.shouldAddStoreAsynchronously = false
        
        guard let persistenceController = try? PersistenceController(model: model, storeDescriptions: [storeDescription]) else {
            assertionFailure("Failed to instantiate persistence controller.")
            return
        }
        
        self.persistenceController = persistenceController
        
        let mainContext = self.persistenceController.mainContext
        
        mainContext.performAndWait {
            let firstUserEntity = mainContext.create(UserEntity.self)
            self.firstTestManagedObjectID = firstUserEntity.objectID
            
            let secondUserEntity = mainContext.create(UserEntity.self)
            self.secondTestManagedObjectID = secondUserEntity.objectID
        }
        
        self.firstTestURL = URL(fileURLWithPath: "/dev/null")
        self.secondTestURL = URL(fileURLWithPath: "/dev/zero")
        
        self.firstTestMetadata = ["firstKey" : "firstValue"]
        self.secondTestMetadata = ["secondKey" : "secondValue"]
    }
    
    // MARK: - Tests
    
    func testShouldCreateUserWithCorrectValues() {
        let user = User(identifier: "testIdentifier",
                        name: "testName",
                        avatar: self.firstTestURL,
                        presenceState: .offline,
                        metadata: self.firstTestMetadata,
                        createdAt: Date.distantPast,
                        updatedAt: Date.distantFuture,
                        objectID: self.firstTestManagedObjectID)
        
        XCTAssertEqual(user.identifier, "testIdentifier")
        XCTAssertEqual(user.name, "testName")
        XCTAssertEqual(user.avatar, self.firstTestURL)
        XCTAssertEqual(user.presenceState, PresenceState.offline)
        XCTAssertNotNil(user.metadata)
        XCTAssertEqual(user.metadata as? [String : String], self.firstTestMetadata as? [String : String])
        XCTAssertEqual(user.createdAt, Date.distantPast)
        XCTAssertEqual(user.updatedAt, Date.distantFuture)
        XCTAssertEqual(user.objectID, self.firstTestManagedObjectID)
    }
    
    func testUserShouldHaveTheSameHashForTheSameIdentifiers() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "testIdentifier",
                              name: "anotherName",
                              avatar: self.secondTestURL,
                              presenceState: .online,
                              metadata: self.secondTestMetadata,
                              createdAt: Date.distantFuture,
                              updatedAt: Date.distantPast,
                              objectID: self.secondTestManagedObjectID)
        
        XCTAssertEqual(firstUser.hashValue, secondUser.hashValue)
    }
    
    func testUserShouldOnlyUseIdentifierToGenerateHash() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "anotherIdentifier",
                              name: "testName",
                              avatar: self.firstTestURL,
                              presenceState: .offline,
                              metadata: self.firstTestMetadata,
                              createdAt: Date.distantPast,
                              updatedAt: Date.distantFuture,
                              objectID: self.firstTestManagedObjectID)
        
        XCTAssertNotEqual(firstUser.hashValue, secondUser.hashValue)
    }
    
    func testShouldCompareTwoUsersAsEqualWhenValuesOfAllPropertiesAreTheSame() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "testIdentifier",
                              name: "testName",
                              avatar: self.firstTestURL,
                              presenceState: .offline,
                              metadata: self.firstTestMetadata,
                              createdAt: Date.distantPast,
                              updatedAt: Date.distantFuture,
                              objectID: self.firstTestManagedObjectID)
        
        XCTAssertEqual(firstUser, secondUser)
    }
    
    func testShouldNotCompareTwoUsersAsEqualWhenIdentifierValuesAreDifferent() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "anotherIdentifier",
                              name: "testName",
                              avatar: self.firstTestURL,
                              presenceState: .offline,
                              metadata: self.firstTestMetadata,
                              createdAt: Date.distantPast,
                              updatedAt: Date.distantFuture,
                              objectID: self.firstTestManagedObjectID)
        
        XCTAssertNotEqual(firstUser, secondUser)
    }
    
    func testShouldNotCompareTwoUsersAsEqualWhenNameValuesAreDifferent() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "testIdentifier",
                              name: "anotherName",
                              avatar: self.firstTestURL,
                              presenceState: .offline,
                              metadata: self.firstTestMetadata,
                              createdAt: Date.distantPast,
                              updatedAt: Date.distantFuture,
                              objectID: self.firstTestManagedObjectID)
        
        XCTAssertNotEqual(firstUser, secondUser)
    }
    
    func testShouldNotCompareTwoUsersAsEqualWhenAvatarValuesAreDifferent() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "testIdentifier",
                              name: "testName",
                              avatar: self.secondTestURL,
                              presenceState: .offline,
                              metadata: self.firstTestMetadata,
                              createdAt: Date.distantPast,
                              updatedAt: Date.distantFuture,
                              objectID: self.firstTestManagedObjectID)
        
        XCTAssertNotEqual(firstUser, secondUser)
    }
    
    func testShouldNotCompareTwoUsersAsEqualWhenPresenceStateValuesAreDifferent() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "testIdentifier",
                              name: "testName",
                              avatar: self.firstTestURL,
                              presenceState: .online,
                              metadata: self.firstTestMetadata,
                              createdAt: Date.distantPast,
                              updatedAt: Date.distantFuture,
                              objectID: self.firstTestManagedObjectID)
        
        XCTAssertNotEqual(firstUser, secondUser)
    }
    
    func testShouldCompareTwoUsersAsEqualWhenMetadataValuesAreDifferent() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "testIdentifier",
                              name: "testName",
                              avatar: self.firstTestURL,
                              presenceState: .offline,
                              metadata: self.secondTestMetadata,
                              createdAt: Date.distantPast,
                              updatedAt: Date.distantFuture,
                              objectID: self.firstTestManagedObjectID)
        
        XCTAssertEqual(firstUser, secondUser)
    }
    
    func testShouldNotCompareTwoUsersAsEqualWhenCreatedAtValuesAreDifferent() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "testIdentifier",
                              name: "testName",
                              avatar: self.firstTestURL,
                              presenceState: .offline,
                              metadata: self.firstTestMetadata,
                              createdAt: Date.distantFuture,
                              updatedAt: Date.distantFuture,
                              objectID: self.firstTestManagedObjectID)
        
        XCTAssertNotEqual(firstUser, secondUser)
    }
    
    func testShouldNotCompareTwoUsersAsEqualWhenUpdatedAtValuesAreDifferent() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "testIdentifier",
                              name: "testName",
                              avatar: self.firstTestURL,
                              presenceState: .offline,
                              metadata: self.firstTestMetadata,
                              createdAt: Date.distantPast,
                              updatedAt: Date.distantPast,
                              objectID: self.firstTestManagedObjectID)
        
        XCTAssertNotEqual(firstUser, secondUser)
    }
    
    func testShouldNotCompareTwoUsersAsEqualWhenObjectIDValuesAreDifferent() {
        let firstUser = User(identifier: "testIdentifier",
                             name: "testName",
                             avatar: self.firstTestURL,
                             presenceState: .offline,
                             metadata: self.firstTestMetadata,
                             createdAt: Date.distantPast,
                             updatedAt: Date.distantFuture,
                             objectID: self.firstTestManagedObjectID)
        
        let secondUser = User(identifier: "testIdentifier",
                              name: "testName",
                              avatar: self.firstTestURL,
                              presenceState: .offline,
                              metadata: self.firstTestMetadata,
                              createdAt: Date.distantPast,
                              updatedAt: Date.distantFuture,
                              objectID: self.secondTestManagedObjectID)
        
        XCTAssertNotEqual(firstUser, secondUser)
    }
    
}
