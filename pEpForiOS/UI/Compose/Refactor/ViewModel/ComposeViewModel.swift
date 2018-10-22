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

    /// Called when the user changes the contetn of a row.
    /// E.g. edited the subject.
    ///
    /// - Parameter indexPath: indexPath of changed row
    func contentChanged(inRowAt indexPath: IndexPath)

    /// The status of whether or not the message has been validated for sending changed.
    ///
    /// - Parameter isValidated: new value
    func validatedStateChanged(to isValidated: Bool)

    /// The model changed / has been resetted
    func modelChanged()

    func colorBatchNeedsUpdate(for rating: PEP_rating, protectionEnabled: Bool)

    func hideSuggestions()

    func showSuggestions(forRowAt indexPath: IndexPath)

    func showMediaAttachmentPicker()

    func hideMediaAttachmentPicker()
}

class ComposeViewModel {
    weak var resultDelegate: ComposeViewModelResultDelegate?
    weak var delegate: ComposeViewModelDelegate?
    public private(set) var sections = [ComposeViewModel.Section]()
    public private(set) var state: ComposeViewModelState

    private var suggestionsVM: SuggestViewModel?
    private var lastRowWithSuggestions: IndexPath?

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

    public func handleUserSelectedRow(at indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if section.type == .wrapped {
            state.setBccUnwrapped()
            resetSections()
        }
    }

    public func handleUserChangedProtectionStatus(to protected: Bool) {
        state.pEpProtection = protected
    }

    private func setup() {
        //IOS-1369: origMessage ignored for now, same with compose mode (always .normal)
        resetSections()
        //        validateInput() //IOS-1369:
    }

    private func existsDirtyRecipientCell() -> Bool {
        for section in sections where section.type == .recipients {
            for row  in section.rows where row is RecipientCellViewModel {
                guard let recipientVM = row as? RecipientCellViewModel else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Cast error")
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
        let userSeemsTyping = existsDirtyRecipientCell()
        delegate?.validatedStateChanged(to: isValid && !userSeemsTyping)
    }

    func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
                               didChangePEPRatingTo newRating: PEP_rating) {
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
            case recipients, wrapped, account, subject, body/*, attachments*/
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
                rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate, type: .to)) //IOS-1369: set initial
                if let wrapped = state?.bccWrapped, !wrapped {
                    rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate, type: .cc)) //IOS-1369: set initial
                    rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate, type: .bcc)) //IOS-1369: set initial
                }
            case .wrapped:
                if let wrapped = state?.bccWrapped, wrapped {
                    rows.append(WrappedBccViewModel())
                }
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
            case .body:
                rows.append(BodyCellViewModel(resultDelegate: cellVmDelegate)) //IOS-1369: set initial
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
                Log.shared.errorAndCrash(component: #function, errorString: "No row VM")
            return
        }
        recipientVM.add(recipient: identity)
    }
}

// MARK: - MediaAttachmentPickerProviderViewModel[ResultDelegate]

extension ComposeViewModel {
    func mediaAttachmentPickerProviderViewModel() -> MediaAttachmentPickerProviderViewModel {
        return MediaAttachmentPickerProviderViewModel(resultDelegate: self)
    }
}

extension ComposeViewModel: MediaAttachmentPickerProviderViewModelResultDelegate {

    func mediaAttachmentPickerProviderViewModel(
        _ vm: MediaAttachmentPickerProviderViewModel,
        didSelect mediaAttachment: MediaAttachmentPickerProviderViewModel.MediaAttachment) {
        if mediaAttachment.type == .image {
            //IOS-1369: TODO: add inlined attachment to state? I think so.
            guard let bodyViewModel = bodyVM else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "No bodyVM. Maybe valid as picking is async.")
                return
            }
            bodyViewModel.inline(attachment: mediaAttachment.attachment)
        } else {
            state.nonInlinedAttachments.append(mediaAttachment.attachment)
            delegate?.hideMediaAttachmentPicker()
            //IOS-1369: update attachment section
            //IOS-1369: update TV.
        }
    }
}

// MARK: - Cell-ViewModel Delegates

// MARK: RecipientCellViewModelResultDelegate

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
        }
/*
         calculateComposeColorAndInstallTapGesture()
         recalculateSendButtonStatus()
 */
    }

    func recipientCellViewModelDidEndEditing(_ vm: RecipientCellViewModel) {
        //IOS-1369: handle!
        //IOS-1369: YAGNIl. TableView currently updates size and does not need the index path.
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
            return
        }
        delegate?.contentChanged(inRowAt: idxPath)
        delegate?.hideSuggestions()
        state.validate()
        /*
         tableView.updateSize()
         hideSuggestions()
         */
    }

    func recipientCellViewModel(_ vm: RecipientCellViewModel, textChanged newText: String) {
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
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
        //IOS-1369: YAGNIl. TableView currently updates size and does not need the index path.
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
            return
        }
        state.from = account.user
        delegate?.contentChanged(inRowAt: idxPath)
    }
}

// MARK: SubjectCellViewModelResultDelegate

extension ComposeViewModel: SubjectCellViewModelResultDelegate {

    func subjectCellViewModelDidChangeSubject(_ vm: SubjectCellViewModel) {
        //IOS-1369: YAGNIl. TableView currently updates size and does not need the index path.
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
            return
        }
        state.subject = vm.content ?? ""
        delegate?.contentChanged(inRowAt: idxPath)
    }
}

// MARK: - BodyCellViewModelResultDelegate

extension ComposeViewModel: BodyCellViewModelResultDelegate {

    var bodyVM: BodyCellViewModel? {
        for section in sections where section.type == .body {
            return section.rows.first as? BodyCellViewModel
        }
        return nil
    }

    func bodyCellViewModel(_ vm: BodyCellViewModel, textChanged newText: String) {
        //IOS-1369: YAGNIl. TableView currently updates size and does not need the index path.
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
            return
        }
        //IOS-1369: What to save to state? attributedText? markdown? ...
        delegate?.contentChanged(inRowAt: idxPath)
    }

    func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel) {
        delegate?.showMediaAttachmentPicker()
    }

    func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel) {
        fatalError()
    }

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           inlinedAttachmentsChanged inlinedAttachments: [Attachment]) {
        //IOS-1369: YAGNIl. TableView currently updates size and does not need the index path.
        guard let idxPath = indexPath(for: vm) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
            return
        }
        state.inlinedAttachments = inlinedAttachments
        delegate?.hideMediaAttachmentPicker()
        delegate?.contentChanged(inRowAt: idxPath)
    }

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           bodyChangedToPlaintext plain: String,
                           html: String) {
        state.bodyHtml = html
        state.bodyPlaintext = plain
    }
}
