//
//  ComposeViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI
import MobileCoreServices
import MessageModel

class ComposeTableViewController: UITableViewController {

    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    
    enum ComposeMode {
        case normal
        case from
        case all
        case forward
        case draft
    }
    
    let contactPicker = CNContactPickerViewController()
    let imagePicker = UIImagePickerController()
    let menuController = UIMenuController.shared
    
    var suggestTableView: SuggestTableView!
    var tableDict: NSDictionary?
    var tableData: ComposeDataSource? = nil
    var currentCell: IndexPath!
    var allCells = [ComposeCell]()
    var ccEnabled = false
    
    var appConfig: AppConfig?
    var composeMode: ComposeMode = .normal
    var messageToSend: Message?
    var originalMessage: Message?
    let operationQueue = OperationQueue()

    lazy var session = PEPSession()
    lazy var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    /// Segue name back to email list when email was sent successfully.
    let unwindToEmailListMailSentSegue = "unwindToEmailListMailSentSegue"

    /// Segue name back to email list when a draft mail should be stored.
    let unwindToEmailListSaveDraftSegue = "unwindToEmailListSaveDraftSegue"

    /// Segue name back to email list, doing nothing else.
    let unwindToEmailListSegue = "unwindToEmailListSegue"
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addContactSuggestTable()
        prepareFields()
    }
    
    // MARK: - Private Methods
    
    private final func prepareFields()  {
        if let path = Bundle.main.path(forResource: "ComposeData", ofType: "plist") {
            tableDict = NSDictionary(contentsOfFile: path)
        }
        
        if let dict = tableDict as? [String: Any] {
            tableData = ComposeDataSource(with: dict["Rows"] as! [[String: Any]])
        }
    }
    
    fileprivate final func openAddressBook() {
        present(contactPicker, animated: true, completion: nil)
    }
    
    fileprivate final func createAttachment(_ url: URL, _ isMovie: Bool = false) -> Attachment {
        let filetype = url.pathExtension
        var filename = url.standardizedFileURL.lastPathComponent
        
        if isMovie {
            filename = "MailComp.Video".localized + filetype
        }
        
        return Attachment.inline(name: filename, url: url, type: filetype, image: nil)
    }
    
    fileprivate final func shouldShowCC(for textview: ComposeTextView) -> Bool {
        if (textview.fieldModel?.type == .to ||
            textview.fieldModel?.type == .subject ||
            textview.fieldModel?.type == .content) &&
            textViewsValidate() == false {
            return false
        }
        return true
    }
    
    fileprivate final func textViewsValidate() -> Bool {
        var result = false
        let types: [ComposeFieldModel.FieldType] = [.cc, .bcc]
        let filteredModels = tableData?.rows.filter { types.contains($0.type) }
        
        filteredModels?.forEach {
            if $0.value.length > 0 {
                result = true
            } else {
                result = result || false
            }
        }
        return result
    }
    
    fileprivate final func addContactSuggestTable() {
        suggestTableView = storyboard?.instantiateViewController(withIdentifier: "contactSuggestionTable").view as! SuggestTableView
        suggestTableView.delegate = self
        suggestTableView.hide()
        updateSuggestTable(defaultCellHeight, true)
        tableView.addSubview(suggestTableView)
    }
    
    fileprivate final func updateSuggestTable(_ position: CGFloat, _ start: Bool = false) {
        var pos = position
        if pos < defaultCellHeight && !start { pos = defaultCellHeight * (position + 1) + 2 }
        suggestTableView.frame.origin.y = pos
        suggestTableView.frame.size.height = tableView.bounds.size.height - pos + 2
    }
    
    fileprivate final func populateMessage() {
        var toAddresses = [String]()
        var ccAddresses = [String]()
        var bccAddresses = [String]()
        var messageBody = NSAttributedString()
        var from = String()
        var subject = String()
        var attachments = [Attachment?]()
        
        allCells.forEach({ (cell) in
            if cell is RecipientCell {
                let addresses = (cell as! RecipientCell).identities
                
                switch cell.fieldModel!.type {
                case .to:
                    addresses.forEach({ (recipient) in
                        toAddresses.append(recipient.address)
                    })
                    break
                case .cc:
                    addresses.forEach({ (recipient) in
                        ccAddresses.append(recipient.address)
                    })
                    break
                case .bcc:
                    addresses.forEach({ (recipient) in
                        bccAddresses.append(recipient.address)
                    })
                    break
                default: ()
                    break
                }
            } else if cell is MessageBodyCell {
                messageBody = cell.textView.attributedText
                attachments = (cell as! MessageBodyCell).getAllAttachments()
            } else {
                switch cell.fieldModel!.type {
                case .from:
                    from = cell.textView.text
                    break
                default:
                    subject = cell.textView.text
                    break
                }
            }
        })
        
        print("--------------------------------------")
        print("To: \(toAddresses)")
        print("Cc: \(ccAddresses)")
        print("Bcc: \(bccAddresses)")
        print("From: \(from)")
        print("Subject: \(subject)")
        print("Attachments: \(attachments)")
        print("Body: \(messageBody)")
        print("--------------------------------------")
    }
    
    // MARK: - Public Methods
    
    public final func addMediaToCell() {
        let media = Capability.media
        
        media.request { (success, error) in
            self.imagePicker.delegate = self
            self.imagePicker.modalPresentationStyle = .currentContext
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            
            if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                self.imagePicker.mediaTypes = mediaTypes
            }
            
            GCD.onMain {
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    public final func addAttachment() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .import)
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let row = tableData?.getRow(at: indexPath.row) else { return UITableViewAutomaticDimension }
        return row.height
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let row = tableData?.getRow(at: indexPath.row) else { return UITableViewAutomaticDimension }
        guard let cell = tableView.cellForRow(at: indexPath) as? ComposeCell else { return row.height }
        
        let height = cell.textView.fieldHeight
        let expandable = cell.fieldModel?.expanded
        
        if cell.fieldModel?.display == .conditional {
            if ccEnabled {
                if (expandable != nil) && cell.isExpanded { return expandable! }
                if height <= row.height { return row.height }
                return height
            } else {
                return 0
            }
        }
        
        if height <= row.height {
            return row.height
        }
        
        return height
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData?.numberOfRows() ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = tableData?.getRow(at: indexPath.row) else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: row.identifier, for: indexPath) as! ComposeCell
        cell.updateCell(row, indexPath)
        cell.delegate = self
        
        if !allCells.contains(cell) {
            allCells.append(cell)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView is SuggestTableView {
            let identity = suggestTableView.didSelectIdentity(index: indexPath)
            
            guard let cell = self.tableView.cellForRow(at: currentCell) as? RecipientCell else { return }
            cell.addContact(identity!)
            cell.textView.scrollToTop()
            
            self.tableView.updateSize()
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ComposeCell else { return }
        if cell is AccountCell {
            let accountCell = cell as! AccountCell
            accountCell.isExpanded = !accountCell.isExpanded
            accountCell.togglePicker()
            self.tableView.updateSize()
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func cancel() {
        let alertCtrl = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertCtrl.addAction(alertCtrl.action("MailComp.Action.Cancel", .cancel, {}))
        
        alertCtrl.addAction(alertCtrl.action("MailComp.Action.Delete", .destructive, {
            self.dismiss()
        }))
        
        alertCtrl.addAction(alertCtrl.action("MailComp.Action.Save", .default, {
            // Save Daft action here!
            self.dismiss()
        }))
        
        present(alertCtrl, animated: true, completion: nil)
    }
    
    @IBAction func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func send() {
        // Extract all data from composer HERE!!!
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Extensions

extension ComposeTableViewController: ComposeCellDelegate {
    
    func textdidStartEditing(at indexPath: IndexPath, textView: ComposeTextView) {
        if tableData?.ccEnabled != shouldShowCC(for: textView) {
            tableData?.ccEnabled = shouldShowCC(for: textView)
            ccEnabled = (tableData?.ccEnabled)!
            tableView.updateSize(true)
        }
    }
    
    func textdidChange(at indexPath: IndexPath, textView: ComposeTextView) {
        let fModel = tableData?.rows.filter{ $0.type == textView.fieldModel?.type }
        fModel?.first?.value = textView.attributedText
        let suggestContacts = fModel?.first?.contactSuggestion ?? false
        
        currentCell = indexPath
        guard let cell = tableView.cellForRow(at: currentCell) as? ComposeCell else {
            tableView.updateSize()
            return
        }
        
        if suggestContacts {
            if suggestTableView.updateContacts(textView.text) {
                tableView.scrollToTopOf(cell)
                cell.textView.scrollToBottom()
                updateSuggestTable(CGFloat(indexPath.row))
            } else {
                cell.textView.scrollToTop()
                tableView.updateSize()
            }
        } else {
            tableView.updateSize()
        }
    }
    
    func textDidEndEditing(at indexPath: IndexPath, textView: ComposeTextView) {
        tableView.updateSize()
        suggestTableView.hide()
    }
    
    func textShouldReturn(at indexPath: IndexPath, textView: ComposeTextView) {}
}

// MARK: - RecipientCellDelegate

extension ComposeTableViewController: RecipientCellDelegate {
    
    func shouldOpenAddressbook(at indexPath: IndexPath) {
        currentCell = indexPath
        openAddressBook()
    }
}

// MARK: - MessageBodyCellDelegate

extension ComposeTableViewController: MessageBodyCellDelegate {
    
    func didStartEditing(at indexPath: IndexPath) {
        currentCell = indexPath
        let media = UIMenuItem(title: "MenuCtrl.Cameraroll".localized, action: #selector(addMediaToCell))
        let attachment = UIMenuItem(title: "MenuCtrl.Attachment".localized, action: #selector(addAttachment))
        menuController.menuItems = [media, attachment]
    }
    
    func didEndEditing(at indexPath: IndexPath) {
        menuController.menuItems?.removeAll()
    }
}

// MARK: - MessageBodyCellDelegate

extension ComposeTableViewController:
    UIImagePickerControllerDelegate,
    UIDocumentPickerDelegate,
    CNContactPickerDelegate,
    UINavigationControllerDelegate {
    
    // MARK: - CNContactPickerViewController Delegate
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        //guard let cell = tableView.cellForRow(at: currentCell) as? RecipientCell else { return }
        //cell.addContact(contact)
        
        tableView.updateSize()
    }
    
    // MARK: - UIImagePickerController Delegate
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        guard let cell = tableView.cellForRow(at: currentCell) as? MessageBodyCell else { return }
        
        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            if mediaType == kUTTypeMovie as String {
                guard let url = info[UIImagePickerControllerMediaURL] as? URL else { return }
                let attachment = createAttachment(url, true)
                cell.addMovie(attachment)
            } else {
                guard let url = info[UIImagePickerControllerReferenceURL] as? URL else { return }
                guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
                cell.insert(Attachment.inline(name: String(), url: url, type: String(), image: image))
            }
        }
        
        tableView.updateSize()
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIDocumentPicker Delegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard let cell = tableView.cellForRow(at: currentCell) as? MessageBodyCell else { return }
        let attachment = createAttachment(url)
        cell.add(attachment)
        
        tableView.updateSize()
    }
}
