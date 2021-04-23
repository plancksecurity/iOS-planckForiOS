//
//  ComposeViewController.swift
//  pEp
//
//  Created by Martin Brude on 30/09/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import Photos
import ContactsUI

import SwipeCellKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

class ComposeViewController: UIViewController {
    public static let storyboardId = "ComposeViewController"

    @IBOutlet var sendButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!

    private var suggestionsChildViewController: SuggestTableViewController?
    lazy private var mediaAttachmentPickerProvider: MediaAttachmentPickerProvider? = {
        guard let pickerVm = viewModel?.mediaAttachmentPickerProviderViewModel() else {
            Log.shared.errorAndCrash("Invalid state")
            return nil
        }
        return MediaAttachmentPickerProvider(with: pickerVm)
    }()
    lazy private var documentAttachmentPicker: DocumentAttachmentPickerViewController = {
        return DocumentAttachmentPickerViewController(
            viewModel: viewModel?.documentAttachmentPickerViewModel())
    }()
    
    private var isInitialFocusSet = false
    private var scrollUtil = TextViewInTableViewScrollUtil()
    private var doOnce: (()->())?

    var viewModel: ComposeViewModel? {
        didSet {
            // Make sure we are the delegate. Always.
            viewModel?.delegate = self
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        return KeyCommandsProvider.commands
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        if viewModel == nil {
            setupModel()
        }
        doOnce = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.tableView.reloadData()
            me.doOnce = nil
        }
        registerForNotifications()

        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                tableView.backgroundColor = .secondarySystemBackground
            } else {
                tableView.backgroundColor = .white
            }
        }  else {
            tableView.backgroundColor = .white
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doOnce?()
        navigationController?.title = title
        tableView.hideSeperatorForEmptyCells()
        setupRecipientSuggestionsTableViewController()
        viewModel?.handleDidReAppear()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup & Configuration

    private func setupView() {
        registerXibs()
        tableView.rowHeight = UITableView.automaticDimension
         //An arbitrary value auto resize seems to require for some reason.
        tableView.estimatedRowHeight = 1000

        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemBackground
        } else {
            tableView.backgroundColor = .white
        }
    }

    private func setupModel() {
        viewModel = ComposeViewModel()
        _ = viewModel?.suggestViewModel()
    }

    private final func setupRecipientSuggestionsTableViewController() {
        let storyboard = UIStoryboard(name: Constants.reusableStoryboard, bundle: nil)
        guard
            let vm = viewModel,
            let suggestVc = storyboard.instantiateViewController(
                withIdentifier: SuggestTableViewController.storyboardId)
                as? SuggestTableViewController,
            let suggestView = suggestVc.view else {
                Log.shared.errorAndCrash("No VC.")
                return
        }
        suggestionsChildViewController = suggestVc
        suggestionsChildViewController?.viewModel = vm.suggestViewModel()
        addChild(suggestVc)
        suggestView.isHidden = true
        tableView.addSubview(suggestView)
    }

    // MARK: - IBActions

    @IBAction func cancel(_ sender: Any) {
        updateBodyState()
        if viewModel?.showCancelActions ?? false {
            showAlertControllerWithOptionsForCanceling(sender: sender)
        } else {
            dismiss()
        }
        viewModel?.handleUserClickedCancelButton()
    }

    @IBAction func send() {
        updateBodyState()
        viewModel?.handleUserClickedSendButton()
    }

    private func updateBodyState() {
        /// The body textview's autocorrection doesn't call the textview's delegate.
        /// To guarantee the message is sent exactly as it's in the textview we trigger the endEditing callback before sending.
        if let cell = tableView.visibleCells.filter({$0 is BodyCell}).first as? BodyCell {
            cell.textViewDidEndEditing(cell.textView)
        }
    }
}

// MARK: - PEP Color View

extension ComposeViewController {
    private func setupPepColorView(for pEpRating: Rating, pEpProtected: Bool) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        //Not so nice. The view(controller) should not know about state and protection.
        let pEpRatingView = showNavigationBarSecurityBadge(pEpRating: pEpRating,
                                                           pEpProtection: pEpProtected)

        // Handshake on simple touch if possible
        vm.canDoHandshake { [weak self] (canDoHandshake) in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                // Do nothing ...
                return
            }
            if canDoHandshake {
                let tapGestureRecognizerHandshake = UITapGestureRecognizer(
                    target: self,
                    action: #selector(me.actionHandshake))
                pEpRatingView?.addGestureRecognizer(tapGestureRecognizerHandshake)
            }
        }

        // Toggle privacy status on long press for trusted and reliable
        let pEpColor = pEpRating.pEpColor()
        if pEpColor == .green || pEpColor == .yellow {
            let tapGestureRecognizerToggleProtection = UILongPressGestureRecognizer(
                target: self,
                action: #selector(showPepActions))
            pEpRatingView?.addGestureRecognizer(tapGestureRecognizerToggleProtection)
        }
    }

    @objc
    private func showPepActions(sender: UIBarButtonItem) {
        guard let vm = viewModel, let titleView = navigationItem.titleView else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        let actionSheetController = UIUtils.actionSheet()
        actionSheetController.addAction(changeSecureStatusAction(pEpProtected: vm.state.pEpProtection))
        actionSheetController.addAction(disableAlertAction())
        actionSheetController.popoverPresentationController?.sourceView = titleView
        actionSheetController.popoverPresentationController?.sourceRect = titleView.bounds

        present(actionSheetController, animated: true)
    }

    private func changeSecureStatusAction(pEpProtected: Bool) -> UIAlertAction {
        let disable = NSLocalizedString("Disable Protection",
                                        comment: "Disable Protection button title of pEp protection toggle action sheet")
        let enable = NSLocalizedString("Enable Protection",
                                       comment: "Enable Protection button title of pEp protection toggle action sheet")

        let action = UIAlertAction(title: pEpProtected ? disable : enable ,
                                   style: .default) { [weak self] (action) in
                                    guard let me = self, let vm = me.viewModel else {
                                        Log.shared.lostMySelf()
                                        return
                                    }
                                    let originalValueOfProtection = vm.state.pEpProtection
                                    vm.handleUserChangedProtectionStatus(to: !originalValueOfProtection)
        }
        return action
    }

    private func disableAlertAction() -> UIAlertAction {
        return UIAlertAction(
            title: NSLocalizedString("Cancel",
                                     comment: "Cancel button title of pEp protection toggle action sheet"),
            style: .cancel) { (action) in }
    }

    /// Shows the handshake menu, if applicable.
    /// - Parameter gestureRecognizer: The gesture recognizer that triggered this
    @objc func actionHandshake(gestureRecognizer: UITapGestureRecognizer) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        vm.canDoHandshake { [weak self] (canDoHandshake) in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                // Do nothing ...
                return
            }
            if (canDoHandshake) {
                me.performSegue(withIdentifier: .segueTrustManagement, sender: self)
            }
        }
    }
}

// MARK: - ComposeViewModelDelegate

extension ComposeViewController: ComposeViewModelDelegate {

    func hideSuggestions() {
        suggestionsChildViewController?.view.isHidden = true
        tableView.isScrollEnabled = true
    }

    func showSuggestions(forRowAt indexPath: IndexPath) {
        updateSuggestTable(suggestionsForCellAt: indexPath)
        tableView.isScrollEnabled = false
    }

    func suggestions(haveScrollFocus: Bool) {
        tableView.isScrollEnabled = !haveScrollFocus
    }

    func validatedStateChanged(to isValidated: Bool) {
        sendButton.isEnabled = isValidated
    }

    func contentChanged(inRowAt indexPath: IndexPath) {
        guard
            let cell = tableView.cellForRow(at: indexPath) as? TextViewContainingTableViewCell
            else {
                // Either we are in initial setup (no cellForRow_at:) or the sender is not
                // editable (can not change size).
                return
        }
        if cell is RecipientCell {
            cell.sizeToFit()
            // We intentionally do not scroll recipinet fields (causes issues).
            tableView.updateSize {
                if !(self.suggestionsChildViewController?.view.isHidden ?? true) {
                    // Asure suggestions are still below the recipient cell after updating the
                    // cells size.
                    // It would be more elegant to let auto layout do it (setting constraints).
                    self.updateSuggestTable(suggestionsForCellAt: indexPath)
                }
            }
        } else if cell is BodyCell {
            // Make sure initialFocus is set before layouting logic takes place
            setInitialFocus()
            cell.textView.sizeToFit()
            scrollUtil.layoutAfterTextDidChange(tableView: tableView, textView: cell.textView)
        } else {
            tableView.updateSize()
        }
    }

    func focusSwitched() {
        tableView.updateSize()
    }

    func modelChanged() {
        tableView.reloadData()
    }

    func sectionChanged(section: Int) {
        tableView.beginUpdates()
        if section < tableView.numberOfSections {
            tableView.reloadSections(IndexSet(integer: section), with: .automatic)
        } else {
            // The section did not exist previously
            tableView.insertSections(IndexSet(integer: section), with: .automatic)
        }
        tableView.endUpdates()
    }

    func colorBatchNeedsUpdate(for rating: Rating, protectionEnabled: Bool) {
        setupPepColorView(for: rating, pEpProtected: protectionEnabled)
    }

    func showMediaAttachmentPicker() {
        presentMediaAttachmentPickerProvider()
    }

    func hideMediaAttachmentPicker() {
        guard isModalViewCurrentlyShown else {
            // Picker is not shown. Nothing to do.
            return
        }
        mediaAttachmentPickerProvider?.imagePicker.dismiss(animated: true) {
            self.setPreviousFocusAfterPicker()
        }
    }

    func showDocumentAttachmentPicker() {
        presentDocumentAttachmentPicker()
    }

    func showContactsPicker() {
        presentContactPicker()
    }

    /// Restore focus to the previous focused cell after closing the picker action
    private func didHideContactPicker() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(message: "No VM!")
            return
        }
        let idxPath = vm.beforeContactsPickerFocus()
        guard let cellToFocus = tableView.cellForRow(at: idxPath)
            as? TextViewContainingTableViewCell else {
                Log.shared.errorAndCrash("Error casting")
                return
        }
        DispatchQueue.main.async {
            cellToFocus.setFocus()
        }
    }

    func documentAttachmentPickerDone() {
        self.setPreviousFocusAfterPicker()
    }

    func showTwoButtonAlert(withTitle title: String,
                            message: String,
                            cancelButtonText: String,
                            positiveButtonText: String,
                            cancelButtonAction: @escaping () -> Void,
                            positiveButtonAction: @escaping () -> Void) {
        UIUtils.showTwoButtonAlert(withTitle: title,
                                   message: message,
                                   cancelButtonText: cancelButtonText,
                                   positiveButtonText: positiveButtonText,
                                   cancelButtonAction: cancelButtonAction,
                                   positiveButtonAction: positiveButtonAction)
    }

   func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - SegueHandlerType

extension ComposeViewController: SegueHandlerType {

    enum SegueIdentifier: String {
        case segueTrustManagement
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueTrustManagement:
            guard
                let nc = segue.destination as? UINavigationController,
                let destination = nc.rootViewController as? TrustManagementViewController else {
                    Log.shared.errorAndCrash("Segue issue")
                    return
            }
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("No vm")
                return
            }
            guard let trustManagementViewModel = vm.trustManagementViewModel() else {
                Log.shared.error("Message not found")
                return
            }
            destination.viewModel = trustManagementViewModel
        }
    }
}

// MARK: - Address Suggestions

extension ComposeViewController {
    private final func updateSuggestTable(suggestionsForCellAt indexPath: IndexPath) {
        let rectCell = tableView.rectForRow(at: indexPath)
        let position = rectCell.origin.y + rectCell.height
        suggestionsChildViewController?.view.frame.origin.y = position
        suggestionsChildViewController?.view.frame.size.height =
            tableView.bounds.size.height - position
    }
}

// MARK: - MediaAttachmentPickerProvider

extension ComposeViewController {

    private func presentMediaAttachmentPickerProvider() {
        let media = Capability.media
        media.requestAndInformUserInErrorCase(viewController: self)  {
            [weak self] (permissionsGranted: Bool, error: Capability.AccessError?) in
            guard permissionsGranted else {
                return
            }
            guard let me = self,
            let picker = me.mediaAttachmentPickerProvider?.imagePicker else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.present(picker, animated: true)
        }
    }
}

// MARK: - DocumentAttachmentPickerViewController

extension ComposeViewController {
    private func presentDocumentAttachmentPicker() {
        present(documentAttachmentPicker, animated: true, completion: nil)
    }
}

// MARK: - CNContactPicker

extension ComposeViewController: CNContactPickerDelegate {
    private func presentContactPicker() {
        let contactPickerVC = CNContactPickerViewController()
        contactPickerVC.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0")
        contactPickerVC.predicateForSelectionOfContact = NSPredicate(format: "emailAddresses.@count == 1")
        contactPickerVC.predicateForSelectionOfProperty = NSPredicate(format: "key == 'emailAddresses'")
        contactPickerVC.delegate = self
        present(contactPickerVC, animated: true)
    }

    // This gets called when the user cancels his request to pick a contact
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        // It's needed to set up an additional, extra work. For example update the focus in a tableview cell/row.
        didHideContactPicker()
    }

    // If contact has more than one e-mail we show contact details and user can select only one e-mail
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        guard let emailAddress = contactProperty.value as? String else {
            Log.shared.errorAndCrash(message: "emailAddress MUST be valid!")
            return
        }
        vm.handleContactSelected(address: emailAddress,
                                 addressBookID: contactProperty.contact.identifier,
                                 userName: contactProperty.contact.givenName)
        didHideContactPicker()
    }

    // If contact has only one e-mail we choose that one
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        guard let emailAddress = contact.emailAddresses.first else {
            Log.shared.errorAndCrash(message: "emailAddress MUST be valid!")
            return
        }
        vm.handleContactSelected(address: String(emailAddress.value),
                                 addressBookID: contact.identifier,
                                 userName: contact.givenName)

        didHideContactPicker()
    }
}

// MARK: - UITableViewDataSource

extension ComposeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = setupCellForIndexPath(indexPath, in: tableView) else {
            Log.shared.errorAndCrash("No cell")
            return UITableViewCell()
        }
        return cell
    }

    private func setupCellForIndexPath(_ indexPath: IndexPath,
                                  in tableView: UITableView) -> UITableViewCell? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UITableViewCell()
        }

        var result: UITableViewCell?
        let section = vm.sections[indexPath.section]

        if section.type == .recipients {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCell.reuseId)
                    as? RecipientCell,
                let rowVm = section.rows[indexPath.row] as? RecipientCellViewModel
                else {
                    Log.shared.errorAndCrash("Invalid state")
                    return nil
            }
            cell.setup(with: rowVm)
            result = cell
        } else if section.type == .wrapped {
            result = tableView.dequeueReusableCell(withIdentifier: "WrappedCell")
        } else if section.type == .account {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell.reuseId)
                    as? AccountCell,
                let rowVm = section.rows[indexPath.row] as? AccountCellViewModel
                else {
                    Log.shared.errorAndCrash("Invalid state")
                    return nil
            }
            cell.setup(with: rowVm)
            result = cell
        } else if section.type == .subject {
                guard
                    let cell = tableView.dequeueReusableCell(withIdentifier: SubjectCell.reuseId)
                        as? SubjectCell,
                    let rowVm = section.rows[indexPath.row] as? SubjectCellViewModel
                    else {
                        Log.shared.errorAndCrash("Invalid state")
                    return nil
            }
            cell.setup(with: rowVm)
            result = cell
        } else if section.type == .body {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: BodyCell.reuseId)
                    as? BodyCell,
                let rowVm = section.rows[indexPath.row] as? BodyCellViewModel
                else {
                    Log.shared.errorAndCrash("Invalid state")
                    return nil
            }
            cell.setup(with: rowVm)
            result = cell
        } else if section.type == .attachments {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: AttachmentCell.reuseId)
                    as? AttachmentCell,
                let rowVm = section.rows[indexPath.row] as? AttachmentViewModel
                else {
                    Log.shared.errorAndCrash("Invalid state")
                    return nil
            }
            cell.setup(with: rowVm)
            cell.delegate = self //SwipeKitDelegate
            result = cell
        }

        return result
    }
}

// MARK: - UITableViewDelegate

extension ComposeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel?.handleUserSelectedRow(at: indexPath)
    }
}

// MARK: - XIBs

extension ComposeViewController {
    private func registerXibs() {
        let nib = UINib(nibName: AttachmentCell.reuseId, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: AttachmentCell.reuseId)
    }
}

// MARK: - SwipeAction

extension ComposeViewController {
    // MARK: - SwipeTableViewCell

    private func deleteAction(forCellAt indexPath: IndexPath) {
        tableView.beginUpdates()
        viewModel?.handleRemovedRow(at: indexPath)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
}

// MARK: - SwipeTableViewCellDelegate

extension ComposeViewController: SwipeTableViewCellDelegate {

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard
            let vm = viewModel,
            vm.isAttachmentSection(indexPath: indexPath) else {
                return nil
        }
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") {
            [weak self] action, indexPath in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.deleteAction(forCellAt: indexPath)
        }
        deleteAction.title = NSLocalizedString("Remove", comment:
            "ComposeTableView: Label of swipe left. Removing of attachment."
        )
        deleteAction.backgroundColor = SwipeActionDescriptor.trash.color
        return (orientation == .right ? [deleteAction] : nil)
    }

    func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        if isLastRow(indexPath: indexPath) {
            // The last cell is not yet displayed (as we are in "willDisplay ..."), thus async.
            DispatchQueue.main.async { [weak self] in
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    return
                }
                me.setInitialFocus()
            }
        }
    }
}

// MARK: - First Responder / Focus

extension ComposeViewController {

    //BUFF:

    private struct KeyCommandsProvider {
        fileprivate static let commands: [UIKeyCommand] = {
            let tabForward = UIKeyCommand(input: "\t",
                                          modifierFlags: [],
                                          action: #selector(jumpToNextField(command:)))
            let tabBackward = UIKeyCommand(input: "\t",
                                           modifierFlags: .shift,
                                           action: #selector(jumpToPreviousField(command:)))
            return [tabForward, tabBackward]
        }()
    }

    private func setFocusToNextCell(currentCell: UITableViewCell) {

        // Finds the first next section that contains rows
        func indexOfNextSectionContainingRows(from currentSectionIndex: Int) -> Int? {
            let nextSectionIndex = currentSectionIndex + 1
            let nextSectionExists = nextSectionIndex < tableView.numberOfSections
            guard nextSectionExists else {
                // There is no next section.
                return nil
            }
            let numRowsInNextSection = tableView.numberOfRows(inSection: nextSectionIndex)
            if numRowsInNextSection > 0 {
                return nextSectionIndex
            } else {
                // The section does not have any rows. Try next section (recurse)
                return indexOfNextSectionContainingRows(from: nextSectionIndex)
            }
        }
        guard let idxPathOfCurrentlyFocusedCell = tableView.indexPath(for: currentCell) else {
            Log.shared.errorAndCrash("`currentCell` is not known to tableview")
            return
        }
        let nextRowInSameSection = idxPathOfCurrentlyFocusedCell.row + 1
        let nextRowExistsInSection = nextRowInSameSection < tableView.numberOfRows(inSection: idxPathOfCurrentlyFocusedCell.section)
        var nextCellIndex: IndexPath? = nil
        if nextRowExistsInSection {
            nextCellIndex = IndexPath(row: nextRowInSameSection, section: idxPathOfCurrentlyFocusedCell.section)
        } else {
            // Try next section
            guard let indexOfNextSection = indexOfNextSectionContainingRows(from: idxPathOfCurrentlyFocusedCell.section)
            else {
                // There is no further section which contains rows, thus there is nothing to set
                // next focus to.
                return
            }
            let firstRowInNextSectionIdx = IndexPath(row: 0, section: indexOfNextSection)
            let rowExists = firstRowInNextSectionIdx.section < tableView.numberOfSections &&
                firstRowInNextSectionIdx.row < tableView.numberOfRows(inSection: firstRowInNextSectionIdx.section)
            if rowExists {
                nextCellIndex = firstRowInNextSectionIdx
            }
        }
        guard let next = nextCellIndex else {
            // There is no next cell.
            return
        }
        guard let nextCell = tableView.cellForRow(at: next) else {
            Log.shared.errorAndCrash("Unexpected! According to our previous computations, a cell must exists for this indexPath")
            return
        }
        if let focusableCell = nextCell as? TextViewContainingTableViewCell {
            focusableCell.setFocus()
        } else {
            // The next cell is not focuable. Skip forward (recurse)
            setFocusToNextCell(currentCell: nextCell)
        }
    }

    private func setFocusToPreviousCell(currentCell: UITableViewCell) {

        // Finds the first previous section that contains rows
        func indexOfPreviousSectionContainingRows(from currentSectionIndex: Int) -> Int? {
            let previousSectionIndex = currentSectionIndex - 1
            let previousSectionExists =
                previousSectionIndex < tableView.numberOfSections && previousSectionIndex >= 0
            guard previousSectionExists else {
                // There is no next section.
                return nil
            }
            let numRowsInPreviousSection = tableView.numberOfRows(inSection: previousSectionIndex)
            if numRowsInPreviousSection > 0 {
                return previousSectionIndex
            } else {
                // The section does not have any rows. Try next section (recurse)
                return indexOfPreviousSectionContainingRows(from: previousSectionIndex)
            }
        }

        guard let idxPathOfCurrentlyFocusedCell = tableView.indexPath(for: currentCell) else {
            Log.shared.errorAndCrash("`currentCell` is not known to tableview")
            return
        }
        let previosRowInSameSection = idxPathOfCurrentlyFocusedCell.row - 1
        let previousRowExistsInSection =
            previosRowInSameSection < tableView.numberOfRows(inSection: idxPathOfCurrentlyFocusedCell.section)
            && previosRowInSameSection >= 0
        var previousCellIndex: IndexPath? = nil
        if previousRowExistsInSection {
            previousCellIndex = IndexPath(row: previosRowInSameSection,
                                          section: idxPathOfCurrentlyFocusedCell.section)
        } else {
            // Try previous section section
            guard let previousSectionIdx =
                    indexOfPreviousSectionContainingRows(from: idxPathOfCurrentlyFocusedCell.section)
            else {
                // There is no further section which contains rows, thus there is nothing to set
                // next focus to.
                return
            }
            let lastRowInPreviousSection = tableView.numberOfRows(inSection: previousSectionIdx) - 1
            let rowExists = lastRowInPreviousSection >= 0
            guard rowExists else {
                Log.shared.info("there are no rows in previous section, thus there is no previous field to set focus to")
                return
            }
            let lastRowInPreviousSectionIdx = IndexPath(row: lastRowInPreviousSection,
                                                        section: previousSectionIdx)
            previousCellIndex = lastRowInPreviousSectionIdx
        }
        guard let previous = previousCellIndex else {
            // There is no next cell.
            return
        }
        guard let previousCell = tableView.cellForRow(at: previous) else {
            Log.shared.errorAndCrash("Unexpected! According to our previous computations, a cell must exists for this indexPath")
            return
        }
        if let focusableCell = previousCell as? TextViewContainingTableViewCell {
            focusableCell.setFocus()
        } else {
            // The previous cell is not focuable. Skip forward (recurse)
            setFocusToPreviousCell(currentCell: previousCell)
        }
    }

    /// Finds the view that is the firstResponder, searching downward the view-hirarchy (the given views and its subviews, recursively).
    /// - Parameter view: view to start searching the view-hirarchy from
    /// - Returns:      view that is the firstResponder if any.
    ///                 `nil` otherwize
    private func currentFirstResponder(inSubviewsOf view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }
        if view.subviews.isEmpty {
            return nil
        }
        for subview in view.subviews {
            if subview.isFirstResponder {
                return subview
            } else if let recursedFound = currentFirstResponder(inSubviewsOf: subview){
                return recursedFound
            }
        }
        return nil
    }

    /// Finds and returns the first superview (of the given view) in the view hirarchy that is of
    /// type UITableViewCell.
    /// Use case:
    /// You have a UITextfield and need to know which UITableViewCell owns it (e.g. you have the current firstResponder, who is considered a UITextView, and need the cell to figure out the next field to jump to)
    /// - Parameter view: view to go up in view hirarchy for
    /// - Returns:      the first UITableViewCell found going up the view-hirarchy.
    ///             `   nil` if none could be found.
    private func findSuperviewThatIsACell(of view: UIView) -> UITableViewCell? {

        if let cell = view as? UITableViewCell {
            return cell
        }
        guard let superview = view.superview else {
            // End recursion. We are on the top of the view hirarchy
            return nil
        }
        if let cell = superview as? UITableViewCell {
            return cell
        }
        return findSuperviewThatIsACell(of: superview)
    }

    @objc
    func jumpToNextField(command: UIKeyCommand) {
        guard let currentResponder = currentFirstResponder(inSubviewsOf: view) else {
            // No cell is currently focused. So there is no "next cell" to set focus to.
            // Do nothing.
            return
        }
        if let focusedCell = findSuperviewThatIsACell(of: currentResponder) {
            setFocusToNextCell(currentCell: focusedCell)
        } else {
            Log.shared.info("No cell is currently focused. So there is no \"next cell\" to set focus to.")
            // Do nothing.
        }
    }

    @objc
    func jumpToPreviousField(command: UIKeyCommand) {
        guard let currentResponder = currentFirstResponder(inSubviewsOf: view) else {
            // No cell is currently focused. So there is no "next cell" to set focus to.
            // Do nothing.
            return
        }
        if let focusedCell = findSuperviewThatIsACell(of: currentResponder) {
            setFocusToPreviousCell(currentCell: focusedCell)
        } else {
            Log.shared.info("No cell is currently focused. So there is no \"next cell\" to set focus to.")
            // Do nothing.
        }
    }
    //

    private func setInitialFocus() {
        guard !isInitialFocusSet else {
            // We want to init once only
            return
        }
        isInitialFocusSet = true
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        let idxPath = vm.initialFocus()
        guard let cellToFocus = tableView.cellForRow(at: idxPath)
            as? TextViewContainingTableViewCell else {
                // This (no tableView.cellForRowAt...) can happen. Ignore
                return
        }
        cellToFocus.setFocus()
    }

    private func setPreviousFocusAfterPicker() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        let idxPath = vm.beforeDocumentAttachmentPickerFocus()
        guard let cellToFocus = tableView.cellForRow(at: idxPath)
            as? TextViewContainingTableViewCell else {
                Log.shared.errorAndCrash("Error casting")
                return
        }
        cellToFocus.setFocus()
    }

    private func isLastRow(indexPath: IndexPath) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return false
        }
        let idxLastSection = vm.sections.count - 1
        return indexPath.section == idxLastSection &&
            indexPath.row == vm.sections[idxLastSection].rows.count - 1
    }
}

// MARK: - Cancel UIAlertController

extension ComposeViewController {

    private func showAlertControllerWithOptionsForCanceling(sender: Any) {
        let actionSheetController = UIUtils.actionSheet()
        if let popoverPresentationController = actionSheetController.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender as? UIBarButtonItem
        }
        actionSheetController.addAction(cancelAction(forAlertController: actionSheetController))
        actionSheetController.addAction(deleteAction(forAlertController: actionSheetController))
        actionSheetController.addAction(saveAction(forAlertController: actionSheetController))
        if viewModel?.showKeepInOutbox ?? false {
            actionSheetController.addAction(
                keepInOutboxAction(forAlertController: actionSheetController))
        }
        present(actionSheetController, animated: true)
    }

    private func deleteAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UIAlertAction()
        }
        let text = vm.deleteActionTitle
        let action = UIUtils.action(text, .destructive) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.dismiss()
        }
        return action
    }

    private func saveAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UIAlertAction()
        }
        let text = vm.saveActionTitle
        let action = UIUtils.action(text, .default) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            vm.handleSaveActionTriggered()
            me.dismiss()
        }
        return action
    }

    private func keepInOutboxAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UIAlertAction()
        }
        let text = vm.keepInOutboxActionTitle
        let action = UIUtils.action(text, .default) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.dismiss()
        }
        return action
    }

    private func cancelAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UIAlertAction()
        }
        return UIUtils.action(vm.cancelActionTitle, .cancel)
    }
}

// MARK: - Keyboard Related Issues

extension ComposeViewController {

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardDidShow),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardDidHide),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
    }

    @objc
    private func handleKeyboardDidShow(notification: NSNotification) {
        tableView.contentInset.bottom =  keyBoardHeight(notification: notification)
    }

    @objc
    private func handleKeyboardDidHide(notification: NSNotification) {
        tableView.contentInset.bottom = 0.0
    }

    private func keyBoardHeight(notification: NSNotification) -> CGFloat {
        guard let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return 0
        }

        return keyboardSize.height
    }
}

extension ComposeViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                // Do not reload. There might be content written!
                if traitCollection.userInterfaceStyle == .dark {
                    tableView.backgroundColor = .secondarySystemBackground
                } else {
                    tableView.backgroundColor = .white
                }
            }
        } else {
            tableView.backgroundColor = .white
        }
    }
}
