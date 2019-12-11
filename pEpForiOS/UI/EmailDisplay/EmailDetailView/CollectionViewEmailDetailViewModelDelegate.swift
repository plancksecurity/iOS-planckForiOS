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
    private var updateTasks: [()->Void] = []
    weak private var collectionView: UICollectionView?

    // MARK: - Life Cycle

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    deinit {
        updateTasks.removeAll()
    }
}

// MARK: - QueryResultsIndexPathRowDelegate

extension CollectionViewEmailDetailViewModelDelegate: EmailDetailViewModelDelegate {

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didInsertDataAt indexPaths: [IndexPath]) {
        addUpdateTask { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.collectionView?.insertItems(at: indexPaths)
        }
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didUpdateDataAt indexPaths: [IndexPath]) {
        addUpdateTask { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.collectionView?.reloadItems(at: indexPaths)
        }
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didRemoveDataAt indexPaths: [IndexPath]) {
        addUpdateTask { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.collectionView?.deleteItems(at: indexPaths)
        }
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel,
                            didMoveData atIndexPath: IndexPath,
                            toIndexPath: IndexPath) {
        addUpdateTask { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.collectionView?.moveItem(at: atIndexPath, to: toIndexPath)
        }
    }

    func willReceiveUpdates(viewModel: EmailDisplayViewModel) {
        guard updateTasks.count == 0 else {
            Log.shared.errorAndCrash("We expect all updates done before `willReceiveUpdates` is called again.") //BUFF: OK to ignore?
            return
        }
        // Do nothing
    }

    func allUpdatesReceived(viewModel: EmailDisplayViewModel) {
        let performChangesBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let updateTasksToRun = Array(me.updateTasks)
            me.updateTasks.removeAll()
            updateTasksToRun.forEach { $0() }
        }
        collectionView?.performBatchUpdates(performChangesBlock)
    }

    func reloadData(viewModel: EmailDisplayViewModel) {
        collectionView?.reloadData()
    }
}

// MARK: - Private

extension CollectionViewEmailDetailViewModelDelegate {

    private func addUpdateTask(_ block: @escaping ()->Void) {
        updateTasks.append(block)
    }
}
