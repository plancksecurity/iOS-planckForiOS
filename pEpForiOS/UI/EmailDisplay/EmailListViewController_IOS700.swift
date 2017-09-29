//
//  EmailListViewController_IOS700.swift
//  pEp
//
//  Created by Andreas Buff on 28.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import Foundation

import MessageModel

class EmailListViewController_IOS700: BaseTableViewController {
    private struct TableViewModel {
        var rows: [Row]
    }
    private struct Row {
        var senderImage: UIImage?
        var ratingImage: UIImage?
        var showAttchmentIcon: Bool = false
        let from: String
        let subject: String
        let bodyPeek: String
        var isFlagged: Bool = false
        var isSeen: Bool = false
        var date: String

        mutating func freeMemory() {
            senderImage = nil
            ratingImage = nil
        }
    }

    private var tableViewModel: TableViewModel = TableViewModel(rows: [])
    private let queue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInteractive
        createe.maxConcurrentOperationCount = 10
        return createe
    }()
    private var operations = [IndexPath:Operation]()

    var config: EmailListConfig? //BUFF: think about

    // MARK: - Outlets

    @IBOutlet weak var enableFilterButton: UIBarButtonItem!
    @IBOutlet weak var textFilterButton: UIBarButtonItem!
    @IBOutlet var showFoldersButton: UIBarButtonItem!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Inbox", comment: "General name for (unified) inbox")
        UIHelper.emailListTableHeight(self.tableView)
//        addSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
        if MiscUtil.isUnitTest() {
            return
        }

        //BUFF:
        for i in 1...100 {
            let row = Row(senderImage: nil, ratingImage: nil, showAttchmentIcon: false, from: "from:\(i)", subject: "subject:\(i)", bodyPeek: "body:\(i)", isFlagged: i%2 == 0, isSeen: false, date: "date:\(i)")
            tableViewModel.rows.append(row)
        }
        tableView.reloadData()

        //BUFF: TODO
//        if let vm = viewModel {
//            self.textFilterButton.isEnabled = vm.filterEnabled
//            updateFilterText()
//        } else {
//            self.textFilterButton.isEnabled = false
//        }
//
//        setDefaultColors()
//        setupConfig()
//        updateModel()
//
//        // Mark this folder as having been looked at by the user
//        if let folder = config?.folder {
//            updateLastLookAt(on: folder)
//        }
//        if viewModel == nil {
//            viewModel = EmailListViewModel(config: config, delegate: self)
//        }
//        MessageModelConfig.messageFolderDelegate = self
//
//        if let size = navigationController?.viewControllers.count, size > 1 {
//            self.showFoldersButton.isEnabled = false
//        } else {
//            self.showFoldersButton.isEnabled = true
//        }
    }

    // MARK: - Actions

    @IBAction func showUnreadButtonTapped(_ sender: UIBarButtonItem) {
        handlefilter()
    }

    func handlefilter() {
        //BUFF: TODO
//        if let vm = viewModel {
//            if vm.filterEnabled {
//                vm.filterEnabled = false
//                handleButtonFilter(enabled: false)
//                if config != nil {
//                    vm.resetFilters()
//                }
//            } else {
//                vm.filterEnabled = true
//                if config != nil {
//                    vm.enableFilter()
//                }
//                handleButtonFilter(enabled: true)
//            }
//            self.textFilterButton.isEnabled = vm.filterEnabled
//        }
    }

    // MARK: - UITableViewDataSource

    //BUFF: is default. not needed. We always have one section, maybe an empty one
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        if let _ = viewModel?.folderToShow {
//            return 1
//        }
//        return 0
//    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewModel.rows.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EmailListViewCell",
                                                       for: indexPath) as? EmailListViewCell_IOS700 else {
            Log.shared.errorAndCrash(component: #function, errorString: "Wrong cell!")
            return UITableViewCell()
        }
//        let _ = cell.configureCell(config: config, indexPath: indexPath, session: session)
//        viewModel?.associate(cell: cell, position: indexPath.row)
        configure(cell: cell, for: indexPath, config: config)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, editActionsForRowAt
        indexPath: IndexPath)-> [UITableViewRowAction]? {
        //BUFF: TODO:
//        let cell = tableView.cellForRow(at: indexPath) as! EmailListViewCell
//        if let email = cell.messageAt(indexPath: indexPath, config: config) {
//            let flagAction = createFlagAction(message: email, cell: cell)
//            let deleteAction = createDeleteAction(message: email, cell: cell)
//            let moreAction = createMoreAction(message: email, cell: cell)
//            return [deleteAction, flagAction, moreAction]
//        }
        return nil
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelOperation(for: indexPath)
    }

    //BUFF: from EmaiListCell
    private func configure(cell: EmailListViewCell_IOS700, for indexPath: IndexPath, config: EmailListConfig? ) { //BUFF: config needed?
        // Configure lightweight stuff on main thread ...
        let model = self.tableViewModel.rows[indexPath.row]
        cell.senderLabel.text = model.from
        cell.subjectLabel.text = model.subject
        cell.summaryLabel.text = model.bodyPeek
        let op = BlockOperation() { [weak self] in
            // ... and expensive computations in background
//            guard let strongSelf = self else {
//                // View is gone, nothing to do.
//                return
//            }
            DispatchQueue.main.async {
                cell.dateLabel.text = model.date
            }

            //BUFF: TODO
            //        self.session = theSession
            //        self.config = config
            //
            //        if let message = messageAt(indexPath: indexPath, config: config) {
            //            UIHelper.putString(message.from?.userNameOrAddress, toLabel: self.senderLabel)
            //            UIHelper.putString(message.shortMessage, toLabel: self.subjectLabel)
            //
            //            // Snippet
            //            if let text = message.longMessage {
            //                let theText = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
            //                UIHelper.putString(UIHelper.cleanHtml(theText), toLabel: self.summaryLabel)
            //            } else if let html = message.longMessageFormatted {
            //                var text = html.extractTextFromHTML()
            //                text = text?.replaceNewLinesWith(" ").trimmedWhiteSpace()
            //                UIHelper.putString(text, toLabel: self.summaryLabel)
            //            } else {
            //                UIHelper.putString(nil, toLabel: self.summaryLabel)
            //            }
            //
            //            if let originationDate = message.sent {
            //                UIHelper.putString(originationDate.smartString(), toLabel: self.dateLabel)
            //            } else {
            //                UIHelper.putString(nil, toLabel: self.dateLabel)
            //            }
            //
            //            attachmentIcon.isHidden = message.viewableAttachments().count > 0 ? false : true
            //            updateFlags(message: message)
            //            updatePepRating(message: message)
            //
            //            contactImageView.image = UIImage.init(named: "empty-avatar")
            //            identityForImage = message.from
            //            if let ident = identityForImage, let imgProvider = config?.imageProvider {
            //                imgProvider.image(forIdentity: ident) { img, ident in
            //                    if ident == self.identityForImage {
            //                        self.contactImageView.image = img
            //                    }
            //                }
            //            }
            //
            //            return message
            //        }
        }
        queue(operation: op, for: indexPath)
    }

//    /**
//     The message at the given position.
//     */
//    func haveSeen(message: Message) -> Bool {
//        return message.imapFlags?.seen ?? false
//    }
//
//    func isFlagged(message: Message) -> Bool {
//        return message.imapFlags?.flagged ?? false
//    }
//
//    func messageAt(indexPath: IndexPath, config: EmailListConfig?) -> Message? {
//        if let fol = config?.folder {
//            return fol.messageAt(index: indexPath.row)
//        }
//        return nil
//    }

//    func updatePepRating(message: Message) {
//        let color = PEPUtil.pEpColor(pEpRating: message.pEpRating(session: theSession))
//        ratingImage.image = color.statusIcon()
//        ratingImage.backgroundColor = nil
//    }

//    func updateFlags(message: Message) {
//        let seen = haveSeen(message: message)
//        let flagged = isFlagged(message: message)
//
//        self.flaggedImageView.backgroundColor = nil
//        if flagged {
//            let fi = FlagImages.create(imageSize: flaggedImageView.frame.size)
//            self.flaggedImageView.isHidden = false
//            self.flaggedImageView.image = fi.flagsImage(message: message)
//        } else {
//            // show nothing
//            self.flaggedImageView.isHidden = true
//            self.flaggedImageView.image = nil
//        }
//
//        if let font = senderLabel.font {
//            let font = seen ? UIFont.systemFont(ofSize: font.pointSize):
//                UIFont.boldSystemFont(ofSize: font.pointSize)
//            setLabels(font: font)
//        }
//    }

    // MARK: - Queue Handling

    private func queue(operation op:Operation, for indexPath: IndexPath) {
        operations[indexPath] = op
        queue.addOperation(op)
    }

    private func cancelOperation(for indexPath:IndexPath) {
        guard let op = operations.removeValue(forKey: indexPath) else {
            return
        }
        if !op.isCancelled  {
            op.cancel()
        }
    }

    // MARK: - Trival Cache

    override func didReceiveMemoryWarning() {
        for row in tableViewModel.rows {
            var tmp = row
            tmp.freeMemory()
        }
    }
}
