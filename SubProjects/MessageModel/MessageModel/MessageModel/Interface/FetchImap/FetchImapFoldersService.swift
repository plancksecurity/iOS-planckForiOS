import CoreData

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

public class FetchImapFoldersService {

    public enum FetchError: Error {
        case isFetching
        case accountNotFound
    }

    typealias Success = Bool
    typealias CompletionBlock = (Success)->()

    private var queue: OperationQueue

    public init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
    }

    private var isFetching = false
    let privateMoc = Stack.shared.newPrivateConcurrentContext

    public func runService(inAccounts accounts: [Account], completion: @escaping (Bool)->()) throws {
        guard !isFetching else {
            throw FetchError.isFetching
        }

        let group = DispatchGroup()
        for account in accounts {
            isFetching = true
            group.enter()
            if let cdAccount = try? accountInContext(cdAccount: account.cdObject) {
                fetchFolders(inCdAccount: cdAccount, context: privateMoc) { success in
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let me = self else {
                // Valid case. The object that owns this service might been dismissed already.
                completion(false)
                return
            }
            completion(true)
            me.isFetching = false
        }

    }

    private func accountInContext(cdAccount: CdAccount) throws -> CdAccount?  {
        let objID = cdAccount.objectID
        var cdAccountInContext: CdAccount?
        var problem: Error? = nil
        privateMoc.performAndWait {
            do {
                cdAccountInContext = try privateMoc.existingObject(with: objID) as? CdAccount
            } catch {
                problem = error
            }
        }
        guard let account = cdAccountInContext, problem == nil else {
            throw FetchError.accountNotFound
        }
        return account
    }

    func fetchFolders(inCdAccount cdAccount: CdAccount,
                      context: NSManagedObjectContext? = nil,
                      alsoCreatePEPFolder: Bool = false,
                      saveContextWhenDone: Bool = true,
                      completion: @escaping CompletionBlock) {
        func addOperationAndWait(blockingQueue: OperationQueue, operation: ImapSyncOperation) {
            blockingQueue.addOperation(operation)
            blockingQueue.waitUntilAllOperationsAreFinished()
        }

        func addFolderCreationOperation(context: NSManagedObjectContext?, imapConnection: ImapConnection, blockingQueue: OperationQueue, folderType: FolderType) {
            let createFolderOP = CreateIMAPFolderOperation(parentName: #function + "\(folderType.rawValue)", context: context, imapConnection: imapConnection, folderType: folderType)
            addOperationAndWait(blockingQueue: blockingQueue, operation: createFolderOP)
        }
        
        queue.addOperation {
            let blockingQueue = OperationQueue()
            blockingQueue.maxConcurrentOperationCount = 1
            blockingQueue.qualityOfService = .userInitiated

            var connect : EmailConnectInfo?
            context?.performAndWait {
                connect = cdAccount.imapConnectInfo
            }
            guard let connectInfo = connect else {
                return
            }

            let imapConnection = ImapConnection(connectInfo: connectInfo)
            let errorContainer = ErrorPropagator()

            let loginOp = LoginImapOperation(errorContainer: errorContainer, imapConnection: imapConnection)
            addOperationAndWait(blockingQueue: blockingQueue, operation: loginOp)

            if errorContainer.hasErrors {
                completion(false)
                return
            }

            let fetchFolderOp = SyncFoldersFromServerOperation(context: context,
                                                               errorContainer: errorContainer,
                                                               imapConnection: imapConnection,
                                                               saveContextWhenDone: saveContextWhenDone)
            addOperationAndWait(blockingQueue: blockingQueue, operation: fetchFolderOp)

            if errorContainer.hasErrors {
                completion(false)
                return
            }

            let createRequiredFoldersOP =
                CreateRequiredFoldersOperation(context: context,
                                               errorContainer: errorContainer,
                                               imapConnection: imapConnection,
                                               saveContextWhenDone: saveContextWhenDone)
            addOperationAndWait(blockingQueue: blockingQueue, operation: createRequiredFoldersOP)

            if alsoCreatePEPFolder {
                addFolderCreationOperation(context: context, imapConnection: imapConnection, blockingQueue: blockingQueue, folderType: .pEpSync)
                addFolderCreationOperation(context: context, imapConnection: imapConnection, blockingQueue: blockingQueue, folderType: .suspicious)
            }

            completion(!errorContainer.hasErrors)
        }
    }
}
