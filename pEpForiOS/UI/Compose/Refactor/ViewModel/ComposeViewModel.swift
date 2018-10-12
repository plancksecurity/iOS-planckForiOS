//
//  ComposeViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Informs the one that triggered the segued to here.
protocol ComposeViewModelResultDelegate: class {
    /// Called after a valid mail has been composed and saved for sending.
    func composeViewModelDidComposeNewMail()
    /// Called after saving a modified version of the original message.
    /// (E.g. after editing a drafted message)
    func composeViewModelDidModifyMessage()
    /// Called after permanentaly deleting the original message.
    /// (E.g. saving an edited oubox mail to drafts. It's permanentaly deleted from outbox.)
    func composeViewModelDidDeleteMessage()
}

protocol ComposeViewModelDelegate: class {
    //Will grow BIG :-/
    //IOS-1369: //TODO handle func userSelectedRecipient(identity: Identity) suggestion
    func contentChanged(inCellAt indexPath: IndexPath)
    func validatedStateChanged(to isValidated: Bool)
}

class ComposeViewModel {
    weak var resultDelegate: ComposeViewModelResultDelegate?
    weak var delegate: ComposeViewModelDelegate?
    public private(set) var sections = [ComposeViewModel.Section]()
    public private(set) var state: ComposeViewModelState

    init(resultDelegate: ComposeViewModelResultDelegate? = nil,
         composeMode: ComposeUtil.ComposeMode? = nil,
         prefilledTo: Identity? = nil,
         originalMessage: Message? = nil) {
        self.resultDelegate = resultDelegate
        let initData = InitData(withPrefilledToRecipient: prefilledTo,
                                orForOriginalMessage: originalMessage,
                                composeMode: composeMode)
        self.state = ComposeViewModelState(initData: initData)
        self.state.delegate = self
        setup()
    }

    public func viewModel(for indexPath: IndexPath) -> CellViewModel {
        return sections[indexPath.section].rows[indexPath.row]
    }

    private func setup() {
        //IOS-1369: origMessage ignored for now, same with compose mode (always .normal)
        resetSections()
        //        validateInput() //IOS-1369:
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
    }
}

// MARK: - InitData

extension ComposeViewModel {
    /// Wraps properties used for initial setup
    struct InitData {
        /// Recipient to set as "To:".
        /// Is ignored if a originalMessage is set.
        public let prefilledTo: Identity?
        /// Original message to compute content and recipients from (e.g. a message we reply to).
        public let originalMessage: Message?

        public let composeMode: ComposeUtil.ComposeMode

        /// Whether or not the original message is in Drafts or Outbox
        var isDraftsOrOutbox: Bool {
            return isDrafts || isOutbox
        }

        /// Whether or not the original message is in Drafts folder
        var isDrafts: Bool {
            if let om = originalMessage {
                return om.parent.folderType == .drafts
            }
            return false
        }

        /// Whether or not the original message is in Outbox
        var isOutbox: Bool {
            if let om = originalMessage {
                return om.parent.folderType == .outbox
            }
            return false
        }

        var from: Identity? {
            return ComposeUtil.initialFrom(composeMode: composeMode,
                                           originalMessage: originalMessage)
        }

        var toRecipients: [Identity] {
            if let om = originalMessage {
                return ComposeUtil.initialTos(composeMode: composeMode, originalMessage: om)
            } else if let presetTo = prefilledTo {
                return [presetTo]
            }
            return []
        }

        var ccRecipients: [Identity] {
            guard let om = originalMessage else {
                return []
            }
            return ComposeUtil.initialCcs(composeMode: composeMode, originalMessage: om)
        }

        var bccRecipients: [Identity] {
            guard let om = originalMessage else {
                return []
            }
            return ComposeUtil.initialBccs(composeMode: composeMode, originalMessage: om)
        }

        var subject: String? {
            return originalMessage?.shortMessage
        }

        //IOS-1369: body needs before 9pm brain

        var nonInlinedAttachments: [Attachment] {
            return ComposeUtil.initialNonInlinedAttachments(composeMode: composeMode,
                                                            originalMessage: originalMessage)
        }



        init(withPrefilledToRecipient prefilledTo: Identity? = nil,
             orForOriginalMessage om: Message? = nil,
             composeMode: ComposeUtil.ComposeMode? = nil) {
            self.composeMode = composeMode ?? ComposeUtil.ComposeMode.normal
            self.originalMessage = om
            self.prefilledTo = om == nil ? prefilledTo : nil
        }
    }
}

// MARK: - State

protocol ComposeViewModelStateDelegate: class {
    func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                               didChangeValidationStateTo isValid: Bool)
}

extension ComposeViewModel {

    /// Wraps bookholding properties
    class ComposeViewModelState {
        let initData: ComposeViewModel.InitData?
        private var edited = false
        private var isValidatedForSending = false

        weak var delegate: ComposeViewModelStateDelegate?

        //Recipients
        var toRecipients = [Identity]() {
            didSet {
                edited = true
                validateForSending()
            }
        }
        var ccRecipients = [Identity]() {
            didSet {
                edited = true
                validateForSending()
            }
        }
        var bccRecipients = [Identity]() {
            didSet {
                edited = true
                validateForSending()
            }
        }

        var from: Identity? {
            didSet {
                edited = true
                validateForSending()
            }
        }

        var subject = "" {
            didSet {
                edited = true
            }
        }

        var body = "" {
            didSet {
                edited = true
            }
        }

        var attachments = [Attachment]() {
            didSet {
                edited = true
            }
        }

        init(initData: InitData? = nil, delegate: ComposeViewModelStateDelegate? = nil) {
            self.initData = initData
            self.delegate = delegate
            setup()
        }

        private func setup() {
            guard let initData = initData else {
                Log.shared.errorAndCrash(component: #function, errorString: "No data")
                return
            }
            toRecipients = initData.toRecipients
            ccRecipients = initData.ccRecipients
            bccRecipients = initData.bccRecipients
            from = initData.from
            subject = initData.subject ?? " " // Set space to work around autolayout first baseline not recognized
            //            body = initD //IOS-1369: TODO
            attachments = initData.nonInlinedAttachments
        }

        private func validateForSending() {
            let before = isValidatedForSending
            //IOS-1369: unimplemented stub") //IOS-1369:
            //TODO: validate!
            //atLeastOneRecipientIsSet && !hasInvalidRecipients && from != nil
            isValidatedForSending = !isValidatedForSending
            if before != isValidatedForSending {
                delegate?.composeViewModelState(self,
                                                didChangeValidationStateTo: isValidatedForSending)
            }
        }
    }
}

// MARK: - ComposeViewModelStateDelegate

extension ComposeViewModel: ComposeViewModelStateDelegate {
    func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                               didChangeValidationStateTo isValid: Bool) {
        delegate?.validatedStateChanged(to: isValid)
    }
}

// MARK: - CellViewModels

extension ComposeViewModel {
    class Section {
        enum SectionType: CaseIterable {
            case recipients, account, subject/*, body, attachments*/
        }
        let type: SectionType
        fileprivate(set) public var rows = [CellViewModel]()

        init?(type: SectionType, for state: ComposeViewModelState?, cellVmDelegate: ComposeViewModel) {
            self.type = type
            setupViewModels(cellVmDelegate: cellVmDelegate, for: state)
            if rows.count == 0 {
                // We want to show non-empty sections only
                return nil
            }
        }

        private func setupViewModels(cellVmDelegate: ComposeViewModel,
                                     for state: ComposeViewModelState?) {
            rows = [CellViewModel]()
            switch type {
            case .recipients:
                rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate, type: .to))
                rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate, type: .wraped))
            case .account:
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
                //            case .body:
                //                rows.append(BodyFieldViewModel())
                //            case .attachments:
                //                setupAttchmentRows()
            }
        }

        private func setupAttchmentRows() {
            //IOS-1369: //!!!: add later for mode != .normal
            //
            //            rows.append(AttachmentViewModel)
        }
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

// MARK: - Suggestions

extension ComposeViewModel {
    func suggestViewModel() -> SuggestViewModel {
        return SuggestViewModel(resultDelegate: self)
    }
}

extension ComposeViewModel: SuggestViewModelResultDelegate {
    func suggestViewModelDidSelectContact(identity: Identity) {
        //IOS-1369:
        //TODO:
    }
}

// MARK: - Cell-ViewModels

// MARK: - RecipientCellViewModelResultDelegate

extension ComposeViewModel: RecipientCellViewModelResultDelegate {
    func recipientCellViewModel(_ vm: RecipientCellViewModel,
                                didChangeRecipients newRecipients: [Identity]) {
        //IOS-1369: handle!
        print("newRecipients: \(newRecipients)")
        switch vm.type {
        case .to:
            state.toRecipients = newRecipients
        case .cc:
            state.ccRecipients = newRecipients
        case .bcc:
            state.bccRecipients = newRecipients
        case .wraped:
            //IOS-1369: handle wrapped. Maybe specialize recipientCell/VM with dead impl?
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "Wraped cellVM should never have recipients")
            break
        }
    }

    func recipientCellViewModelDidEndEditing(_ vm: RecipientCellViewModel) {
        //IOS-1369: handle!
        //IOS-1369: YAGNIl. TableView currently updates size and does not need the index path.
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
            return
        }
        delegate?.contentChanged(inCellAt: idxPath)
    }
}

// MARK: - AccountCellViewModelResultDelegate

extension ComposeViewModel: AccountCellViewModelResultDelegate {
    func accountCellViewModel(_ vm: AccountCellViewModel, accountChangedTo account: Account) {
        //IOS-1369: YAGNIl. TableView currently updates size and does not need the index path.
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
            return
        }
        state.from = account.user
        delegate?.contentChanged(inCellAt: idxPath)
    }
}

// MARK: - SubjectCellViewModelResultDelegate

extension ComposeViewModel: SubjectCellViewModelResultDelegate {

    func subjectCellViewModelDidChangeSubject(_ vm: SubjectCellViewModel) {
        //IOS-1369: YAGNIl. TableView currently updates size and does not need the index path.
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
            return
        }
        state.subject = vm.content ?? ""
        delegate?.contentChanged(inCellAt: idxPath)
    }
}
