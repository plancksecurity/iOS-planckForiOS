//
//  EmailViewController.swift
//  pEp
//
//  Created by Martín Brude on 19/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox
import QuickLook

protocol EmailViewControllerDelegate: class {
    func openQLPreviewController(toShowDocumentWithUrl url: URL)
}

class EmailViewController: UIViewController {
    public var viewModel: EmailViewModel?
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
        showExternalContentButton.backgroundColor = UIColor.pEpGreen
        showExternalContentButton.tintColor = UIColor.white
        showExternalContentLabel.text = NSLocalizedString("""
 By showing external content, your privacy may be invaded.
 This may affect the privacy status of the message.
""", comment: "external content label text")
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

    // MARK: - IBActions

    @IBAction func showExternalContentButtonPressed() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleDidTapShowExternalContentButton()
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
        let cellId = vm.cellIdentifier(for: indexPath)
        let row = vm[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }
        switch row.type {
        case .subject:
            setupSubject(cell: cell, with: row)
            return cell
        case .body:
            guard let dequeued = cell as? MessageContentCell else {
                Log.shared.errorAndCrash("Invalid state.")
                return UITableViewCell()
            }
            setup(cell: dequeued, with: vm)
            return dequeued
        case .attachment:
            guard let dequeued = cell as? MessageAttachmentCell else {
                Log.shared.errorAndCrash("Invalid state.")
                return UITableViewCell()
            }
            setup(cell: dequeued, with: row)
            return dequeued
        case .to:
            setupSender(cell: cell, with: row)
            return cell
        case .cc:
            setupSender(cell: cell, with: row)
            return cell
        case .bcc:
            setupSender(cell: cell, with: row)
            return cell
        }
    }

    private func isLastRow(indexPath: IndexPath) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return false
        }
        return indexPath.row == vm.numberOfRows - 1
    }
}

//MARK: - UITableViewDelegate

extension EmailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isLastRow(indexPath: indexPath) {
            guard let vm = viewModel else {
                Log.shared.errorAndCrash("No VM")
                return
            }
            vm.retrieveAttachments()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Missing vm")
            return tableView.estimatedRowHeight
        }
        let row = vm[indexPath.row]
        if row.type == .attachment {
            return row.height
        }
        if row.type == .body, viewModel?.htmlBody != nil {
            return htmlViewerViewController.contentSize.height
        } else {
            return tableView.rowHeight
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Missing vm")
            return
        }
        let row = vm[indexPath.row]
        if row.type == .attachment {
            vm.handleDidTapAttachment(at: indexPath)
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

    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect:
        UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        repositionPopoverTo(rect: rect, in: view)
    }
}

// MARK: - EmailViewModelDelegate

extension EmailViewController: EmailViewModelDelegate {

    func showQuickLookOfAttachment(qlItem: QLPreviewItem) {
        guard let url = qlItem.previewItemURL else {
            Log.shared.errorAndCrash("QL item is not an URL")
            return
        }
        delegate?.openQLPreviewController(toShowDocumentWithUrl: url)
    }

    func showDocumentsEditor(url: URL) {
        documentInteractionController.url = url
        let dim: CGFloat = 40
        let rect = CGRect.rectAround(center: view.center, width: dim, height: dim)
        documentInteractionController.presentOptionsMenu(from: rect, in: view, animated: true)
    }

    func showClientCertificateImport(viewModel: ClientCertificateImportViewModel) {
        guard let vc = UIStoryboard.init(name: "Certificates", bundle: nil)
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

    func didSetAttachments(forRowsAt indexPaths: [IndexPath]) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("Missing vm")
            return
        }
        indexPaths.forEach { (indexPath) in
            guard let cell = tableView.cellForRow(at: indexPath) as? MessageAttachmentCell else {
                // Valid case. We might have been dismissed already.
                return
            }
            let row = vm[indexPath.row]
            cell.nameLabel.text = row.firstValue
            cell.extensionLabel.text = row.secondValue
            cell.iconImageView.image = row.image
        }
        vm.didRetrieveAttachments = true
    }

    func showExternalContent() {
        removeExternalContentView()
        tableView.reloadData()
    }
}

//MARK: - Private

extension EmailViewController {

    private func removeExternalContentView() {
        showExternalContentView.isHidden = true
    }

    private func setup(cell: MessageContentCell, with vm: EmailViewModel) {
        if let htmlBody = viewModel?.htmlBody {
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
            vm.body { [weak self] (body) in
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    return
                }
                cell.contentText.attributedText = body
                cell.contentText.tintColor = UIColor.pEpGreen
                cell.contentText.dataDetectorTypes = .link
                cell.contentText.delegate = me.clickHandler
                me.tableView.updateSize()
            }
        }
    }

    private func setupSender(cell: MessageCell, with row: EmailRowProtocol) {
        let font = UIFont.pepFont(style: .footnote, weight: .semibold)
        cell.titleLabel?.font = font
        cell.titleLabel?.text = row.firstValue
        if let subtitle = row.secondValue {
            let attributes = [NSAttributedString.Key.font: font,
                              NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            cell.valueLabel?.attributedText = NSAttributedString(string: subtitle, attributes: attributes)
        }
    }

    private func setupSubject(cell: MessageCell, with row: EmailRowProtocol) {
        cell.titleLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        cell.titleLabel?.text = row.firstValue
        if let value = row.secondValue {
            cell.valueLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
            cell.valueLabel?.text = value
            cell.valueLabel?.isHidden = false
        } else {
            cell.valueLabel?.text = nil
            cell.valueLabel?.isHidden = true
        }
    }

    private func setup(cell: MessageAttachmentCell, with row: EmailRowProtocol) {
        cell.nameLabel.text = row.firstValue ?? ""
        cell.iconImageView.image = row.image ?? nil
        cell.extensionLabel.text = row.secondValue ?? ""
    }
}
