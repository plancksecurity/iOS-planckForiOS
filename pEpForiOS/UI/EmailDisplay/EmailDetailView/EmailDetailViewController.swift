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
    private var collectionViewUpdateTasks: [()->Void] = []
    private var emailViewControllers = [EmailViewController]() //BUFF:
    lazy private var documentInteractionController = UIDocumentInteractionController()
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var previousButton: UIBarButtonItem!
    @IBOutlet weak var flagButton: UIBarButtonItem!
    @IBOutlet weak var destructiveButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    var viewModel: EmailDetailViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupToolbar()
    }

    //BUFF: move
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        viewModel?.delegate = self
        collectionView.register(UINib(nibName: EmailDetailViewController.xibName, bundle: nil),
                                forCellWithReuseIdentifier: EmailDetailViewController.cellId)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.startMonitoring() //???: should UI know about startMonitoring?
        collectionView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureView()
    }

    // MARK: - Target & Action

    @IBAction func flagButtonPressed(_ sender: UIBarButtonItem) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        guard let indexPath = indexPathOfCurrentlyVisibleCell else {
            Log.shared.errorAndCrash("Nothing shown?")
            return
        }
        vm.handleFlagButtonPress(for: indexPath)
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
        // We are manually computing the currently shown indexPath as
        // collectionView.indexPathsForVisibleItems oftern contains more then one (i.e. 2) indexpaths.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        return visibleIndexPath
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

    private func configureView() { //BUFF: HERE
        // Make sure the NavigationBar is shown, even if the previous view has hidden it.
        navigationController?.setNavigationBarHidden(false, animated: false) //BUFF: rm NC in storyboard?
        
        //ToolBar
        if splitViewController != nil {
            if onlySplitViewMasterIsShown {
                navigationController?.setToolbarHidden(false, animated: false)
            } else {
                navigationController?.setToolbarHidden(true, animated: false)
            }
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        
        destructiveButton.image = vm.destructiveButtonIcon(forMessageAt: indexPathOfCurrentlyVisibleCell)
        flagButton.image = vm.flagButtonIcon(forMessageAt: indexPathOfCurrentlyVisibleCell)
        
        previousButton.isEnabled = thereIsAPreviousMessageToShow //BUFF: to VM
        nextButton.isEnabled = thereIsANextMessageToShow
        
        
        showPepRating()
        
        //        if let internalMessage = message, !internalMessage.imapFlags.seen { //BUFF: TODO: mark as seen
        //            internalMessage.markAsSeen()
        //        }
        
        
    }

    private func showPepRating() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        guard let indexPath = indexPathOfCurrentlyVisibleCell else {
            Log.shared.errorAndCrash("Nothing shown?")
            return
        }
        guard let ratingView = showNavigationBarSecurityBadge(pEpRating: vm.pEpRating(forItemAt: indexPath)) else {
            // Nothing to show for current message
            return
        }

        if vm.canShowPrivacyStatus(forItemAt: indexPath) {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                              action: #selector(showHandshakeView(gestureRecognizer:)))
            ratingView.addGestureRecognizer(tapGestureRecognizer)
        }
    }

    @objc
    func showHandshakeView(gestureRecognizer: UITapGestureRecognizer? = nil) {
        if onlySplitViewMasterIsShown {
            performSegue(withIdentifier: .segueHandshakeCollapsed, sender: self) //BUFF: HERE: re add seques in storyboard

        } else {
            performSegue(withIdentifier: .segueHandshake, sender: self)
        }
    }

    //    // Sets the destructive bottom bar item accordint to the message (trash/archive)
    //    private func setupDestructiveButtonIcon() { //BUFF: to VM
    //       let shownMessage =  indexPathOfCurrentlyVisibleCell
    //
    //        if msg.parent.defaultDestructiveActionIsArchive {
    //            // Replace the Storyboard set trash icon for providers that use "archive" rather than
    //            // "delete" as default
    //            destructiveButton.image = #imageLiteral(resourceName: "folders-icon-archive")
    //        }
    //    }
}

// MARK: - Private

extension EmailDetailViewController {

    // MARK: - SETUP

    private func setupToolbar() {
        let pEpButton = UIBarButtonItem.getPEPButton(action: #selector(showPepActions(sender:)),
                                                     target: self)
        pEpButton.tag = BarButtonType.settings.rawValue
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
                                                             target: nil,
                                                             action: nil)
        flexibleSpace.tag = BarButtonType.space.rawValue
        toolbarItems?.append(contentsOf: [flexibleSpace, pEpButton])
        if !(onlySplitViewMasterIsShown) {
            navigationItem.rightBarButtonItems = toolbarItems
        }

    }

    @objc
    private func showPepActions(sender: UIBarButtonItem) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        guard let indexPath = indexPathOfCurrentlyVisibleCell else {
            Log.shared.errorAndCrash("Nothing shown?")
            return
        }

        let actionSheetController = UIAlertController.pEpAlertController(preferredStyle: .actionSheet)

        if vm.canShowPrivacyStatus(forItemAt:indexPath), let handshakeAction = showHandshakeViewAction() {
            actionSheetController.addAction(handshakeAction)
        }
        actionSheetController.addAction(tutorialAction())
        actionSheetController.addAction(showSettingsAction())

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "possible private status action"),
            style: .cancel) { (action) in }
        actionSheetController.addAction(cancelAction)

        if splitViewController != nil, !onlySplitViewMasterIsShown {
            actionSheetController.popoverPresentationController?.barButtonItem = sender
        }
        present(actionSheetController, animated: true)
    }

    private func showSettingsAction() -> UIAlertAction {
        let action = UIAlertAction(
            title: NSLocalizedString("Settings", comment: "acction sheet title 2"),
            style: .default) { [weak self] (action) in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "lost myself")
                    return
                }
                me.showSettingsViewController()
        }
        return action
    }

    private func tutorialAction() -> UIAlertAction{
        return UIAlertAction(
            title: NSLocalizedString("Tutorial", comment: "show tutorial from compose view"),
            style: .default) { _ in
                TutorialWizardViewController.presentTutorialWizard(viewController: self)
        }
    }

    private func showHandshakeViewAction() -> UIAlertAction? {
        guard
            let vm = viewModel,
            let indexPath = indexPathOfCurrentlyVisibleCell,
            vm.isHandshakePossible(forItemAt: indexPath)
            else {
                return nil
        }
        let action = UIAlertAction(title: NSLocalizedString("Privacy Status",
                                                            comment: "action sheet title 1"),
                                   style: .default) { [weak self] (action) in
                                    guard let me = self else {
                                        Log.shared.errorAndCrash(message: "lost myself")
                                        return
                                    }
                                    me.showHandshakeView()
        }

        return action
    }

    @objc
    private func showHandshakeScreen() {
        splitViewController?.preferredDisplayMode = .allVisible
        guard let nav = splitViewController?.viewControllers.first as? UINavigationController,
            let vc = nav.topViewController else {
                return
        }
        UIUtils.presentSettings(on: vc, appConfig: appConfig)
    }

    @objc
    private func showSettingsViewController() {
        splitViewController?.preferredDisplayMode = .allVisible
        guard let nav = splitViewController?.viewControllers.first as? UINavigationController,
            let vc = nav.topViewController else {
                return
        }
        UIUtils.presentSettings(on: vc, appConfig: appConfig)
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

extension EmailDetailViewController: UIScrollViewDelegate {
    // Called after programatically triggered scrollling animation ended.
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard
            let vm = viewModel,
            let indexPath = indexPathOfCurrentlyVisibleCell else {
                Log.shared.errorAndCrash("Invalid state")
                return
        }
        vm.handleEmailShown(forItemAt: indexPath)
        configureView()
    }
    // Called after scrollling animation  triggered by user ended.
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard
            let vm = viewModel,
            let indexPath = indexPathOfCurrentlyVisibleCell else {
                Log.shared.errorAndCrash("Invalid state")
                return
        }
        vm.handleEmailShown(forItemAt: indexPath)
        configureView()
    }
}

// MARK: - SegueHandlerType

extension EmailDetailViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case segueReplyFrom
        case segueReplyAllForm
        case segueForward
        case segueHandshake
        case segueHandshakeCollapsed
        case segueShowMoveToFolder
        case noSegue
    }

    private func composeMode(for segueId: SegueIdentifier) -> ComposeUtil.ComposeMode {
        if segueId == .segueReplyFrom {
            return .replyFrom
        } else if segueId == .segueReplyAllForm {
            return  .replyAll
        } else if segueId == .segueForward {
            return  .forward
        } else {
            Log.shared.errorAndCrash("Unsupported input")
            return .replyFrom
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let vm = viewModel,
            let indexPath = indexPathOfCurrentlyVisibleCell
            else {
                Log.shared.errorAndCrash("Invalid state")
                return
        }
        let theId = segueIdentifier(for: segue)
        switch theId {
        case .segueReplyFrom, .segueReplyAllForm, .segueForward:
            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? ComposeTableViewController else {
                    Log.shared.errorAndCrash("No DVC?")
                    break
            }
            destination.appConfig = appConfig
            destination.viewModel = vm.composeViewModel(forMessageRepresentedByItemAt: indexPath,
                                                        composeMode: composeMode(for: theId))
        case .segueShowMoveToFolder:
            guard  let nav = segue.destination as? UINavigationController,
                let destination = nav.topViewController as? MoveToAccountViewController else {
                    Log.shared.errorAndCrash("No DVC?")
                    break
            }
            destination.appConfig = appConfig
            destination.viewModel = viewModel?.moveToAccountViewModel(forMessageRepresentedByItemAt: indexPath)
        case .segueHandshake, .segueHandshakeCollapsed:
            fatalError()

            guard let nv = segue.destination as? UINavigationController,
                let vc = nv.topViewController as? HandshakeViewController else {
                    Log.shared.errorAndCrash("No DVC?")
                    break
            }

            guard let message = vm.message(representedByRowAt: indexPath) else {
                Log.shared.errorAndCrash("No message")
                return
            }

            //as we need a view to be source of the popover and title view is not always present.
            //we directly use the navigation bar view.
            nv.popoverPresentationController?.delegate = self
            nv.popoverPresentationController?.sourceView = nv.view
            nv.popoverPresentationController?.sourceRect = CGRect(x: nv.view.bounds.midX,
                                                                  y: nv.view.bounds.midY,
                                                                  width: 0,
                                                                  height: 0)
            vc.appConfig = appConfig
            vc.message = message
            break
        case .noSegue:
            break
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            documentInteractionController.dismissMenu(animated: false)
        }

        splitViewController?.preferredDisplayMode = .allVisible

        coordinator.animate(alongsideTransition: nil)
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension EmailDetailViewController: UIPopoverPresentationControllerDelegate {

    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect:
        UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {

        guard let titleView = navigationItem.titleView else {
            return
        }

        rect.initialize(to: CGRect(x:titleView.bounds.midY,
                                   y: titleView.bounds.midX,
                                   width:0,
                                   height:0))
        view.pointee = titleView

    }
}


// MARK: - EmailDetailViewModelDelegate

/// FetchedResultsController (FRC) (und thus QueryResults and subclasses) delegate methods are
/// designed for usage with UITableView methods like willUpdate & didupdate. As UICollectionView
/// does not offer those methods but uses batchUpdate, this class mimics a UITableViews behaviour.
/// - note: FRC does have callbacks for batchUpdate starting from iOS13. Remove this class and use
///         the batchupdate delegte methods of FRC directly after iOS12 support is dropped.
extension EmailDetailViewController: EmailDetailViewModelDelegate {

    func isNotUndecryptableAnyMore(indexPath: IndexPath) {
        addUpdateTask { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.collectionView?.reloadItems(at: [indexPath])
        }
    }

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
            me.configureView()
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
        guard collectionViewUpdateTasks.count == 0 else {
            Log.shared.errorAndCrash("We expect all updates done before `willReceiveUpdates` is called again.")
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
            let updateTasksToRun = Array(me.collectionViewUpdateTasks)
            me.collectionViewUpdateTasks.removeAll()
            updateTasksToRun.forEach { $0() }
        }
        collectionView?.performBatchUpdates(performChangesBlock)
    }

    func reloadData(viewModel: EmailDisplayViewModel) {
        collectionView?.reloadData()
    }

    private func addUpdateTask(_ block: @escaping ()->Void) {
        collectionViewUpdateTasks.append(block)
    }
}
