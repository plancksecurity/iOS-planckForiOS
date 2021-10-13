//
//  EmailViewController.swift
//  pEp
//
//  Created by Martín Brude on 19/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox
import QuickLook

import EventKit
import EventKitUI
import pEpIOSToolbox

protocol EmailViewControllerDelegate: AnyObject {
    func openQLPreviewController(toShowDocumentWithUrl url: URL)
}

class EmailViewController: UIViewController {

    @IBOutlet private weak var bannerContainerView: UIView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var bannerHeightConstraint: NSLayoutConstraint!

    public var viewModel: EmailViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    public weak var delegate: EmailViewControllerDelegate?

    // When is 'true', there are no recipients grouped under the '& X more' button.
    private var shouldDisplayAll: [EmailViewModel.RecipientType: Bool] = [EmailViewModel.RecipientType.to: false,
                                                                          EmailViewModel.RecipientType.cc: false,
                                                                          EmailViewModel.RecipientType.bcc: false]
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pEpSettingsChanged),
                                               name: .pEpSettingsChanged,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(copyToClip),
                                               name: UIPasteboard.changedNotification,
                                               object: nil)

        showExternalContentLabel.text = Localized.showExternalContentText
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        if let container = container as? CalendarEventBannerViewController, !bannerContainerView.isHidden {
            bannerHeightConstraint?.constant = container.preferredContentSize.height
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.title = title
        tableView.hideSeperatorForEmptyCells()
        removeExternalContentView()
    }



    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.isIpad {
            documentInteractionController.dismissMenu(animated: false)
        }
        splitViewController?.preferredDisplayMode = .allVisible
        coordinator.animate(alongsideTransition: nil) { [weak self] context in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.tableView.reloadData()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case. Optional param.
            reloadTableView()
            return
        }
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            reloadTableView()
            return
        }
        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                reloadTableView()
                return
            }
        }
        if ((traitCollection.verticalSizeClass != thePreviousTraitCollection.verticalSizeClass)
            || (traitCollection.horizontalSizeClass != thePreviousTraitCollection.horizontalSizeClass)) {
            reloadTableView()
        }
    }


    @objc func copyToClip() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleCopy(maxWidth: tableView.frame.size.width)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        case .header:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MessageHeaderCell else {
                return UITableViewCell()
            }
            guard let row = vm[indexPath.row] as? EmailViewModel.HeaderRow else {
                Log.shared.errorAndCrash("Can't get or cast sender row")
                return cell
            }
            setupHeader(cell: cell, row: row)
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
}

extension EmailViewController {
    private struct Localized {
        static let showExternalContentText = NSLocalizedString("""
By showing external content, your privacy may be invaded.
This may affect the privacy status of the message.
""", comment: "external content label text")
    }
}

//MARK: - pEp Settings Changed

extension EmailViewController {

    @objc func pEpSettingsChanged() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        /// The delegate will be assing in didSet
        viewModel = vm.copy()
        tableView.reloadData()
    }
}

// MARK: - MessageHeaderCellDelegate

extension EmailViewController: MessageHeaderCellDelegate {

    func displayAllRecipients(recipientType: EmailViewModel.RecipientType) {
        shouldDisplayAll[recipientType] = true
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // This workaround prevents a wrong layout in the collection view of the recipient fields.
        // For some unknown reason it seems to layout the cells in a container of the size of what's in the IB, ignoring the real device dimensions.
        tableView.reloadData()
    }
}

//MARK: - Segue

extension EmailViewController: SegueHandlerType {

    enum SegueIdentifier: String {
        case segueCalendarBanner
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        let segueId = segueIdentifier(for: segue)
        switch segueId {
        case .segueCalendarBanner:
            guard
                let vc = segue.destination as? CalendarEventBannerViewController else {
                    Log.shared.errorAndCrash("Missing VCs")
                    return
            }
            guard let calendarEventBannerViewModel = vm.getCalendarEventBannerViewModel(delegate: self) else {
                return
            }
            vc.viewModel = calendarEventBannerViewModel
            bannerContainerView.isHidden = !calendarEventBannerViewModel.shouldShowEventsBanner
        }
    }
}

//MARK: - CalendarEventBannerViewModelDelegate

extension EmailViewController: CalendarEventBannerViewModelDelegate {
    func dismiss() {
        bannerContainerView.isHidden = true
        stackView.layoutIfNeeded()
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
                // We have to update size (not `updateSizeIfLastCell()`) here even if we are not
                // the last cell. `row.body` is async and the completion block might be called
                // after loding the last row (e.g. some attachment), which will lead to the
                // bodyRowTextview size never updated and thus invisible for the user. The backside
                // is that we might call `updateSize()` twice, once after oading the last attachment
                // row, once here. See IOS-2832.
                me.tableView.updateSize()
            }
        }
    }

    private func setupHeader(cell: MessageHeaderCell, row: EmailViewModel.HeaderRow) {
        cell.setup(row:row, shouldDisplayAll: shouldDisplayAll, delegate: self)
    }

    private func setupSubject(cell: MessageSubjectCell, with row: EmailViewModel.SubjectRow) {
        cell.subjectLabel?.font = UIFont.pepFont(style: .headline, weight: .semibold)
        cell.subjectLabel?.text = row.title
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

    private func setBannerVisible(isVisible: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: [], animations: { [weak self] in
                guard let me = self else {
                    //Valid case: might be dismissed already.
                    return
                }
                me.bannerContainerView.isHidden = !isVisible
                me.stackView.layoutIfNeeded()
            }, completion: nil)
        }
    }

    private func reloadTableView() {
        // This workaround fix a timming issue on the re-layout flow when rotating the device.
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
