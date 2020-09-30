//
//  EmailDetailViewController.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit
import QuickLook

import pEpIOSToolbox

// Represents the a list of mails showing one mail with all details in full screen.
class EmailDetailViewController: BaseViewController {
    static private let cellXibName = "EmailDetailCollectionViewCell"
    static private let cellId = "EmailDetailViewCell"
    /// Collects all QueryResultsDelegate reported changes to call them in one CollectionView
    /// batchUpdate.
    private var collectionViewUpdateTasks: [()->Void] = []
    /// EmailViewControllers of currently used cells
    private var emailSubViewControllers = [EmailViewController]()
    /// Stuff that must be done once only in viewWillAppear
    private var doOnce: (()-> Void)?
    private var pdfPreviewUrl: URL?

    @IBOutlet weak var nextButton: UIBarButtonItem?
    @IBOutlet weak var previousButton: UIBarButtonItem?
    @IBOutlet weak var nextButtonForSplitView: UIBarButtonItem?
    @IBOutlet weak var prevButtonForSplitView: UIBarButtonItem?
    @IBOutlet weak var flagButton: UIBarButtonItem!
    @IBOutlet weak var destructiveButton: UIBarButtonItem!
    @IBOutlet weak var replyButton: UIBarButtonItem!
    @IBOutlet weak var pEpIconSettingsButton: UIBarButtonItem!
    @IBOutlet weak var moveToFolderButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    private var pEpButtonHelper = UIBarButtonItem.getPEPButton(action: #selector(showSettingsViewController),
                                                               target: self)
    
    private var separatorsArray = [UIBarButtonItem]()

    /// IndexPath to show on load
    var firstItemToShow: IndexPath?
    
    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }
    
    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }
    
    var viewModel: EmailDetailViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .all
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doOnce?()
        createSeparators()
        configureView()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Re-layout cells after device orientaion change
        collectionView.collectionViewLayout.invalidateLayout()
        adjustTitleViewPositionIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setupToolbar()
        // Works around a UI glitch: When !onlySplitViewMasterIsShown, the colletionView scroll
        // position is inbetween two cells after orientation change.
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.scrollToLastViewedCell()
        }
    }
    
    // MARK: - Target & Action

    @objc @IBAction func flagButtonPressed(_ sender: UIBarButtonItem) {
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
        performSegue(withIdentifier: .segueShowMoveToFolder, sender: self)
    }

    @IBAction func destructiveButtonPressed(_ sender: UIBarButtonItem) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        guard let indexPath = indexPathOfCurrentlyVisibleCell else {
            Log.shared.errorAndCrash("Nothing shown?")
            return
        }
        vm.handleDestructiveButtonPress(for: indexPath)
    }

    @IBAction func replyButtonPressed(_ sender: UIBarButtonItem) {
        // The ReplyAllPossibleChecker() should be pushed into the view model
        // as soon as there is one.
        guard
            let vm = viewModel,
            let indexPath = indexPathOfCurrentlyVisibleCell,
            let replyAllChecker = vm.replyAllPossibleChecker(forItemAt: indexPath)
            else {
                Log.shared.errorAndCrash("Invalid state")
                return
        }

        let alert = ReplyAlertCreator(replyAllChecker: replyAllChecker)
            .withReplyOption { [weak self] action in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost MySelf")
                    return
                }
                me.performSegue(withIdentifier: .segueReplyFrom , sender: self)
        }.withReplyAllOption() { [weak self] action in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }
            me.performSegue(withIdentifier: .segueReplyAllForm , sender: self)
        }.withFordwardOption { [weak self] action in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }
            me.performSegue(withIdentifier: .segueForward , sender: self)
        }.withToggelMarkSeenOption(for: vm.message(representedByRowAt: indexPath))
            .withCancelOption()
            .build()

        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }

        present(alert, animated: true, completion: nil)
    }

    @IBAction func pEpIconSettingsButtonPressed(_ sender: UIBarButtonItem) {
        showSettingsViewController()
    }

    @objc
    @IBAction func previousButtonPressed(_ sender: UIBarButtonItem) {
        showPreviousIfAny()
    }
    
    @objc
    @IBAction func nextButtonPressed(_ sender: UIBarButtonItem) {
        showNextIfAny()
    }
}

// MARK: - Private

extension EmailDetailViewController {

    private func setup() {
        viewModel?.delegate = self
        setupCollectionView()
        doOnce = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.viewModel?.startMonitoring()
            me.collectionView.reloadData()
            me.doOnce = nil
        }
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: EmailDetailViewController.cellXibName,
                                      bundle: nil),
                                forCellWithReuseIdentifier: EmailDetailViewController.cellId)
    }

    @objc private func showNextIfAny() {
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

    @objc private func showPreviousIfAny() {
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

    @objc
    private func showTrustManagementView(gestureRecognizer: UITapGestureRecognizer? = nil) {
        performSegue(withIdentifier: .segueTrustManagement, sender: self)
    }

    private var indexPathOfCurrentlyVisibleCell: IndexPath? {
        // We are manually computing the currently shown indexPath as
        // collectionView.indexPathsForVisibleItems often contains more then one (i.e. 2) indexpaths.
        let visibleRect = CGRect(origin: collectionView.contentOffset,
                                 size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX,
                                   y: visibleRect.midY)
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        return visibleIndexPath
    }

    /// Makes sure the message the user is currently viewing is still shown after collection view
    /// updates (which may modify the visible cell by removing or inserting a mails with
    /// row num < currently shown).
    private func scrollToLastViewedCell() {
        guard
            let vm = viewModel,
            let indexPath = vm.indexPathForCellDisplayedBeforeUpdating else {
                // The previously shown message might have been deleted.
                // Do nothing ...
                return
        }
        collectionView?.scrollToItem(at: indexPath,
                                     at: .left,
                                     animated: false)
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

    private func configureView() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        
        //if there are no messages to show and we are in "Iphone" we have to pop up the detailView
        //and go back to the list.
        if vm.rowCount == 0 && onlySplitViewMasterIsShown {
            // We haven't any email, we should exit from this view
            navigationController?.popViewController(animated: true)
            return
        }

        destructiveButton?.image = vm.destructiveButtonIcon(forMessageAt: indexPathOfCurrentlyVisibleCell)
        flagButton?.image = vm.flagButtonIcon(forMessageAt: indexPathOfCurrentlyVisibleCell)

        previousButton?.isEnabled = thereIsAPreviousMessageToShow
        nextButton?.isEnabled = thereIsANextMessageToShow
        prevButtonForSplitView?.isEnabled = thereIsAPreviousMessageToShow
        nextButtonForSplitView?.isEnabled = thereIsANextMessageToShow
        

        showPepRating()
        setupToolbar()
    }

    private func showPepRating() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        guard let indexPath = indexPathOfCurrentlyVisibleCell else {
            // List is empty. That is ok. The user might have deleted the last shown message.
            return
        }

        vm.pEpRating(forItemAt: indexPath) { [weak self] (rating) in
            guard let me = self else {
                // Valid case. The user might have dismissed the view meanwhile.
                // Do nothing.
                return
            }
            guard let ratingView = me.showNavigationBarSecurityBadge(pEpRating: rating) else {
                // Nothing to show for current message
                return
            }
            vm.shouldShowPrivacyStatus(forItemAt: indexPath) { (shouldShowPrivacyStatus) in
                if shouldShowPrivacyStatus {
                    let tapGestureRecognizer = UITapGestureRecognizer(target: me,
                                                                      action: #selector(me.showTrustManagementView(gestureRecognizer:)))
                    ratingView.addGestureRecognizer(tapGestureRecognizer)
                }
            }
        }
    }
    
    // Removes all EmailViewController that are not connected to a cell any more.
    private func releaseUnusedSubViewControllers() {
        emailSubViewControllers = emailSubViewControllers.filter { $0.view.superview != nil }
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

    private func showTrustManagementViewAction() -> UIAlertAction {
        let action = UIAlertAction(title: NSLocalizedString("Privacy Status", comment: "action sheet title 1"),
                                   style: .default) { [weak self] (action) in
                                    guard let me = self else {
                                        Log.shared.errorAndCrash(message: "lost myself")
                                        return
                                    }
                                    me.showTrustManagementView()
        }
        return action
    }

    @objc
    private func showSettingsViewController() {
        splitViewController?.preferredDisplayMode = .allVisible
        UIUtils.presentSettings(appConfig: appConfig)
    }

    private func setupEmailViewController(forRowAt indexPath: IndexPath) -> EmailViewController? {
        guard
            let vm = viewModel,
            let createe = storyboard?.instantiateViewController(withIdentifier: EmailViewController.storyboardId) as? EmailViewController
            else {
                Log.shared.errorAndCrash("No V[M|C]")
                return nil
        }
        createe.appConfig = appConfig
        createe.message = vm.message(representedByRowAt: indexPath) //!!!: EmailVC should have a VM which should be created in our VM. This VC should not be aware of `Message`s!
        createe.delegate = self
        emailSubViewControllers.append(createe)

        return createe
    }
}

// MARK: - UICollectionViewDelegate

extension EmailDetailViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Expect to have a view model")
            return
        }

        // Handle pre-emptive loading of older messages from the server, if they exist,
        // but only if there is no email list shown (therefore `onlySplitViewMasterIsShown`).
        if onlySplitViewMasterIsShown {
            vm.fetchOlderMessagesIfRequired(forIndexPath: indexPath)
        }

        // Scroll to show message selected by previous (EmailList) view
        guard let indexToScrollTo = firstItemToShow else {
            // Is not first load.
            // Do nothing
            return
        }
        // On first load only: Display message selected by user in previous VC
        collectionView.scrollToItem(at: indexToScrollTo, at: .left, animated: false)
        firstItemToShow = nil
        guard let currentlyVisibledIdxPth = indexPathOfCurrentlyVisibleCell else {
            Log.shared.errorAndCrash("Invalid state")
            return
        }
        vm.handleEmailShown(forItemAt: currentlyVisibledIdxPth)
        configureView()
    }
}

// MARK: - UICollectionViewDataSource

extension EmailDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return viewModel?.rowCount ?? 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        releaseUnusedSubViewControllers()

        guard
            let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier: EmailDetailViewController.cellId,
                                               for: indexPath) as? EmailDetailCollectionViewCell,
            let emailViewController = setupEmailViewController(forRowAt: indexPath)
            else {
                Log.shared.errorAndCrash("Error setting up cell")
                return collectionView.dequeueReusableCell(withReuseIdentifier: EmailDetailViewController.cellId,
                                                          for: indexPath)
        }
        cell.setContainedView(containedView: emailViewController.view)

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EmailDetailViewController: UICollectionViewDelegateFlowLayout {

    /// Make cell size == collection view size
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
                // No cells shown any more. Can happen, is valid.
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
        case segueTrustManagement
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
            destination.viewModel = viewModel?.getMoveToFolderViewModel(forMessageRepresentedByItemAt: indexPath)
        case .segueTrustManagement:
            guard let nv = segue.destination as? UINavigationController,
                let vc = nv.topViewController as? TrustManagementViewController ,
                let trustManagementViewModel = viewModel?.trustManagementViewModel else {
                    Log.shared.errorAndCrash("No DVC, No trustManagementViewModel?")
                    break
            }

            nv.modalPresentationStyle = .fullScreen

            //as we need a view to be source of the popover and title view is not always present.
            //we directly use the navigation bar view.
            nv.popoverPresentationController?.delegate = self
            nv.popoverPresentationController?.sourceView = nv.view
            nv.popoverPresentationController?.sourceRect = CGRect(x: nv.view.bounds.midX,
                                                                  y: nv.view.bounds.midY,
                                                                  width: 0,
                                                                  height: 0)
            
            vc.appConfig = appConfig
            vc.viewModel = trustManagementViewModel

            break
        case .noSegue:
            break
        }
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension EmailDetailViewController: UIPopoverPresentationControllerDelegate {

    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController,
                                       willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>,
                                       in view: AutoreleasingUnsafeMutablePointer<UIView>) {

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
/// does not offer those methods but uses batchUpdate we are collecting the update tasks and run
/// them all in one batchUpdate.
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
        // Perform updates ...
        let performChangesBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let updateTasksToRun = Array(me.collectionViewUpdateTasks)
            me.collectionViewUpdateTasks.removeAll()
            updateTasksToRun.forEach { $0() }
        }
        guard let vm = viewModel as? EmailDetailViewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        if vm.shouldScrollBackToCurrentlyViewdCellAfterUpdate {
            // Dis- and later enable animations while updating to avoid visible glitches while first
            // updating the colelction and then scroll back to the cell the user is currently viewing.
            UIView.setAnimationsEnabled(false)
            collectionView?.performBatchUpdates(performChangesBlock)
            UIView.setAnimationsEnabled(true)
            // ... and make sure the the previously shown message is still shown after the update.
            scrollToLastViewedCell()
        } else {
            collectionView?.performBatchUpdates(performChangesBlock)
        }
        configureView()

        // We might need to scroll emailLISTview to curretlySelectedIndexPath here in case loads
        //of new mails came in or have been deleted and the selected row is not visible any more.
    }

    func reloadData(viewModel: EmailDisplayViewModel) {
        collectionView?.reloadData()
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // This is a valid case. it might happen when filters are applied
                return
            }
            me.configureView()
        }
    }

    func select(itemAt indexPath: IndexPath) {
        scroll(to: indexPath, animated: false)
        configureView()
    }

    private func addUpdateTask(_ block: @escaping ()->Void) {
        collectionViewUpdateTasks.append(block)
    }
}

// MARK: - EmailViewControllerDelegate

extension EmailDetailViewController: EmailViewControllerDelegate {

    func openQLPreviewController(toShowDocumentWithUrl url: URL) {
        pdfPreviewUrl = url
        let previewController = QLPreviewController()
        previewController.dataSource = self
        present(previewController, animated: true, completion: nil)
    }
}

// MARK: - QLPreviewControllerDataSource

extension EmailDetailViewController: QLPreviewControllerDataSource {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController,
                           previewItemAt index: Int) -> QLPreviewItem {
        guard let url = pdfPreviewUrl else {
            fatalError("Could not load URL")
        }
        return url as QLPreviewItem
    }
}

// MARK: - SplitView handling

extension EmailDetailViewController: SplitViewHandlingProtocol {
    func splitViewControllerWill(splitViewController: PEPSplitViewController, newStatus: SplitViewStatus) {
        switch newStatus {
        case .collapse:
            // when splitview will collapse toolbar shoud be prepared
            var newToolbarItems = navigationItem.rightBarButtonItems
            navigationItem.rightBarButtonItems = nil
            if let pepButton = pEpIconSettingsButton {
                newToolbarItems?.append(createFlexibleBarButtonItem())
                newToolbarItems?.append(pepButton)
            } else {
                newToolbarItems?.append(createFlexibleBarButtonItem())
                newToolbarItems?.append(pEpButtonHelper)
            }
            var newtoolbar = [UIBarButtonItem]()
            for item in newToolbarItems! {
                if separatorsArray.contains(item) {
                    newtoolbar.append(createFlexibleBarButtonItem())
                } else {
                    newtoolbar.append(item)
                }
            }
            setToolbarItems(newtoolbar, animated: true)
            let next = UIBarButtonItem.getNextButton(action: #selector(nextButtonPressed), target: self)
            let previous = UIBarButtonItem.getPreviousButton(action: #selector(previousButtonPressed), target: self)
            previous.isEnabled = thereIsAPreviousMessageToShow
            next.isEnabled = thereIsANextMessageToShow
            let size = CGSize(width: 15, height: 25)
            next.image = next.image?.resizeImage(targetSize: size)
            previous.image = previous.image?.resizeImage(targetSize: size)
            previousButton = previous
            nextButton = next
            navigationItem.setRightBarButtonItems([next, previous], animated: false)
            navigationItem.leftBarButtonItems = []
        case .separate:
            //view itself correctly handles the bars when is gonna separate
            break
        }
    }
    /// Our own factory method for creating flexible space bar button items,
    /// tagged so we recognize them later, for easy removal.
    private func createFlexibleBarButtonItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
            target: nil,
            action: nil)
        return item
    }
}

// MARK: - Setup Toolbar

extension EmailDetailViewController {
    private func createSeparators() {
        //Spacer
        let defaultSpacerWidth: CGFloat = 8.0
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = defaultSpacerWidth
        
        let midSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        midSpacer.width = 18
        
        separatorsArray.append(contentsOf: [spacer,midSpacer])
    }
    private func setupToolbar() {
        if onlySplitViewMasterIsShown {
            navigationController?.setToolbarHidden(false, animated: false)
        } else {
            // Make sure the NavigationBar is shown, even if the previous view has hidden it.
            navigationController?.setToolbarHidden(true, animated: false)
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
        let size = CGSize(width: 15, height: 25)
        nextButton?.image = nextButton?.image?.resizeImage(targetSize: size)
        previousButton?.image = previousButton?.image?.resizeImage(targetSize: size)

        if !onlySplitViewMasterIsShown {
            // Up & Down Buttons

            let nextPrevButtonSize = CGRect(x: 0, y: 0, width: 27, height: 15)

            let downButton = UIButton(frame: nextPrevButtonSize)
            let downImage = UIImage(named: "chevron-icon-down")?.withRenderingMode(.alwaysTemplate)
            downButton.setBackgroundImage(downImage, for: .normal)
            downButton.tintColor = thereIsANextMessageToShow ? UIColor.pEpGreen : UIColor.pEpGray
            downButton.addTarget(self, action: #selector(showNextIfAny), for: .touchUpInside)

            let upButton = UIButton(frame: nextPrevButtonSize)
            let upImage = UIImage(named: "chevron-icon-up")?.withRenderingMode(.alwaysTemplate)
            upButton.setBackgroundImage(upImage, for: .normal)
            upButton.tintColor = thereIsAPreviousMessageToShow ? UIColor.pEpGreen : UIColor.pEpGray

            upButton.addTarget(self, action: #selector(showPreviousIfAny), for: .touchUpInside)
            upButton.isEnabled = thereIsAPreviousMessageToShow

            let downBarButtonItem = UIBarButtonItem(customView: downButton)
            let upBarButtonItem = UIBarButtonItem(customView: upButton)
            
            downBarButtonItem.isEnabled = thereIsANextMessageToShow
            upBarButtonItem.isEnabled = thereIsAPreviousMessageToShow
            
            navigationItem.leftBarButtonItems = [downBarButtonItem, separatorsArray[0], upBarButtonItem]

            //Reply
            let replyImage = UIImage(named: "pEpForiOS-icon-reply")
            let replyBarButtonItem = UIBarButtonItem(image: replyImage,
                                                     style: .plain,
                                                     target: self,
                                                     action: #selector(replyButtonPressed(_:)))

            //Folder
            let folderImage = UIImage(named: "pEpForiOS-icon-movetofolder")
            let folderButtonBarButtonItem = UIBarButtonItem(image: folderImage,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(moveToFolderButtonPressed(_:)))

            //Flag
            let flagImage = viewModel?.flagButtonIcon(forMessageAt: indexPathOfCurrentlyVisibleCell)
            let tintedimage = flagImage?.withRenderingMode(.alwaysTemplate)
            let flagFrame = CGRect(x: 0, y: 0, width: 14, height: 24)
            let flagButton = UIButton(frame: flagFrame)
            flagButton.setBackgroundImage(tintedimage, for: .normal)
            flagButton.imageView?.tintColor = UIColor.pEpGreen
            flagButton.addTarget(self, action: #selector(flagButtonPressed(_:)), for: .touchUpInside)
            let flagBarButtonItem = UIBarButtonItem(customView: flagButton)

            //Delete
            let deleteImage = viewModel?.destructiveButtonIcon(forMessageAt: indexPathOfCurrentlyVisibleCell)
            let deleteButtonBarButtonItem = UIBarButtonItem(image: deleteImage,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(destructiveButtonPressed(_:)))

            
            navigationItem.rightBarButtonItems = [replyBarButtonItem,
                                                  separatorsArray[1],
                                                  folderButtonBarButtonItem,
                                                  separatorsArray[1],
                                                  flagBarButtonItem,
                                                  separatorsArray[1],
                                                  deleteButtonBarButtonItem]
        } else {
            navigationItem.leftBarButtonItems = []
        }
    }
}
