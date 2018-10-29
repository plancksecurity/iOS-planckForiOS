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

class ComposeTableViewController: BaseTableViewController {
    @IBOutlet var sendButton: UIBarButtonItem!

    private var suggestionsChildViewController: SuggestTableViewController?
    lazy private var mediaAttachmentPickerProvider: MediaAttachmentPickerProvider? = {
        guard let pickerVm = viewModel?.mediaAttachmentPickerProviderViewModel() else {
            Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
            return nil
        }
        return MediaAttachmentPickerProvider(with: pickerVm)
    }()
    lazy private var documentAttachmentPicker: DocumentAttachmentPickerViewController = {
        return DocumentAttachmentPickerViewController(
            viewModel: viewModel?.documentAttachmentPickerViewModel())
    }()

    private var isInitialSetup = true
    private var currentCellIndexPath: IndexPath?
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
    }

    // MARK: - Setup & Configuration

    private func setupView() {
        registerXibs()
        tableView.rowHeight = UITableViewAutomaticDimension
         //IOS-1369 an arbitrary value auto resize seems to require for some reason.
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
                Log.shared.errorAndCrash(component: #function, errorString: "No VC.")
                return
        }
        suggestionsChildViewController = suggestVc
        suggestionsChildViewController?.appConfig = appConfig
        suggestionsChildViewController?.viewModel = vm.suggestViewModel()
        addChildViewController(suggestVc)
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

    func dismiss() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func send() {
        viewModel?.handleUserClickedSendButton()
        dismiss()
    }
}

// MARK: - PEP Color View

extension ComposeTableViewController {
    private func setupPepColorView(for pEpRating: PEP_rating, pEpProtected: Bool) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return
        }

        //IOS-1369: Not so nice. The view(controller) should not know about state and protection.
        if let view = showPepRating(pEpRating: pEpRating, pEpProtection: pEpProtected) {
            if vm.state.canHandshake() || vm.state.canToggleProtection() {
                let tapGestureRecognizer = UITapGestureRecognizer(
                    target: self,
                    action: #selector(actionHandshakeOrForceUnprotected))
                view.addGestureRecognizer(tapGestureRecognizer)
            }
        }
    }

    /// Shows a menu where user can choose to make a handshake, or toggle force unprotected.
    @objc func actionHandshakeOrForceUnprotected(gestureRecognizer: UITapGestureRecognizer) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return
        }
        let theCanHandshake = vm.state.canHandshake()
        let theCanToggleProtection = vm.state.canToggleProtection()

        if theCanHandshake || theCanToggleProtection {
            let alert = UIAlertController.pEpAlertController()

            if theCanHandshake {
                let actionReply = UIAlertAction(
                    title: NSLocalizedString("Handshake",
                                             comment: "possible privacy status action"),
                    style: .default) {[weak self] (action) in
                        self?.performSegue(withIdentifier: .segueHandshake, sender: self)
                }
                alert.addAction(actionReply)
            }

            if theCanToggleProtection {
                let originalValueOfProtection = vm.state.pEpProtection
                let title = vm.state.pEpProtection ?
                    NSLocalizedString("Disable Protection",
                                      comment: "possible private status action") :
                    NSLocalizedString("Enable Protection",
                                      comment: "possible private status action")
                let actionToggleProtection = UIAlertAction(
                    title: title,
                    style: .default) { (action) in
                        vm.handleUserChangedProtectionStatus(to: !originalValueOfProtection)
                }
                alert.addAction(actionToggleProtection)
            }

            let cancelAction = UIAlertAction(
                title: NSLocalizedString("Cancel", comment: "possible private status action"),
                style: .cancel) { (action) in }
            alert.addAction(cancelAction)

            present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - ComposeViewModelDelegate

extension ComposeTableViewController: ComposeViewModelDelegate {

    func hideSuggestions() {
        suggestionsChildViewController?.view.isHidden = true
    }

    func showSuggestions(forRowAt indexPath: IndexPath) {
        suggestionsChildViewController?.view.isHidden = false
        updateSuggestTable(suggestionsForCellAt: indexPath)
    }

    func validatedStateChanged(to isValidated: Bool) {
        sendButton.isEnabled = isValidated
    }

    func contentChanged(inRowAt indexPath: IndexPath) {
        //IOS-1369: indexPath currently unused.
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

    func colorBatchNeedsUpdate(for rating: PEP_rating, protectionEnabled: Bool) {
        setupPepColorView(for: rating, pEpProtected: protectionEnabled)
    }

    func showMediaAttachmentPicker() {
        presentMediaAttachmentPickerProvider()
    }

    func hideMediaAttachmentPicker() {
        mediaAttachmentPickerProvider?.imagePicker.dismiss(animated: true)
    }

    func showDocumentAttachmentPicker() {
        presentDocumentAttachmentPicker()
    }
}

// MARK: - SegueHandlerType

extension ComposeTableViewController: SegueHandlerType {

    enum SegueIdentifier: String {
        case segueHandshake
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueHandshake:
            guard
                let nc = segue.destination as? UINavigationController,
                let destination = nc.rootViewController as? HandshakeViewController else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return
            }
            destination.appConfig = appConfig
            viewModel?.setup(handshakeViewController: destination)
        }
    }

    //IOS-1369: I can not think of a use case for this. Remove if obsolete.
//    @IBAction func segueUnwindAccountAdded(segue: UIStoryboardSegue) {
//        // nothing to do.
//    }
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
                Log.shared.errorAndCrash(component: #function, errorString: "Lost somthing")
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
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return 0
        }
        return vm.sections.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return 0
        }
        return vm.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = setupCellForIndexPath(indexPath, in: tableView)
        return cell!
    }

    private func setupCellForIndexPath(_ indexPath: IndexPath,
                                  in tableView: UITableView) -> UITableViewCell? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
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
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                    return nil
            }
            cell.setup(with: rowVm)
            result = cell
        } else if section.type == .wrapped {
            result = tableView.dequeueReusableCell(withIdentifier: "WrappedCell")
        } else if section.type == .account {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell_mvvm.reuseId)
                    as? AccountCell_mvvm,
                let rowVm = section.rows[indexPath.row] as? AccountCellViewModel
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
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
                        Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
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
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
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
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
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
        viewModel?.handleRemovedRow(at: indexPath)
        tableView.beginUpdates()
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
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
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
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return UIAlertAction()
        }
        let action: UIAlertAction
        let text = vm.deleteActionTitle
        action = ac.action(text, .destructive) {[weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            vm.handleDeleteActionTriggered()
            me.dismiss()
        }
        return action
    }

    private func saveAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return UIAlertAction()
        }
        let action: UIAlertAction
        let text = vm.saveActionTitle
        action = ac.action(text, .default) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            vm.handleSaveActionTriggered()
            me.dismiss()
        }
        return action
    }

    private func keepInOutboxAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return UIAlertAction()
        }
        let action: UIAlertAction
        let text = vm.keepInOutboxActionTitle
        action = ac.action(text, .default) {[weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            me.dismiss()
        }
        return action
    }

    private func cancelAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return UIAlertAction()
        }
        return ac.action(vm.cancelActionTitle, .cancel)
    }
}

/*
 func add(nonInlinedAttachment attachment: Attachment) {
 let indexInserted = nonInlinedAttachmentData.add(attachment: attachment)
 let indexPath = IndexPath(row: indexInserted, section: attachmentSection)
 tableView.beginUpdates()
 tableView.insertRows(at: [indexPath], with: .automatic)
 tableView.endUpdates()
 }


 // MARK: - SwipeTableViewCellDelegate

 extension ComposeTableViewController_Old: SwipeTableViewCellDelegate {

 func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath,
 for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
 guard indexPath.section == attachmentSection else {
 return nil
 }
 let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
 self.deleteAction(forCellAt: indexPath)
 }
 configure(action: deleteAction, with: .trash)
 return (orientation == .right ?   [deleteAction] : nil)
 }
 }
 

 // MARK: - SwipeTableViewCell

 private func deleteAction(forCellAt indexPath: IndexPath) {
 guard indexPath.section == attachmentSection else {
 Log.shared.errorAndCrash(component: #function,
 errorString: "only attachments have delete actions")
 return
 }
 nonInlinedAttachmentData.remove(at: indexPath.row)
 tableView.beginUpdates()
 tableView.deleteRows(at: [indexPath], with: .automatic)
 tableView.endUpdates()
 }

 private func configure(action: SwipeAction, with descriptor: SwipeActionDescriptor) {
 action.title = NSLocalizedString("Remove", comment:
 "ComposeTableView: Label of swipe left. Removing of attachment."
 )
 action.backgroundColor = descriptor.color
 }
 */
