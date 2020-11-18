//
//  EmailViewController2.swift
//  pEp
//
//  Created by Martín Brude on 19/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox
import QuickLook

class EmailViewController2: UIViewController {
    public static let storyboard = "Main"
    public static let storyboardId = "EmailViewController"
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
        if isIpad {
            documentInteractionController.dismissMenu(animated: false)
        }
        splitViewController?.preferredDisplayMode = .allVisible
        coordinator.animate(alongsideTransition: nil)
    }
}

//MARK: - UITableViewDataSource

extension EmailViewController2: UITableViewDataSource {

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
        let row = vm[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: row.cellIdentifier, for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }
        if let contentCell = cell as? MessageContentCell {
            setup(cell: contentCell, with: vm)
        } else if row.type == .sender, let senderCell = cell as? MessageSenderCell {
            setup(cell: senderCell, with: row)
        } else if row.type == .subject, let subjectCell = cell as? MessageSubjectCell {
            setup(cell: subjectCell, with: row)
        } else if row.type == .attachment, let attachmentsCell = cell as? MessageAttachmentsCell {
            setup(cell: attachmentsCell, with: vm)
        }
        return cell
    }
}

//MARK: - UITableViewDelegate

extension EmailViewController2: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let row = viewModel?[indexPath.row] else {
            Log.shared.errorAndCrash("Missing row")
            return tableView.estimatedRowHeight
        }
        if row.type == .body, viewModel?.htmlBody != nil {
            return htmlViewerViewController.contentSize.height
        } else {
            return tableView.rowHeight
        }
    }
}

// MARK: - SecureWebViewControllerDelegate

extension EmailViewController2: SecureWebViewControllerDelegate {
    func didFinishLoading() {
        tableView.updateSize()
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension EmailViewController2: UIPopoverPresentationControllerDelegate, UIPopoverPresentationControllerProtocol {

    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect:
        UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        repositionPopoverTo(rect: rect, in: view)
    }
}

// MARK: - EmailViewModelDelegate

extension EmailViewController2: EmailViewModelDelegate {
    func showQuickLookOfAttachment(qlItem: QLPreviewItem) {
        guard let url = qlItem.previewItemURL else {
            Log.shared.errorAndCrash("QL item is not an URL")
            return
        }
        delegate?.openQLPreviewController(toShowDocumentWithUrl: url)
    }

    func showDocumentsEditor(url: URL) {
        //TODO: test this on iPad
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
}

//MARK: - Private

extension EmailViewController2 {

    @IBAction private func showExternalContent() {
        viewModel?.shouldShowExternalContent = false
        tableView.reloadData()
    }

    private func removeExternalContentView() {
        showExternalContentView.isHidden = true
    }

    private func setup(cell: MessageContentCell, with vm: EmailViewModel) {
        if let htmlBody = viewModel?.htmlBody {
            cell.contentView.addSubview(htmlViewerViewController.view)
            htmlViewerViewController.view.fullSizeInSuperView()
            if htmlBody.containsExternalContent() && vm.shouldShowHtmlViewer {
                showExternalContentView.isHidden = false
            } else if !vm.shouldShowHtmlViewer {
                removeExternalContentView()
            }
            htmlViewerViewController.display(html: htmlBody, showExternalContent: vm.shouldShowExternalContent)
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

    private func setup(cell: MessageSenderCell, with row: EmailRowProtocol) {
        let font = UIFont.pepFont(style: .footnote, weight: .semibold)
        cell.titleLabel?.font = font
        cell.titleLabel?.text = row.firstValue
        if let subtitle = row.secondValue {
            let attributes = [NSAttributedString.Key.font: font,
                              NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            cell.valueLabel?.attributedText = NSAttributedString(string: subtitle, attributes: attributes)
        }
    }

    private func setup(cell: MessageSubjectCell, with row: EmailRowProtocol) {
        cell.titleLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        cell.titleLabel?.text = row.firstValue
        if let value =  row.secondValue {
            cell.valueLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
            cell.valueLabel?.text = value
            cell.valueLabel?.isHidden = false
        } else {
            cell.valueLabel?.text = nil
            cell.valueLabel?.isHidden = true
        }
    }

    private func setup(cell: MessageAttachmentsCell, with vm: EmailViewModel) {
        // Work around auto-layout problems
        cell.contentView.heightAnchor.constraint(equalToConstant: 0).isActive = !vm.hasAttachments
        cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = vm.hasAttachments
        var attachmentViewContainers = [AttachmentViewContainer2]()
        let attachmentView = AttachmentsView()
        vm.attachmentInformation { (informations) in
            informations?.forEach { (info) in
                if info.image != .none {
                    let imageView = UIImageView(image: info.image)
                    let container = AttachmentViewContainer2(view: imageView, info: info)
                    attachmentViewContainers.append(container)
                }
            }
            attachmentView.attachmentViewContainers2 = attachmentViewContainers
            cell.attachmentsImageView = attachmentView
            self.tableView.updateSize()
        }
    }
}
