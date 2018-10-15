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

// MARK: - ComposeViewModelStateDelegate

extension ComposeViewModel: ComposeViewModelStateDelegate {
    func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
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
            //IOS-1369: handle wrapped. Own section please.
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
