//
//  ComposeViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

protocol ComposeViewModelDelegate: AnyObject {

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

    func colorBatchNeedsUpdate(for rating: Rating, protectionEnabled: Bool)

    func hideSuggestions()

    func showSuggestions(forRowAt indexPath: IndexPath)

    func suggestions(haveScrollFocus: Bool)

    func showMediaAttachmentPicker()

    func hideMediaAttachmentPicker()

    func showDocumentAttachmentPicker()

    func showContactsPicker()

    func documentAttachmentPickerDone()

    func showTwoButtonAlert(withTitle title: String,
                            message: String,
                            cancelButtonText: String,
                            positiveButtonText: String ,
                            cancelButtonAction: @escaping () -> Void,
                            positiveButtonAction: @escaping () -> Void)
    func dismiss()
}

/// Contains messages about cancelation and send.
protocol ComposeViewModelFinalActionDelegate: AnyObject {
    /// The user requested the mail to be sent.
    func userWantsToSend(message: Message)

    /// The user opted to send, but there were (internal)
    /// problems creating the message.
    func couldNotCreateOutgoingMessage()

    /// The user canceled the composing of the mail.
    func canceled()
}

class ComposeViewModel {
    weak var delegate: ComposeViewModelDelegate? {
        didSet {
            delegate?.colorBatchNeedsUpdate(for: state.rating,
                                            protectionEnabled: state.pEpProtection)
        }
    }

    /// Signals having sent or canceled.
    weak var composeViewModelEndActionDelegate: ComposeViewModelFinalActionDelegate?

    public private(set) var sections = [ComposeViewModel.Section]()
    public private(set) var state: ComposeViewModelState

    /// During normal execution, the app will ask the user to save a draft on cancel,
    /// which is not wanted when sharing a file.
    public let offerToSaveDraftOnCancel: Bool

    private var suggestionsVM: SuggestViewModel?
    private var lastRowWithSuggestions: IndexPath?

    /// IndexPath of "To:" receipientVM
    private var indexPathToVm: IndexPath {
        return IndexPath(item: 0, section: 0)
    }

    /// IndexPath of "Subject" VM
    private var indexPathSubjectVm: IndexPath {
        let subjectSection = section(for: .subject)
        guard
            let vm = subjectSection?.rows.first,
            let idxSubject = indexPath(for: vm)
        else {
            Log.shared.errorAndCrash("No Subject?")
            return IndexPath(row: 0, section: 0)
        }
        return idxSubject
    }

    /// Indicates if there are no active accounts. 
    public var hasNoActiveAccounts: Bool {
        return Account.all().count == 0
    }

    /// IndexPath of "Body" VM
    private var indexPathBodyVm: IndexPath {
        let bodySection = section(for: .body)
        guard
            let vm = bodySection?.rows.first,
            let body = indexPath(for: vm)
        else {
            Log.shared.errorAndCrash("No body")
            return IndexPath(row: 0, section: 0)
        }
        return body
    }

    /// Private session to use for attachments (and maybe others) that are dangling/invalid until a
    /// message to send is crafted. (E.g. attachments have message == nil, which is invalid and
    /// would thus crash if anone commits the main session.
    private let session = Session()

    init(state: ComposeViewModelState, offerToSaveDraftOnCancel: Bool = true) {
        self.state = state
        self.offerToSaveDraftOnCancel = offerToSaveDraftOnCancel
        self.state.delegate = self
        setup()
    }

    convenience init(composeMode: ComposeUtil.ComposeMode? = nil,
                     prefilledTo: Identity? = nil,
                     prefilledFrom: Identity? = nil,
                     originalMessage: Message? = nil) {
        let initData = InitData(prefilledTo: prefilledTo,
                                prefilledFrom: prefilledFrom,
                                originalMessage: originalMessage,
                                composeMode: composeMode)
        let state = ComposeViewModelState(initData: initData)
        self.init(state: state)
    }

    convenience init(prefilledFromAddress: String) {
        let prefilledFrom = Identity(address: prefilledFromAddress)
        let initData = InitData(prefilledTo: nil,
                                prefilledFrom: prefilledFrom,
                                originalMessage: nil,
                                composeMode: nil)
        let state = ComposeViewModelState(initData: initData)
        self.init(state: state)
    }

    public func handleDidReAppear() {
        state.validate()
    }

    public func viewModel(for indexPath: IndexPath) -> CellViewModel {
        return sections[indexPath.section].rows[indexPath.row]
    }

    /// - returns: the indexpath of the cell to set focus the to.
    public func initialFocus() -> IndexPath {
        if state.initData?.toRecipients.isEmpty ?? false {
            // Use cases: new mail or forward (no To: prefilled)
            return indexPathToVm
        } else if state.subject.isEmpty || state.subject.isOnlyWhiteSpace(){
            if let composeMode = state.initData?.composeMode,
               (composeMode == .replyFrom || composeMode == .replyAll) {
                // When replying a mail we always want the cursor in body, even the subject is empty
                return indexPathBodyVm            }
            // Use case: open compose by clicking mailto: link
            return indexPathSubjectVm
        } else {
            // Use case: reply a mail (to and subject are set)
            return indexPathBodyVm
        }
    }

    public func beforeDocumentAttachmentPickerFocus() -> IndexPath {
        return indexPathBodyVm
    }

    public func beforeContactsPickerFocus() -> IndexPath {
        return lastRowWithSuggestions ?? indexPathBodyVm
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

    public func handleUserClickedCancelButton() {
        composeViewModelEndActionDelegate?.canceled()
    }

    public func handleUserClickedSendButton() {
        rollbackMainSession()
        let safeState = state.makeSafe(forSession: Session.main)
        let sendClosure: (() -> Message?) = { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return nil
            }

            guard let msg = ComposeUtil.messageToSend(withDataFrom: safeState) else {
                Log.shared.warn("No message for sending")
                return nil
            }

            msg.sent = Date()
            msg.session.commit()

            guard let data = me.state.initData else {
                Log.shared.errorAndCrash("No data")
                return msg
            }
            if data.isDrafts {
                // From user perspective, we have edited a drafted message and will send it.
                // Technically we are creating and sending a new message (msg), thus we have to
                // delete the original, previously drafted one.
                me.deleteOriginalMessage()
            }

            return msg
        }

        showAlertFordwardingLessSecureIfRequired(forState: safeState) { [weak self] (accepted) in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            guard accepted else {
                return
            }
            let msg = sendClosure()
            me.delegate?.dismiss()

            if let theMsg = msg {
                me.composeViewModelEndActionDelegate?.userWantsToSend(message: theMsg)
            } else {
                me.composeViewModelEndActionDelegate?.couldNotCreateOutgoingMessage()
            }
        }
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
}

// MARK: - Private

extension ComposeViewModel {

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

    typealias Accepted = Bool
    /// When forwarding/answering a previously decrypted message and the pEpRating is considered as
    /// less secure as the original message's pEp rating, warn the user.
    private func showAlertFordwardingLessSecureIfRequired(forState state: ComposeViewModelState,
                                                          completion: @escaping (Accepted)->()) {
        guard AppSettings.shared.unsecureReplyWarningEnabled else {
            // Setting is disabled ...
            // ... nothing to do.
            completion(true)
            return
        }
        guard
            let composeMode = state.initData?.composeMode,
            composeMode != .normal
        else {
            // The message is not forwarded or answered, not our use case ...
            // ... nothing to do
            completion(true)
            return
        }
        guard let originalMessage = state.initData?.originalMessage else {
            Log.shared.errorAndCrash("Invalid state: Forward && not having an original message")
            completion(true)
            return
        }
        var originalRating: Rating? = nil //!!!: BUFF: AFAIU originalRating MUST NOT taken be taken into account any more since IOS-2414
        let group = DispatchGroup()
        group.enter()
        originalMessage.pEpRating { (rating) in
            originalRating = rating
            group.leave()
        }
        group.notify(queue: DispatchQueue.main) {[weak self] in
            guard let me = self else {
                // Valid case. The we might have been dismissed already.
                // Do nothing ...
                return
            }
            guard let originalRating = originalRating else {
                Log.shared.errorAndCrash("No rating")
                completion(false)
                return
            }
            let pEpRating = state.rating
            let title: String
            let message: String
            if composeMode == .forward {
                title = NSLocalizedString("Confirm Forward",
                                          comment: "Confirm less secure forwarding message alert title")
                message = NSLocalizedString("You are about to forward a secure message as unsecure. If you choose to proceed, confidential information might be leaked putting you and your communication partners at risk. Are you sure you want to continue?",
                                            comment: "Confirm less secure forwarding message alert body")
            } else {
                title = NSLocalizedString("Confirm Answer",
                                          comment: "Confirm less secure answering message alert title")
                message = NSLocalizedString("You are about to answer a secure message as unsecure. If you choose to proceed, confidential information might be leaked putting you and your communication partners at risk. Are you sure you want to continue?",
                                            comment: "Confirm less secure answer message alert body")
            }

            if pEpRating.hasLessSecurePepColor(than: originalRating) {
                // Forwarded mesasge is less secure than original message. Warn the user.
                me.delegate?.showTwoButtonAlert(withTitle: title,
                                                message: message,
                                                cancelButtonText: NSLocalizedString("NO", comment: "'No' button to confirm less secure email sent"),
                                                positiveButtonText: NSLocalizedString("YES", comment: "'Yes' button to confirm less secure email sent"),
                                                cancelButtonAction: { completion(false) },
                                                positiveButtonAction: { completion(true) })
            } else {
                completion(true)
            }
        }
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
                               didChangePEPRatingTo newRating: Rating) {
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
                var subject = state?.subject ?? ""
                if subject.isEmpty {
                    // Works around a layout issue that shows empty two lines when replying a mail
                    // with empty subject.
                    subject = " "
                }
                let rowModel = SubjectCellViewModel(content: subject, resultDelegate: cellVmDelegate)
                rows.append(rowModel)
            case .body:
                rows.append(BodyCellViewModel(resultDelegate: cellVmDelegate,
                                              initialPlaintext: state?.initData?.bodyPlaintext,
                                              initialAttributedText: state?.initData?.bodyHtml,
                                              inlinedAttachments: state?.initData?.inlinedAttachments,
                                              account: state?.from))
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
        guard
            let section = section(for: .attachments),
            let rows = section.rows as? [AttachmentViewModel]
        else {
            Log.shared.errorAndCrash("Only attachments can be removed by the user")
            return
        }
        // Remove from section
        var newAttachmentVMs = [AttachmentViewModel]()
        for vm in rows {
            vm.attachment.session.performAndWait {
                if vm.attachment != removee {
                    newAttachmentVMs.append(vm)
                }
            }
        }
        section.rows = newAttachmentVMs
        // Remove from state
        var newNonInlinedAttachments = [Attachment]()
        for att in state.nonInlinedAttachments {
            let safeRemovee = removee.safeForSession(att.session)
            att.session.performAndWait {
                if att != safeRemovee {
                    newNonInlinedAttachments.append(att)
                }
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
        let createe = SuggestViewModel(from: state.from, resultDelegate: self)
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
        return DocumentAttachmentPickerViewModel(resultDelegate: self, session: session)
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
        return MediaAttachmentPickerProviderViewModel(resultDelegate: self, session: session)
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
        if offerToSaveDraftOnCancel {
            return existsDirtyCell() || state.edited
        } else {
            return false
        }
    }

    public var deleteActionTitle: String {
        guard let data = state.initData else {
            Log.shared.errorAndCrash("No data")
            return ""
        }
        let title: String
        if data.isDrafts {
            title = NSLocalizedString("Delete Changes", comment:
                                        "ComposeTableView: button to decide to delete changes made on a drafted mail.")
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

    //!!!: Dirty hack. Works around a mess in Session.main, caused by creating and using of
    //messageToSend in/for TrustmanagementVC (which is supposed to use an independent Session
    // but leaves leftovers that makes commiting the Session impossible).
    private func rollbackMainSession() {
        Session.main.rollback()
    }

    public func handleDeleteActionTriggered() {
        rollbackMainSession()
    }

    public func handleSaveActionTriggered() {
        rollbackMainSession()
        guard let data = state.initData else {
            Log.shared.errorAndCrash("No data")
            return
        }
        if data.isDrafts {
            // We are in drafts folder and, from user perespective, are editing a drafted mail.
            // Technically we have to create a new one and delete the original message, as the
            // mail is already synced with the IMAP server and thus we must/can not modify it.
            deleteOriginalMessage()
        }

        let safeState = state.makeSafe(forSession: Session.main)

        guard let msg = ComposeUtil.messageToSend(withDataFrom: safeState) else {
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
    }
}

// MARK: - TrustManagementViewModel

extension ComposeViewModel {

    func canDoHandshake(completion: @escaping (Bool)->Void) {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.state.canHandshake(completion: completion)
        }
    }

    func trustManagementViewModel() -> TrustManagementViewModel? {

        guard let message = ComposeUtil.messageForTrustManagement(withDataFrom: state) else {
            Log.shared.errorAndCrash("No message")
            return nil
        }
        // Do not store message (persistRatingChangesForMessage). Would result in a meesage in Outbox and thus unwanted sending
        return TrustManagementViewModel(message: message,
                                        pEpProtectionModifyable: true,
                                        persistRatingChangesForMessage: false,
                                        protectionStateChangeDelegate: self,
                                        ratingDelegate: self)
    }
}

// MARK: - TrustmanagementProtectionStateChangeDelegate

extension ComposeViewModel: TrustmanagementProtectionStateChangeDelegate {
    func protectionStateChanged(to newValue: Bool) {
        state.pEpProtection = newValue
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
        suggestionsVM?.updateSuggestion(searchString: text.cleanAttachments)
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
        suggestionsVM?.updateSuggestion(searchString: newText.cleanAttachments)
    }

    // MARK: - Add Contact

    func addContactTapped() {
        delegate?.showContactsPicker()
    }

    func handleContactSelected(address: String, addressBookID: String, userName: String) {
        guard
            let idxPath = lastRowWithSuggestions,
            let recipientVM = sections[idxPath.section].rows[idxPath.row] as? RecipientCellViewModel
        else {
            Log.shared.errorAndCrash("No row VM")
            return
        }
        let contactIdentity = Identity(address: address, userID: nil,
                                       addressBookID: addressBookID,
                                       userName: userName,
                                       session: Session.main)
        recipientVM.add(recipient: contactIdentity)
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
        state.subject = vm.content
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

    func bodyCellViewModel(_ vm: BodyCellViewModel, bodyAttributedString: NSAttributedString) {
        state.bodyText = bodyAttributedString

        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash("We got called by a non-existing VM?")
            return
        }
        // Dispatch as next to not "Attempted to call -cellForRowAtIndexPath: on the table view while it was in the process of updating its visible cells, which is not allowed. ...". See IOS-2347 for details.
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Valid case. The view might have been dismissed already.
                return
            }
            me.delegate?.contentChanged(inRowAt: idxPath)
        }
    }
}

// MARK: - TrustmanagementRatingChangedDelegate

extension ComposeViewModel: TrustmanagementRatingChangedDelegate {
    func ratingMayHaveChanged() {
        state.reevaluatePepRating()
    }
}
