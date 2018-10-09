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
    public private(set) var state = ComposeViewModelState()
    public let initData: ComposeViewModel.InitData


    init(resultDelegate: ComposeViewModelResultDelegate? = nil,
         prefilledTo: Identity? = nil,
         originalMessage: Message? = nil) {
        self.resultDelegate = resultDelegate
        self.initData = ComposeViewModel.InitData(prefilledTo: prefilledTo,
                                                  originalMessage: originalMessage)
        setup()
    }

    public func viewModel(for indexPath: IndexPath) -> CellViewModel {
        return sections[indexPath.section].rows[indexPath.row]
    }

    private func setup() {
        //IOS-1369: origMessage ignored for now, same with compose mode (always .normal)
        resetSections()

    }

    private func resetSections() {
        var newSections = [ComposeViewModel.Section]()
        for type in ComposeViewModel.Section.SectionType.allCases {
            if let section = ComposeViewModel.Section(type: type, cellVmDelegate: self) {
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
    }
}

// MARK: - State

extension ComposeViewModel {
    /// Wraps bookholding properties
    struct ComposeViewModelState {
        fileprivate var isValidatedForSending = false
        public fileprivate(set) var edited = false
    }

    private func updateState() {
        state.edited = true
        validateInput()
    }

    private func validateInput() {
        let before = state.isValidatedForSending
        //IOS-1369: unimplemented stub") //IOS-1369:
        //TODO: validate!
        if before != state.isValidatedForSending {
            delegate?.validatedStateChanged(to: state.isValidatedForSending)
        }
    }
}

// MARK: - CellViewModels

extension ComposeViewModel {
    class Section {
        enum SectionType: CaseIterable {
            case /*recipients, account, */subject/*, body, attachments*/
        }
        let type: SectionType
        fileprivate(set) public var rows = [CellViewModel]()

        init?(type: SectionType, cellVmDelegate: ComposeViewModel) {
            self.type = type
            resetViewModels(cellVmDelegate: cellVmDelegate)
            if rows.count == 0 {
                // We want to show non-empty sections only
                return nil
            }
        }

        private func resetViewModels(cellVmDelegate: ComposeViewModel) {
            rows = [CellViewModel]()
            switch type {
                //            case .recipients:
                //                rows.append(RecipientFieldViewModel(type: .to))
                //                rows.append(RecipientFieldViewModel(type: .wraped))
                //            case .account:
            //                rows.append(AccountFieldViewModel())
            case .subject:
                rows.append(SubjectCellViewModel(resultDelegate: cellVmDelegate))
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

// MARK: - SubjectCellViewModelResultDelegate

extension ComposeViewModel: SubjectCellViewModelResultDelegate {

    func SubjectCellViewModelDidChangeSubject(_ subjectCellViewModel: SubjectCellViewModel) {
        //IOS-1369: YAGNI
        guard let idxPath = indexPath(for: subjectCellViewModel) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We got called by a non-existing VM?")
            return
        }
        delegate?.contentChanged(inCellAt: idxPath)
        updateState()
    }
}
