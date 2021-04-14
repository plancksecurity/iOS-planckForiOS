//
//  EmailViewController.swift
//  pEp
//
//  Created by Martín Brude on 19/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox
import QuickLook
import ContactsUI

protocol EmailViewControllerDelegate: class {
    func openQLPreviewController(toShowDocumentWithUrl url: URL)
    func showContactsViewController(controller: CNContactViewController)
}

class EmailViewController: UIViewController {

    private var recipientLabelHeight: CGFloat = 15
    private let recipientLabelPadding: CGFloat = 0
    private let recipientLabelSpacingX: CGFloat = 2
    private let recipientLabelSpacingY: CGFloat = 0

    public var viewModel: EmailViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }
    public weak var delegate: EmailViewControllerDelegate?

    private var htmlViewerViewControllerExists = false
    private var busyState: ViewBusyState?
    private lazy var documentInteractionController = UIDocumentInteractionController()
    private lazy var clickHandler: UrlClickHandler = {
        return UrlClickHandler()
    }()

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var showExternalContentView: UIView!
    @IBOutlet private weak var showExternalContentButton: UIButton!
    @IBOutlet private weak var showExternalContentLabel: UILabel!

    private lazy var htmlViewerViewController: SecureWebViewController = {
        let storyboard = UIStoryboard(name: "Reusable", bundle: nil)
        guard let vc =
                storyboard.instantiateViewController(withIdentifier: SecureWebViewController.storyboardId)
                as? SecureWebViewController
        else {
            Log.shared.errorAndCrash("Cast error")
            return SecureWebViewController()
        }
        vc.zoomingEnabled = true
        vc.delegate = self
        vc.urlClickHandler = clickHandler
        htmlViewerViewControllerExists = true
        return vc
    }()

    // MARK: - ViewController LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        showExternalContentLabel.text = Localized.showExternalContentText
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.title = title
        tableView.hideSeperatorForEmptyCells()
        removeExternalContentView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.isIpad {
            documentInteractionController.dismissMenu(animated: false)
        }
        splitViewController?.preferredDisplayMode = .allVisible
        coordinator.animate(alongsideTransition: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case. Optional param.
            tableView.reloadData()
            return
        }

        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                tableView.reloadData()
                return
            }
        }

        /// If size classes change, we need to reload.
        if ((traitCollection.verticalSizeClass != thePreviousTraitCollection.verticalSizeClass) || (traitCollection.horizontalSizeClass != thePreviousTraitCollection.horizontalSizeClass)) {
            tableView.reloadData()
        }
    }

    // MARK: - IBActions

    @IBAction func showExternalContentButtonPressed() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleShowExternalContentButtonPressed()
    }
}

//MARK: - UITableViewDataSource

extension EmailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }
        return vm.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return UITableViewCell()
        }
        let cellIdentifier = vm.cellIdentifier(for: indexPath)
        let row = vm[indexPath.row]
        switch row.type {
        case .sender:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MessageSenderCell else {
                return UITableViewCell()
            }
            guard let row = vm[indexPath.row] as? EmailViewModel.SenderRow else {
                Log.shared.errorAndCrash("Can't get or cast sender row")
                return cell
            }
            setupSender(cell: cell, with: row)
            return cell
        case .subject:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MessageSubjectCell else {
                return UITableViewCell()
            }
            guard let row = vm[indexPath.row] as? EmailViewModel.SubjectRow else {
                Log.shared.errorAndCrash("Can't get or cast sender row")
                return cell
            }
            setupSubject(cell: cell, with: row)
            return cell
        case .body:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MessageBodyCell else {
                return UITableViewCell()
            }
            guard let row = vm[indexPath.row] as? EmailViewModel.BodyRow else {
                Log.shared.errorAndCrash("Can't get or cast sender row")
                return cell
            }
            setupBody(cell: cell, with: row, indexPath: indexPath)
            return cell
        case .attachment:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MessageAttachmentCell else {
                return UITableViewCell()
            }
            guard let row = vm[indexPath.row] as? EmailViewModel.BaseAttachmentRow else {
                Log.shared.errorAndCrash("Can't get or cast attachment row")
                return cell
            }
            setupAttachment(cell: cell, with: row)
            return cell

        case .imageAttachment:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MessageImageAttachmentCell else {
                return UITableViewCell()
            }
            guard let row = vm[indexPath.row] as? EmailViewModel.ImageAttachmentRow else {
                Log.shared.errorAndCrash("Can't get or cast attachment row")
                return cell
            }
            setupImageAttachment(cell: cell, row: row, indexPath: indexPath)
            return cell
        }
    }
}

//MARK: - UITableViewDelegate

extension EmailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Missing vm")
            return tableView.estimatedRowHeight
        }
        if let row = vm[indexPath.row] as? EmailViewModel.AttachmentRow {
            return row.height
        }
        if (vm[indexPath.row] as? EmailViewModel.BodyRow)?.htmlBody != nil {
            return htmlViewerViewController.contentSize.height
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Missing vm")
            return
        }
        let row = vm[indexPath.row]
        if row.type == .attachment || row.type == .imageAttachment {
            vm.handleDidTapAttachmentRow(at: indexPath)
        }
    }
}

// MARK: - SecureWebViewControllerDelegate

extension EmailViewController: SecureWebViewControllerDelegate {
    func didFinishLoading() {
        tableView.updateSize()
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension EmailViewController: UIPopoverPresentationControllerDelegate, UIPopoverPresentationControllerProtocol {

    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController,
                                       willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>,
                                       in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        repositionPopoverTo(rect: rect, in: view)
    }
}

// MARK: - EmailViewModelDelegate

extension EmailViewController: EmailViewModelDelegate {

    func showQuickLookOfAttachment(quickLookItem: QLPreviewItem) {
        guard let url = quickLookItem.previewItemURL else {
            Log.shared.errorAndCrash("QL item is not an URL")
            return
        }
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("Delegate not found")
            return
        }
        delegate.openQLPreviewController(toShowDocumentWithUrl: url)
    }

    func showDocumentsEditor(url: URL) {
        documentInteractionController.url = url
        let dim: CGFloat = 40
        let rect = CGRect.rectAround(center: view.center, width: dim, height: dim)
        documentInteractionController.presentOptionsMenu(from: rect, in: view, animated: true)
    }

    func showClientCertificateImport(viewModel: ClientCertificateImportViewModel) {
        guard let vc = UIStoryboard.init(name: Constants.certificatesStoryboard, bundle: nil)
                .instantiateViewController(withIdentifier: ClientCertificateImportViewController.storyboadIdentifier) as? ClientCertificateImportViewController else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        viewModel.delegate = vc
        vc.viewModel = viewModel
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    func showLoadingView() {
        busyState = view.displayAsBusy()
    }

    func hideLoadingView() {
        guard let busyState = busyState else {
            // Valid case: the view state might not be busy anymore.
            return
        }
        view.stopDisplayingAsBusy(viewBusyState: busyState)
    }

    func showExternalContent() {
        removeExternalContentView()
        tableView.reloadData()
    }

    func showAddNewContact(contact: CNContact) {
        let contactViewController = CNContactViewController(forNewContact: contact)
        show(contactViewController: contactViewController)
    }

    func showEditContact(contact: CNContact) {
        let contactViewController = CNContactViewController(for: contact)
        show(contactViewController: contactViewController)
    }

    private func show(contactViewController: CNContactViewController) {
        UIUtils.presentContactViewController(viewController: contactViewController)
    }

}

//MARK: - Private

extension EmailViewController {

    private func removeExternalContentView() {
        showExternalContentView.isHidden = true
    }

    private func setupBody(cell: MessageBodyCell, with row: EmailViewModel.BodyRow, indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Missing vm")
            return
        }
        if let htmlBody = row.htmlBody {
            cell.contentView.addSubview(htmlViewerViewController.view)
            htmlViewerViewController.view.fullSizeInSuperView()
            showExternalContentView.isHidden = !vm.shouldShowExternalContentView
            htmlViewerViewController.display(html: htmlBody, showExternalContent: !vm.shouldShowExternalContentView)
        } else {
            // We do not have HTML content.
            // Remove the HTML view if we just stepped from an HTML mail to one without
            if htmlViewerViewControllerExists &&
                htmlViewerViewController.view.superview == cell.contentView {
                htmlViewerViewController.view.removeFromSuperview()
            }
            row.body { [weak self] (body) in
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    return
                }
                cell.contentText.attributedText = body
                cell.contentText.dataDetectorTypes = .link
                cell.contentText.delegate = me.clickHandler
                me.updateSizeIfLastCell(indexPath: indexPath)
            }
        }
    }

    private func setupSender(cell: MessageSenderCell, with row: EmailViewModel.SenderRow) {
        func display(_ buttons: [UIButton]) {
            let containerWidth = cell.toContainer.frame.size.width
            var currentOriginX: CGFloat = 0
            var currentOriginY: CGFloat = 0

            buttons.forEach { button in
                // if current origin X + label width is be greater than the container view width
                // move the label to next row
                if currentOriginX + button.frame.width > containerWidth {
                    currentOriginX = 0
                    currentOriginY += recipientLabelHeight + recipientLabelSpacingY
                }

                // set the frame origin
                button.frame.origin.x = currentOriginX
                button.frame.origin.y = currentOriginY

                // increment current X by btn width + spacing
                currentOriginX += button.frame.width + recipientLabelSpacingX
            }
            // update container view height
            cell.containerHeightConstraint.constant = currentOriginY + recipientLabelHeight
        }
        //Setup from label
        cell.fromLabel.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        cell.fromLabel.text = row.from

        //Setup to recipeints
        cell.toContainer.subviews.forEach({$0.removeFromSuperview()})
        var recipientButtons = [UIButton]()
        let toText = NSLocalizedString("To:", comment: "To: - To label")
        var textsToShow = [toText]
        textsToShow.append(contentsOf: row.recipients)
        textsToShow.forEach { (textToShow) in
            let recipientButton = RecipientButton.with(text: textToShow)
            recipientLabelHeight = recipientButton.frame.height
            recipientButton.frame.size.width = recipientButton.intrinsicContentSize.width + recipientLabelPadding
            recipientButton.frame.size.height = recipientLabelHeight
            // 'To:' shouldn't be tappable.
            recipientButton.isUserInteractionEnabled = textToShow != toText
            recipientButton.addTarget(self, action: #selector(addressButtonPressed), for: .touchUpInside)
            cell.toContainer.addSubview(recipientButton)
            recipientButtons.append(recipientButton)
        }
        display(recipientButtons)
    }

    @objc func addressButtonPressed(button: UIButton) {
        guard let address = button.titleLabel?.text, address.isProbablyValidEmail() else {
            // Valid case, nothing to do:
            return
        }

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        vm.handleAddressButtonPressed(address: address)
    }

    private func setupSubject(cell: MessageSubjectCell, with row: EmailViewModel.SubjectRow) {
        cell.subjectLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        cell.subjectLabel?.text = row.title
        if let date = row.date {
            cell.dateLabel.font = UIFont.pepFont(style: .footnote, weight: .semibold)
            cell.dateLabel.text = date
            cell.dateLabel.isHidden = false
        } else {
            cell.dateLabel.text = nil
            cell.dateLabel.isHidden = true
        }
    }

    private func setupAttachment(cell: MessageAttachmentCell, with row: EmailViewModel.BaseAttachmentRow) {
        row.retrieveAttachmentData { () in
            cell.fileNameLabel.text = row.filename
            cell.iconImageView.image = row.icon
            cell.fileExtensionLabel.text = row.fileExtension
        }
    }

    private func setupImageAttachment(cell: MessageImageAttachmentCell,
                                      row: EmailViewModel.ImageAttachmentRow,
                                      indexPath: IndexPath) {
        func setupCellFromRowData() {
            guard var image = row.icon else {
                Log.shared.errorAndCrash("No image in a ImageAttachmentRow")
                return
            }
            if image.size.width > cell.frame.size.width {
                image = image.resized(newWidth: cell.frame.width) ?? image
            }
            cell.imageAttachmentView?.image = image
            updateSizeIfLastCell(indexPath: indexPath)
        }
        row.retrieveAttachmentData() {
            setupCellFromRowData()
        }
    }

    /// Update table view size in case the indexPath corresponds to the last cell.
    /// - Parameter indexPath: The indexPath of the cell to evaluate
    private func updateSizeIfLastCell(indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        if indexPath.row == vm.numberOfRows - 1 {
            tableView.updateSize()
        }
    }
}

extension EmailViewController {
    private struct Localized {
        static let showExternalContentText = NSLocalizedString("""
By showing external content, your privacy may be invaded.
This may affect the privacy status of the message.
""", comment: "external content label text")
    }
}


// MARK: - CNContactViewController

extension EmailViewController: CNContactViewControllerDelegate {

}
