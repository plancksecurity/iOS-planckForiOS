//
//  ComposeTableViewController.swift
//  pEp
//
//  Created by Andreas Buff on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel
import SwipeCellKit
import Photos
import pEpIOSToolbox

class ComposeTableViewController: BaseTableViewController {
    @IBOutlet var sendButton: UIBarButtonItem!

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

    var viewModel: ComposeViewModel? {
        didSet {
            // Make sure we are the delegate. Always.
            viewModel?.delegate = self
            tableView.reloadData()
        }
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        if viewModel == nil {
            setupModel()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupRecipientSuggestionsTableViewController()
        viewModel?.handleDidReAppear()
    }

    // MARK: - Setup & Configuration

    private func setupView() {
        registerXibs()
        tableView.rowHeight = UITableView.automaticDimension
         //An arbitrary value auto resize seems to require for some reason.
        tableView.estimatedRowHeight = 1000
    }

    private func setupModel() {
        viewModel = ComposeViewModel()
    }

    private final func setupRecipientSuggestionsTableViewController() {
        let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: nil)
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
        suggestionsChildViewController?.appConfig = appConfig
        suggestionsChildViewController?.viewModel = vm.suggestViewModel()
        addChild(suggestVc)
        suggestView.isHidden = true
        tableView.addSubview(suggestView)
    }

    // MARK: - IBActions

    @IBAction func cancel(_ sender: Any) {
        if viewModel?.showCancelActions ?? false {
            showAlertControllerWithOptionsForCanceling(sender: sender)
        } else {
            dismiss()
        }
    }

    @IBAction func send() {
        viewModel?.handleUserClickedSendButton()
    }
}

// MARK: - PEP Color View

extension ComposeTableViewController {
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
                // Valid case. We might havebeen dismissed already.
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

        let actionSheetController = UIAlertController.pEpAlertController(preferredStyle: .actionSheet)
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
                                        Log.shared.errorAndCrash(message: "lost myself")
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
                // Valid case. We might havebeen dismissed already.
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

extension ComposeTableViewController: ComposeViewModelDelegate {

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
            if cell.textView.text == "" {
                cell.textView.text = " "
            }
            setInitialFocus()
            cell.textView.sizeToFit()
            // We call this function only when focus is set (not before that)
            scrollUtil.layoutAfterTextDidChange(tableView: tableView, textView: cell.textView)
        } else {
            // We intentionally do not scroll recipinet fields (causes issues).
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

extension ComposeTableViewController: SegueHandlerType {

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

            destination.appConfig = appConfig
            guard let trustManagementViewModel = vm.trustManagementViewModel() else {
                Log.shared.error("Message not found")
                return
            }
            destination.viewModel = trustManagementViewModel
        }
    }
}

// MARK: - Address Suggestions

extension ComposeTableViewController {
    private final func updateSuggestTable(suggestionsForCellAt indexPath: IndexPath) {
        let rectCell = tableView.rectForRow(at: indexPath)
        let position = rectCell.origin.y + rectCell.height
        suggestionsChildViewController?.view.frame.origin.y = position
        suggestionsChildViewController?.view.frame.size.height =
            tableView.bounds.size.height - position
    }
}

// MARK: - MediaAttachmentPickerProvider

extension ComposeTableViewController {

    private func presentMediaAttachmentPickerProvider() {
        let media = Capability.media
        media.requestAndInformUserInErrorCase(viewController: self)  {
            [weak self] (permissionsGranted: Bool, error: Capability.AccessError?) in
            guard permissionsGranted else {
                return
            }
            guard let me = self,
            let picker = me.mediaAttachmentPickerProvider?.imagePicker else {
                Log.shared.errorAndCrash("Lost somthing")
                return
            }
            me.present(picker, animated: true)
        }
    }
}

// MARK: - DocumentAttachmentPickerViewController

extension ComposeTableViewController {
    private func presentDocumentAttachmentPicker() {
        present(documentAttachmentPicker, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension ComposeTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.sections.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView,
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

extension ComposeTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel?.handleUserSelectedRow(at: indexPath)
    }
}

// MARK: - XIBs

extension ComposeTableViewController {
    private func registerXibs() {
        let nib = UINib(nibName: AttachmentCell.reuseId, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: AttachmentCell.reuseId)
    }
}

// MARK: - SwipeAction

extension ComposeTableViewController {
    // MARK: - SwipeTableViewCell

    private func deleteAction(forCellAt indexPath: IndexPath) {
        tableView.beginUpdates()
        viewModel?.handleRemovedRow(at: indexPath)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
}

// MARK: - SwipeTableViewCellDelegate

extension ComposeTableViewController: SwipeTableViewCellDelegate {

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
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }
            me.deleteAction(forCellAt: indexPath)
        }
        deleteAction.title = NSLocalizedString("Remove", comment:
            "ComposeTableView: Label of swipe left. Removing of attachment."
        )
        deleteAction.backgroundColor = SwipeActionDescriptor.trash.color
        return (orientation == .right ?   [deleteAction] : nil)
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        if isLastRow(indexPath: indexPath) {
            // The last cell is not yet displayed (as we are in "willDisplay ..."), thus async.
            DispatchQueue.main.async { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost MySelf")
                    return
                }
                me.setInitialFocus()
            }
        }
    }
}

// MARK: - First Responder / Focus

extension ComposeTableViewController {

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
        let idxPath = vm.beforePickerFocus()
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

extension ComposeTableViewController {

    private func showAlertControllerWithOptionsForCanceling(sender: Any) {
        let actionSheetController = UIAlertController.pEpAlertController(preferredStyle: .actionSheet)
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
        let action: UIAlertAction
        let text = vm.deleteActionTitle
        action = ac.action(text, .destructive) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
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
        let action: UIAlertAction
        let text = vm.saveActionTitle
        action = ac.action(text, .default) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
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
        let action: UIAlertAction
        let text = vm.keepInOutboxActionTitle
        action = ac.action(text, .default) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
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
        return ac.action(vm.cancelActionTitle, .cancel)
    }
}
