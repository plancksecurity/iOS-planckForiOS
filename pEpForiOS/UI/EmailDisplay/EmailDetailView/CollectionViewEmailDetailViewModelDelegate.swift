//
//  CollectionViewEmailDetailViewModelDelegate.swift
//  pEp
//
//  Created by Andreas Buff on 06.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// FetchedResultsController (FRC) (und thus QueryResults and subclasses) delegate methods are
/// designed for usage with UITableView methods like willUpdate & didupdate. As UICollectionView
/// does not offer those methods but uses batchUpdate, this class mimics a UITableViews behaviour.
/// - note: FRC does have callbacks for batchUpdate starting from iOS13. Remove this class and use
///         the batchupdate delegte methods of FRC directly after iOS12 support is dropped.
class CollectionViewEmailDetailViewModelDelegate {
    private var operations: [Operation] = []
    private let queue: OperationQueue = {
        let createe = OperationQueue()
        createe.maxConcurrentOperationCount = 1
        createe.qualityOfService = .userInteractive
        return createe
    }()
    weak private var collectionView: UICollectionView?

    // MARK: - Life Cycle

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    deinit {
        operations.forEach { $0.cancel() }
        operations.removeAll()
    }
}

// MARK: - QueryResultsIndexPathRowDelegate

extension CollectionViewEmailDetailViewModelDelegate: EmailDetailViewModelDelegate {

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didInsertDataAt indexPaths: [IndexPath]) {
        let op = BlockOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.collectionView?.insertItems(at: indexPaths)
        }
        operations.append(op)
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didUpdateDataAt indexPaths: [IndexPath]) {
        let op = BlockOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.collectionView?.reloadItems(at: indexPaths)
        }
        operations.append(op)
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didRemoveDataAt indexPaths: [IndexPath]) {
        let op = BlockOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.collectionView?.deleteItems(at: indexPaths)
        }
        operations.append(op)
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didMoveData atIndexPath: IndexPath,
                            toIndexPath: IndexPath) {
        let op = BlockOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.collectionView?.moveItem(at: atIndexPath, to: toIndexPath)
        }
        operations.append(op)
    }

    func willReceiveUpdates(viewModel: EmailDisplayViewModel) {
        operations.removeAll()
    }

    func allUpdatesReceived(viewModel: EmailDisplayViewModel) {
        let performChangesBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.queue.addOperations(me.operations, waitUntilFinished: true)
        }
        let completionBlock: (Bool)-> Void = { [weak self] finished in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.operations.removeAll()
        }
        collectionView?.performBatchUpdates(performChangesBlock, completion: completionBlock)
    }

    func reloadData(viewModel: EmailDisplayViewModel) {
        collectionView?.reloadData()
    }
}
