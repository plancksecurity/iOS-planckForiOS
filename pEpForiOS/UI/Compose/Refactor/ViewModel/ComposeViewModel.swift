//
//  ComposeViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

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
    //IOS-1369: //TODO handle func userSelectedRecipient(identity: Identity)
}

class ComposeViewModel {
    weak var resultDelegate: ComposeViewModelResultDelegate?
    weak var delegate: ComposeViewModelDelegate?
    public private(set) var sections = [ComposeViewModel.Section]()


    /// Recipient to set as "To:".
    /// Is ignored if a originalMessage is set.
    var prefilledTo: Identity?
    /// Original message to compute content and recipients from (e.g. a message we reply to).
    var originalMessage: Message?

    init(resultDelegate: ComposeViewModelResultDelegate? = nil, originalMessage: Message? = nil) {
        self.resultDelegate = resultDelegate
        self.originalMessage = originalMessage
        setup()
    }

    private func setup() {
        //IOS-1369: origMessage ignored for now, same with compose mode (always .normal)
        resetSections()

    }

    private func resetSections() {
        var newSections = [ComposeViewModel.Section]()
        for type in ComposeViewModel.Section.SectionType.allCases {
            newSections.append(ComposeViewModel.Section(type: type))
        }
        self.sections = newSections
    }
}

// MARK: - CellViewModels

extension ComposeViewModel {
    class Section {
        enum SectionType: CaseIterable {
            case recipients, account, subject, body, attachments
        }
        let type: SectionType
        fileprivate(set) public var rows = [CellViewModel]()

        init(type: SectionType) {
            self.type = type
        }

        private func resetViewModels() {
            rows = [CellViewModel]()
            switch type {
            case .recipients:
                rows.append(RecipientFieldViewModel(type: .to))
                rows.append(RecipientFieldViewModel(type: .wraped))
                rows.append(RecipientFieldViewModel(type: .to))
            case .account:
                rows.append(AccountFieldViewModel())
            case .subject:
                rows.append(SubjectFieldViewModel())
            case .body:
                rows.append(BodyFieldViewModel())
            case .attachments:
                setupAttchmentRows()
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
