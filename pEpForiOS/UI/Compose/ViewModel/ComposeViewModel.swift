//
//  ComposeViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox
import PEPObjCAdapterFramework

/// Informs the one that triggered the segued to here.
protocol ComposeViewModelResultDelegate: class {
    /// Called after a valid mail has been composed and saved for sending.
    func composeViewModelDidComposeNewMail(message: Message)
    /// Called after saving a modified version of the original message.
    /// (E.g. after editing a drafted message)
    func composeViewModelDidModifyMessage(message: Message)
    /// Called after permanentaly deleting the original message.
    /// (E.g. saving an edited oubox mail to drafts. It's permanentaly deleted from outbox.)
    func composeViewModelDidDeleteMessage(message: Message)
}

protocol ComposeViewModelDelegate: class {

    /// Called when the user changes the content of a row.
    /// E.g. edited the subject.
    ///
    /// - Parameter indexPath: indexPath of changed row
    func contentChanged(inRowAt indexPath: IndexPath)

    func focusSwitched()

    /// The status of whether or not the message has been validated for sending changed.
    ///
    /// - Parameter isValidated: new value
    func validatedStateChanged(to isValidated: Bool)

    /// The model changed / has been resetted
    func modelChanged()

    func sectionChanged(section: Int)

    func colorBatchNeedsUpdate(for rating: PEPRating, protectionEnabled: Bool)

    func hideSuggestions()

    func showSuggestions(forRowAt indexPath: IndexPath)

    func suggestions(haveScrollFocus: Bool)

    func showMediaAttachmentPicker()

    func hideMediaAttachmentPicker()

    func showDocumentAttachmentPicker()

    func documentAttachmentPickerDone()
}

class ComposeViewModel {
    weak var resultDelegate: ComposeViewModelResultDelegate?
    weak var delegate: ComposeViewModelDelegate? {
        didSet {
            delegate?.colorBatchNeedsUpdate(for: state.rating,
                                            protectionEnabled: state.pEpProtection)
        }
    }
    public private(set) var sections = [ComposeViewModel.Section]()
    public private(set) var state: ComposeViewModelState

    private var suggestionsVM: SuggestViewModel?
    private var lastRowWithSuggestions: IndexPath?
    private var indexPathBodyVm: IndexPath {
        let bodySection = section(for: .body)
        guard
            let vm = bodySection?.rows.first,
            let body = indexPath(for: vm) else {
                Log.shared.errorAndCrash("No body")
                return IndexPath(row: 0, section: 0)
        }
        return body
    }

    init(resultDelegate: ComposeViewModelResultDelegate? = nil,
         composeMode: ComposeUtil.ComposeMode? = nil,
         prefilledTo: Identity? = nil,
         prefilledFrom: Identity? = nil,
         originalMessage: Message? = nil) {
        self.resultDelegate = resultDelegate
        let initData = InitData(withPrefilledToRecipient: prefilledTo,
                                prefilledFromSender: prefilledFrom,
                                orForOriginalMessage: originalMessage,
                                composeMode: composeMode)
        self.state = ComposeViewModelState(initData: initData)
        self.state.delegate = self
        setup()
    }

    public func handleDidReAppear() {
        state.validate()
    }

    public func viewModel(for indexPath: IndexPath) -> CellViewModel {
        return sections[indexPath.section].rows[indexPath.row]
    }

    public func initialFocus() -> IndexPath {
        if state.initData?.toRecipients.isEmpty ?? false {
            let to = IndexPath(row: 0, section: 0)
            return to
        } else {
            return indexPathBodyVm
        }
    }

    public func beforePickerFocus() -> IndexPath {
        return indexPathBodyVm
    }

    public func handleUserSelectedRow(at indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if section.type == .wrapped {
            state.setBccUnwrapped()
            unwrapRecipientSection()
        }
    }

    public func handleUserChangedProtectionStatus(to protected: Bool) {
        state.pEpProtection = protected
    }

    public func handleUserClickedSendButton() {
        guard let msg = ComposeUtil.messageToSend(withDataFrom: state) else {
            Log.shared.warn("No message for sending")
            return
        }
        msg.save()
        // The user crafted a new message. We must persist that.
//        Session.saveToDisk()
        guard let data = state.initData else {
            Log.shared.errorAndCrash("No data")
            return
        }
        if data.isDraftsOrOutbox {
            // From user perspective, we have edited a drafted message and will send it.
            // Technically we are creating and sending a new message (msg), thus we have to
            // delete the original, previously drafted one.
            deleteOriginalMessage()
        }
        resultDelegate?.composeViewModelDidComposeNewMail(message: msg)
    }

    public func isAttachmentSection(indexPath: IndexPath) -> Bool {
        return sections[indexPath.section].type == .attachments
    }

    public func handleRemovedRow(at indexPath: IndexPath) {
        guard let removeeVM = viewModel(for: indexPath) as? AttachmentViewModel else {
            Log.shared.errorAndCrash("Only attachmnets can be removed by the user")
            return
        }
        removeNonInlinedAttachment(removeeVM.attachment)
    }

    private func deleteOriginalMessage() {
        guard let data = state.initData else {
            Log.shared.errorAndCrash("No data")
            return
        }
        guard let om = data.originalMessage else {
            // That might happen. Message might be sent already and thus has been moved to
            // Sent folder.
            return
        }
        // Make sure the "draft" flag is not set to avoid the original msg will keep in virtual
        // mailboxes, that show all flagged messages.
        om.imapFlags.draft = false
        om.imapMarkDeleted()
        resultDelegate?.composeViewModelDidDeleteMessage(message: om)
    }

    private func setup() {
        resetSections()
    }

    private func existsDirtyCell() -> Bool {
        for section in sections where section.type == .recipients {
            for row  in section.rows where row is RecipientCellViewModel {
                guard let recipientVM = row as? RecipientCellViewModel else {
                    Log.shared.errorAndCrash("Cast error")
                    return false
                }
                if recipientVM.isDirty {
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - ComposeViewModelStateDelegate

extension ComposeViewModel: ComposeViewModelStateDelegate {

    func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
                               didChangeValidationStateTo isValid: Bool) {
        let userSeemsTyping = existsDirtyCell()
        delegate?.validatedStateChanged(to: isValid && !userSeemsTyping)
    }

    func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
                               didChangePEPRatingTo newRating: PEPRating) {
        delegate?.colorBatchNeedsUpdate(for: newRating, protectionEnabled: state.pEpProtection)
    }

    func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
                               didChangeProtection newValue: Bool) {
        delegate?.colorBatchNeedsUpdate(for: state.rating, protectionEnabled: newValue)
    }
}

// MARK: - CellViewModels

extension ComposeViewModel {
    class Section {
        enum SectionType: CaseIterable {
            case recipients, wrapped, account, subject, body, attachments
        }
        let type: SectionType
        fileprivate(set) public var rows = [CellViewModel]()

        init?(type: SectionType,
              for state: ComposeViewModelState,
              cellVmDelegate: ComposeViewModel?) {
            self.type = type
            setupViewModels(cellVmDelegate: cellVmDelegate, for: state)
            if rows.count == 0 {
                // We want to show non-empty sections only
                return nil
            }
        }

        private func setupViewModels(cellVmDelegate: ComposeViewModel?,
                                     for state: ComposeViewModelState?) {
            rows = [CellViewModel]()
            let isWrapped = state?.bccWrapped ?? false
            let hasCcOrBcc = (state?.ccRecipients.count ?? 0 > 0) ||
                (state?.bccRecipients.count ?? 0 > 0)
            switch type {
            case .recipients:
                rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate,
                                                   type: .to,
                                                   recipients: state?.toRecipients ?? []))
                if !isWrapped || hasCcOrBcc {
                    rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate,
                                                       type: .cc,
                                                       recipients: state?.ccRecipients ?? []))
                    rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate,
                                                       type: .bcc,
                                                       recipients: state?.bccRecipients ?? []))
                }
            case .wrapped:
                if isWrapped && !hasCcOrBcc {
                    rows.append(WrappedBccViewModel())
                }
            case .account:
                if Account.all().count == 1 {
                    // Accountpicker only for multi account setup
                    break
                }
                var fromAccount: Account? = nil
                if let fromIdentity = state?.from {
                    fromAccount = Account.by(address: fromIdentity.address)
                }
                let rowModel = AccountCellViewModel(resultDelegate: cellVmDelegate,
                                                    initialAccount: fromAccount)
                rows.append(rowModel)
            case .subject:
                let rowModel = SubjectCellViewModel(resultDelegate: cellVmDelegate)
                if let subject = state?.subject {
                    rowModel.content = subject
                }
                rows.append(rowModel)
            case .body:
                rows.append(BodyCellViewModel(resultDelegate: cellVmDelegate,
                                              initialPlaintext: state?.initData?.bodyPlaintext,
                                              initialAttributedText: state?.initData?.bodyHtml,
                                              inlinedAttachments: state?.initData?.inlinedAttachments))
            case .attachments:
                for att in state?.nonInlinedAttachments ?? [] {
                    rows.append(AttachmentViewModel(attachment: att))
                }
            }
        }
    }

    private func resetSections() {
        var newSections = [ComposeViewModel.Section]()
        for type in ComposeViewModel.Section.SectionType.allCases {
            if let section = ComposeViewModel.Section(type: type,
                                                      for: state,
                                                      cellVmDelegate: self) {
                newSections.append(section)
            }
        }
        self.sections = newSections
        delegate?.modelChanged()
    }

    private func unwrapRecipientSection() {
        let maybeWrappedIdx = 1
        if sections[maybeWrappedIdx].type == .wrapped {
            let wrappedSection = sections[maybeWrappedIdx]
            wrappedSection.rows.removeAll()
            delegate?.sectionChanged(section: maybeWrappedIdx)
        }
        // Add Cc and Bcc VMs

        let recipientsSection = section(for: .recipients)
        recipientsSection?.rows.append(RecipientCellViewModel(resultDelegate: self,
                                                              type: .cc,
                                                              recipients: []))
        recipientsSection?.rows.append(RecipientCellViewModel(resultDelegate: self,
                                                              type: .bcc,
                                                              recipients: []))
        let idxRecipients = 0
        delegate?.sectionChanged(section: idxRecipients)
    }

    private func index(ofSectionWithType type: ComposeViewModel.Section.SectionType) -> Int? {
        for i in 0..<sections.count {
            if sections[i].type == type {
                return i
            }
        }
        return nil
    }

    private func section(
        `for` type: ComposeViewModel.Section.SectionType) -> ComposeViewModel.Section? {
        for section in sections {
            if section.type == type {
                return section
            }
        }
        return nil
    }

    private func indexPath(for cellViewModel: CellViewModel) -> IndexPath? {
        for s in 0..<sections.count {
            let section = sections[s]
            for r in 0..<section.rows.count {
                let row = section.rows[r]
                if row === cellViewModel {
                    return IndexPath(row: r, section: s)
                }
            }
        }
        return nil
    }
}

// MARK: - Attachments

extension ComposeViewModel {
    private func removeNonInlinedAttachment(_ removee: Attachment) {
        guard let section = section(for: .attachments) else {
            Log.shared.errorAndCrash("Only attachmnets can be removed by the user")
            return
        }
        // Remove from section
        var newAttachmentVMs = [AttachmentViewModel]()
        for vm in section.rows {
            guard let aVM = vm as? AttachmentViewModel else {
                Log.shared.errorAndCrash("Error casting")
                return
            }
            if aVM.attachment != removee {
                newAttachmentVMs.append(aVM)
            }
        }
        section.rows = newAttachmentVMs
        // Remove from state
        var newNonInlinedAttachments = [Attachment]()
        for att in state.nonInlinedAttachments {
            if att != removee {
                newNonInlinedAttachments.append(att)
            }
        }
        state.nonInlinedAttachments = newNonInlinedAttachments
    }

    private func addNonInlinedAttachment(_ att: Attachment) {
        // Add to state
        state.nonInlinedAttachments.append(att)
        // add section
        if let existing = section(for: .attachments) {
            existing.rows.append(AttachmentViewModel(attachment: att))
        } else {
            guard let new = Section(type: .attachments, for: state, cellVmDelegate: self) else {
                Log.shared.errorAndCrash("Invalid state")
                return
            }
            sections.append(new)
        }
        if let attachmenttSection = index(ofSectionWithType: .attachments) {
            delegate?.sectionChanged(section: attachmenttSection)
        }
    }
}

// MARK: - Suggestions

extension ComposeViewModel {
    func suggestViewModel() -> SuggestViewModel {
        let createe = SuggestViewModel(resultDelegate: self)
        suggestionsVM = createe
        return createe
    }
}

extension ComposeViewModel: SuggestViewModelResultDelegate {
    func suggestViewModelDidSelectContact(identity: Identity) {
        guard
            let idxPath = lastRowWithSuggestions,
            let recipientVM = sections[idxPath.section].rows[idxPath.row] as? RecipientCellViewModel
            else {
                Log.shared.errorAndCrash("No row VM")
                return
        }
        recipientVM.add(recipient: identity)
    }

    func suggestViewModel(_ vm: SuggestViewModel, didToggleVisibilityTo newValue: Bool) {
        delegate?.suggestions(haveScrollFocus: newValue)
    }
}

// MARK: - DocumentAttachmentPickerViewModel[ResultDelegate]

extension ComposeViewModel {
    func documentAttachmentPickerViewModel() -> DocumentAttachmentPickerViewModel {
        return DocumentAttachmentPickerViewModel(resultDelegate: self)
    }
}

extension ComposeViewModel: DocumentAttachmentPickerViewModelResultDelegate {
    func documentAttachmentPickerViewModel(_ vm: DocumentAttachmentPickerViewModel,
                                           didPick attachment: Attachment) {
        addNonInlinedAttachment(attachment)
        delegate?.documentAttachmentPickerDone()
    }

    func documentAttachmentPickerViewModelDidCancel(_ vm: DocumentAttachmentPickerViewModel) {
        delegate?.documentAttachmentPickerDone()
    }
}

// MARK: - MediaAttachmentPickerProviderViewModel[ResultDelegate]

extension ComposeViewModel {
    func mediaAttachmentPickerProviderViewModel() -> MediaAttachmentPickerProviderViewModel {
        return MediaAttachmentPickerProviderViewModel(resultDelegate: self)
    }

    func mediaAttachmentPickerProviderViewModelDidCancel(
        _ vm: MediaAttachmentPickerProviderViewModel) {
        delegate?.hideMediaAttachmentPicker()
    }
}

extension ComposeViewModel: MediaAttachmentPickerProviderViewModelResultDelegate {

    func mediaAttachmentPickerProviderViewModel(
        _ vm: MediaAttachmentPickerProviderViewModel,
        didSelect mediaAttachment: MediaAttachmentPickerProviderViewModel.MediaAttachment) {
        if mediaAttachment.type == .image {
            guard let bodyViewModel = bodyVM else {
                Log.shared.errorAndCrash("No bodyVM. Maybe valid as picking is async.")
                return
            }
            bodyViewModel.inline(attachment: mediaAttachment.attachment)
        } else {
            addNonInlinedAttachment(mediaAttachment.attachment)
            delegate?.hideMediaAttachmentPicker()
        }
    }
}

// MARK: - Cancel Actions

extension ComposeViewModel {

    public var showKeepInOutbox: Bool {
        return state.initData?.isOutbox ?? false
    }

    public var showCancelActions: Bool {
        return existsDirtyCell() || state.edited
    }

    public var deleteActionTitle: String {
        guard let data = state.initData else {
            Log.shared.errorAndCrash("No data")
            return ""
        }
        let title: String
        if data.isDrafts {
            title = NSLocalizedString("Discharge changes", comment:
                "ComposeTableView: button to decide to discharge changes made on a drafted mail.")
        } else if data.isOutbox {
            title = NSLocalizedString("Delete", comment:
                "ComposeTableView: button to decide to delete a message from Outbox after " +
                "making changes.")
        } else {
            title = NSLocalizedString("Delete", comment: "compose email delete")
        }
        return title
    }

    public var saveActionTitle: String {
        guard let data = state.initData else {
            Log.shared.errorAndCrash("No data")
            return ""
        }
        let title: String
        if data.isDrafts {
            title = NSLocalizedString("Save changes", comment:
                "ComposeTableView: button to decide to save changes made on a drafted mail.")
        } else {
            title = NSLocalizedString("Save Draft", comment: "compose email save")
        }
        return title
    }

    public var keepInOutboxActionTitle: String {
        return NSLocalizedString("Keep in Outbox", comment:
            "ComposeTableView: button to decide to Discharge changes made on a mail in outbox.")
    }

    public var cancelActionTitle: String {
        return NSLocalizedString("Cancel", comment: "compose email cancel")
    }

    public func handleDeleteActionTriggered() {
        guard let data = state.initData else {
            Log.shared.errorAndCrash("No data")
            return
        }

        if data.isOutbox {
            data.originalMessage?.delete()
            if let message = data.originalMessage {
                resultDelegate?.composeViewModelDidDeleteMessage(message: message)
            }
        }
    }

    public func handleSaveActionTriggered() {
        guard let data = state.initData else {
            Log.shared.errorAndCrash("No data")
            return
        }
        if data.isDraftsOrOutbox {
            // We are in drafts folder and, from user perespective, are editing a drafted mail.
            // Technically we have to create a new one and delete the original message, as the
            // mail is already synced with the IMAP server and thus we must not modify it.
            deleteOriginalMessage()

            if data.isOutbox {
                // Message will be saved (moved from user perspective) to drafts, but we are in
                // outbox folder.
                if let message = data.originalMessage {
                    resultDelegate?.composeViewModelDidDeleteMessage(message: message)
                }
            }
        }

        guard let msg = ComposeUtil.messageToSend(withDataFrom: state) else {
            Log.shared.errorAndCrash("No message")
            return
        }
        let acc = msg.parent.account
        guard let f = Folder.by(account:acc, folderType: .drafts) else {
            Log.shared.errorAndCrash("No drafts")
            return
        }
        msg.parent = f
        msg.imapFlags.draft = true
        msg.sent = Date()
        Message.saveForAppend(msg: msg)
        if data.isDrafts {
            // We save a modified version of a drafted message. The UI might want to updtate
            // its model.
            if let message = data.originalMessage {
                resultDelegate?.composeViewModelDidModifyMessage(message: message)
            }
        }
    }
}

// MARK: - HandshakeViewModel

extension ComposeViewModel {
    // There is no view model for HandshakeViewController yet, thus we are setting up the VC itself
    // as a workaround to avoid letting the VC know MessageModel
    func setup(handshakeViewController: HandshakeViewController) {
        // We MUST use an independent Session here. We do not want the outer world to see it nor to
        //save somthinng from the state (Attachments, Identitie, ...) when saving the MainSession.
        let session = Session()
//        let safeState = state.makeSafe(forSession: session)
//        guard let msg = ComposeUtil.messageToSend(withDataFrom: safeState, session: session) else {
//            Log.shared.errorAndCrash("No message")
//            return
//        }
        handshakeViewController.session = session
        session.perform{ [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let safeState = me.state.makeSafe(forSession: session)
            guard let msg = ComposeUtil.messageToSend(withDataFrom: safeState) else {
                Log.shared.errorAndCrash("No message")
                return
            }
            handshakeViewController.message = msg
            let evaluator = RatingReEvaluator(message: msg)
            handshakeViewController.ratingReEvaluator = evaluator
        }
    }
}

// MARK: - Cell-ViewModel Delegates

// MARK: RecipientCellViewModelResultDelegate

extension ComposeViewModel: RecipientCellViewModelResultDelegate {

    func recipientCellViewModel(_ vm: RecipientCellViewModel,
                                didChangeRecipients newRecipients: [Identity]) {
        switch vm.type {
        case .to:
            state.toRecipients = newRecipients
        case .cc:
            state.ccRecipients = newRecipients
        case .bcc:
            state.bccRecipients = newRecipients
        }
    }

    func recipientCellViewModel(_ vm: RecipientCellViewModel, didBeginEditing text: String) {
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash("We got called by a non-existing VM?")
            return
        }
        lastRowWithSuggestions = idxPath
        delegate?.showSuggestions(forRowAt: idxPath)
        suggestionsVM?.updateSuggestion(searchString: text)
    }

    func recipientCellViewModelDidEndEditing(_ vm: RecipientCellViewModel) {
        state.validate()
        delegate?.focusSwitched()
        delegate?.hideSuggestions()
    }

    func recipientCellViewModel(_ vm: RecipientCellViewModel, textChanged newText: String) {
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash("We got called by a non-existing VM?")
            return
        }
        lastRowWithSuggestions = idxPath

        delegate?.contentChanged(inRowAt: idxPath)
        delegate?.showSuggestions(forRowAt: idxPath)
        suggestionsVM?.updateSuggestion(searchString: newText)
        state.validate()
    }
}

// MARK: AccountCellViewModelResultDelegate

extension ComposeViewModel: AccountCellViewModelResultDelegate {
    func accountCellViewModel(_ vm: AccountCellViewModel, accountChangedTo account: Account) {
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash("We got called by a non-existing VM?")
            return
        }
        state.from = account.user
        delegate?.contentChanged(inRowAt: idxPath)
    }
}

// MARK: SubjectCellViewModelResultDelegate

extension ComposeViewModel: SubjectCellViewModelResultDelegate {

    func subjectCellViewModelDidChangeSubject(_ vm: SubjectCellViewModel) {
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash("We got called by a non-existing VM?")
            return
        }
        state.subject = vm.content ?? ""
        delegate?.contentChanged(inRowAt: idxPath)
    }
}

// MARK: BodyCellViewModelResultDelegate

extension ComposeViewModel: BodyCellViewModelResultDelegate {

    var bodyVM: BodyCellViewModel? {
        for section in sections where section.type == .body {
            return section.rows.first as? BodyCellViewModel
        }
        return nil
    }

    func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel) {
        delegate?.showMediaAttachmentPicker()
    }

    func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel) {
        delegate?.showDocumentAttachmentPicker()
    }

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           inlinedAttachmentsChanged inlinedAttachments: [Attachment]) {
        state.inlinedAttachments = inlinedAttachments
        delegate?.hideMediaAttachmentPicker()
    }

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           bodyChangedToPlaintext plain: String,
                           html: String) {
        state.bodyHtml = html
        state.bodyPlaintext = plain
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash("We got called by a non-existing VM?")
            return
        }
        delegate?.contentChanged(inRowAt: idxPath)
    }
}
