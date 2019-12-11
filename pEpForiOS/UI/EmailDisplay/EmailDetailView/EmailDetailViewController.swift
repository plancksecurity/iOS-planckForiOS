//
//  EmailDetailViewController.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

// Represents the a list of mails showing one mail with all details in full screen.
//BUFF: docs!
class EmailDetailViewController: EmailDisplayViewController {
    static private let xibName = "EmailDetailCollectionViewCell"
    static private let cellId = "EmailDetailViewCell"
    private var emailViewControllers = [EmailViewController]()
    @IBOutlet weak var collectionView: UICollectionView!
    var viewModel: EmailDetailViewModel? {
        didSet {
            viewModel?.delegate = collectionViewEmailDetailViewModelDelegate
        }
    }
    var collectionViewEmailDetailViewModelDelegate: CollectionViewEmailDetailViewModelDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }

    //BUFF: move
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionViewEmailDetailViewModelDelegate =
            CollectionViewEmailDetailViewModelDelegate(collectionView: collectionView)
        viewModel?.delegate = collectionViewEmailDetailViewModelDelegate
        collectionView.register(UINib(nibName: EmailDetailViewController.xibName, bundle: nil),
                                forCellWithReuseIdentifier: EmailDetailViewController.cellId)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.startMonitoring() //???: should UI know about startMonitoring?
        collectionView.reloadData()
    }

    // MARK: - Target & Action

    @IBAction func flagButtonPressed(_ sender: UIBarButtonItem) {
        fatalError()
    }

    @IBAction func moveToFolderButtonPressed(_ sender: UIBarButtonItem) {
        fatalError()
    }

    @IBAction func destructiveButtonPressed(_ sender: UIBarButtonItem) {
        fatalError()
    }

    @IBAction func replyButtonPressed(_ sender: UIBarButtonItem) {
//        performSegue(withIdentifier: .segueReply, sender: self)
        fatalError()
    }

    @IBAction func previousButtonPressed(_ sender: UIBarButtonItem) {
        showPreviousIfAny()
    }
    
    @IBAction func nextButtonPressed(_ sender: UIBarButtonItem) {
        showNextIfAny()
    }

    //BUFF: move
    private func showNextIfAny() {
        guard
            let indexPathForCurrentlyVisibleCell = indexPathOfCurrentlyVisibleCell,
            thereIsANextMessageToShow
            else {
                // No mail to show
                return
        }
        let nextIndexPath = IndexPath(item: indexPathForCurrentlyVisibleCell.item + 1,
                                      section: indexPathForCurrentlyVisibleCell.section)
        scroll(to: nextIndexPath)
    }

    private func showPreviousIfAny() {
        guard
            let indexPathForCurrentlyVisibleCell = indexPathOfCurrentlyVisibleCell,
            thereIsAPreviousMessageToShow
            else {
                // No mail to show
                return
        }
            let nextIndexPath = IndexPath(item: indexPathForCurrentlyVisibleCell.item - 1,
                                          section: indexPathForCurrentlyVisibleCell.section)
            scroll(to: nextIndexPath)
    }

    private var indexPathOfCurrentlyVisibleCell: IndexPath? {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        // visibleIndexPaths.count can be 2 while animating from one to onother cell.
        // If taking the `first` mail leads to unexpected results, change to use `last` instead.
        return visibleIndexPaths.first
    }

    private var thereIsANextMessageToShow: Bool {
        guard let indexPathForCurrentlyVisibleCell = indexPathOfCurrentlyVisibleCell else {
            // No mail to show
            return false
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return false
        }
        return (indexPathForCurrentlyVisibleCell.row + 1) < vm.rowCount
    }

    private var thereIsAPreviousMessageToShow: Bool {
        guard let indexPathForCurrentlyVisibleCell = indexPathOfCurrentlyVisibleCell else {
            // No mail to show
            return false
        }

        return (indexPathForCurrentlyVisibleCell.row - 1) >= 0
    }


    private func scroll(to indexPath: IndexPath,
                        at: UICollectionView.ScrollPosition = .centeredHorizontally,
                        animated: Bool = true) {
        collectionView.scrollToItem(at: indexPath,
                                    at: at,
                                    animated: animated)
    }
}

// MARK: - UICollectionViewDelegate

extension EmailDetailViewController: UICollectionViewDelegate {
    //

}

// MARK: - UICollectionViewDataSource

extension EmailDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return viewModel?.rowCount ?? 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //BUFF: move emilVC setup
        guard
            let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier: EmailDetailViewController.cellId,
                                               for: indexPath) as? EmailDetailCollectionViewCell,
            let emailViewController = storyboard?.instantiateViewController(withIdentifier: EmailViewController.storyboardId) as? EmailViewController,
        let vm = viewModel
            else {
                Log.shared.errorAndCrash("Error setting up cell")
                return collectionView.dequeueReusableCell(withReuseIdentifier: EmailDetailViewController.cellId,
                                                          for: indexPath)
        }
        emailViewController.appConfig = appConfig
        //BUFF: HERE: set message to show
        emailViewController.message = vm.message(representedByRowAt: indexPath)

        emailViewControllers.append(emailViewController)
        cell.containerView.addSubview(emailViewController.view)
        emailViewController.view.fullSizeInSuperView()

//        emailViewController.
        //        let cell = co //BUFF: HERE
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EmailDetailViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

// MARK: - EmailDetailViewModelDelegate

extension EmailDetailViewController: EmailDetailViewModelDelegate {
    func emailListViewModel(viewModel: EmailDisplayViewModel, didInsertDataAt indexPaths: [IndexPath]) {
        //BUFF:
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel, didUpdateDataAt indexPaths: [IndexPath]) {
        //
    }


    func emailListViewModel(viewModel: EmailDisplayViewModel, didRemoveDataAt indexPaths: [IndexPath]) {
        //
    }

    func emailListViewModel(viewModel: EmailDisplayViewModel, didMoveData atIndexPath: IndexPath, toIndexPath: IndexPath) {
        //
    }

    func checkIfSplitNeedsUpdate(indexpath: [IndexPath]) {
        //
    }

    func willReceiveUpdates(viewModel: EmailDisplayViewModel) {
        //
    }

    func allUpdatesReceived(viewModel: EmailDisplayViewModel) {
        //
    }

    func reloadData(viewModel: EmailDisplayViewModel) {
        //
    }

    func toolbarIs(enabled: Bool) { //BUFF: needed? alse move to listView
        //
    }

    func showUnflagButton(enabled: Bool) { //BUFF: needed? alse move to listView
        //
    }

    func showUnreadButton(enabled: Bool) { //BUFF: needed? alse move to listView
        //
    }

    func updateView() {
        //
    }



}
