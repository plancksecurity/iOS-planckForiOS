//
//  FetchServiceBaseClass.swift
//  MessageModel
//
//  Created by Xavier Algarra on 21/08/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

public class FetchServiceBaseClass {

    public enum FetchError: Error {
        case isFetching
    }

    struct FolderKey: Hashable {
        let accountsUserAddress: String
        let name: String

        init(folder: Folder) {
            accountsUserAddress = folder.account.user.address
            name = folder.name
        }

        // MARK: Hashable
        static func ==(lhs: FolderKey, rhs: FolderKey) -> Bool {
            return lhs.accountsUserAddress == rhs.accountsUserAddress && lhs.name == rhs.name
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(accountsUserAddress)
            hasher.combine(name)
        }
    }

    private var isFetching = false
    private let queue: OperationQueue

    public init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated //I tend to use -utility, it is actually userInitiated though. Let's see if it blocks the UI somehow...
    }

    public func runService(inFolders folders: [Folder], completion: (()->())? = nil) throws {
        guard !isFetching else {
            throw FetchError.isFetching
        }
        let group = DispatchGroup()
        for folder in folders {
            isFetching = true
            group.enter()
            fetchMessages(inFolder: folder) {
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let me = self else {
                // This is a valid case. The client niled us, he is not interested in completion
                // any more. Eg. the UnifiedInbox (client) might be dismissed and does not exist
                // any more. All good.
                Log.shared.error("Lost myself, can not inform for completion")
                completion?()
                return
            }
            completion?()
            me.isFetching = false
        }
    }

    private func fetchMessages(inFolder folder: Folder, completion: (()->())? = nil) {
        guard folder.isSyncedWithServer else {
            // Do not try to fetch local folders like OUTBOX.
            completion?()
            return
        }

        let cdFolder = folder.cdObject

        guard let cdAccount = cdFolder.account else {
            Log.shared.errorAndCrash("inconsistent DB state. CDFolder for Folder %@ does not exist or its mandatory field \"account\" is not set.",
                folder.name)
            completion?()
            return
        }
        guard let imapConnectInfo = cdAccount.imapConnectInfo else {
            completion?()
            return
        }
        let folderKey = FolderKey(folder: folder)
        let imapConnection = ImapConnection(connectInfo: imapConnectInfo)
        let errorContainer = ErrorPropagator()
        let loginOp = LoginImapOperation(parentName: #function,
                                         errorContainer: errorContainer,
                                         imapConnection: imapConnection)
        let operation = operationToRun(errorContainer: errorContainer,
                                       imapConnection: imapConnection,
                                       folderName: folderKey.name)

        operation.addDependency(loginOp)
        operation.completionBlock = {
            completion?()
        }
        queue.addOperation(loginOp)
        queue.addOperation(operation)
    }

    func operationToRun(errorContainer: ErrorContainerProtocol,
                        imapConnection: ImapConnectionProtocol,
                        folderName: String) -> FetchMessagesInImapFolderOperation{
        fatalError("Subclasses need to implement this method.")
    }
}
