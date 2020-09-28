//
//  EmailViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit
import QuickLook

import pEpIOSToolbox
import MessageModel

protocol EmailViewControllerDelegate: class {
    func showPdfPreview(forPdfAt url: URL)
}

class EmailViewController: BaseTableViewController {
    private var tableData: ComposeDataSource?
    lazy private var documentInteractionController = UIDocumentInteractionController()
    private var clientCertificateImportViewController: ClientCertificateImportViewController?

    static public let storyboard = "Main"
    static let storyboardId = "EmailViewController"
    weak var delegate: EmailViewControllerDelegate?
    var message: Message?
    lazy var clickHandler: UrlClickHandler = {
        return UrlClickHandler(appConfig: appConfig)
    }()

    // MARK: - LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        loadDatasource("MessageData")
        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTableRows()
    }

    private func configureTableRows() {
        tableData?.filterRows(message: message)
    }

    private final func loadDatasource(_ file: String) {
        if let path = Bundle.main.path(forResource: file, ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                tableData = ComposeDataSource(with: dict["Rows"] as! [[String: Any]])
            }
        }
    }

    // MARK: - EMAIL BODY

    /**
     Indicate that the htmlViewerViewController already exists, to avoid
     instantiation just to check if it has been instantiated.
     */
    var htmlViewerViewControllerExists = false

    lazy private var htmlViewerViewController: SecureWebViewController = {
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

    /**
     Yields the HTML message body if:
     * we can show it in a secure way
     * we have non-empty HTML content at all
     - Returns: The HTML message body or nil
     */
    private func htmlBody(message: Message?) ->  String? {
        guard
            let m = message,
            let htmlBody = m.longMessageFormatted,
            !htmlBody.isEmpty else {
                return nil
        }
        return htmlBody
    }

    private func setup(contentCell: MessageContentCell, rowData: ComposeFieldModel) {
        guard let m = message else {
            Log.shared.errorAndCrash("No msg.")
            return
        }
        if let htmlBody = htmlBody(message: m) {
            // We do have HTML content.
            contentCell.contentView.addSubview(htmlViewerViewController.view)
            htmlViewerViewController.view.fullSizeInSuperView()
            let displayHtml = appendInlinedPlainText(fromAttachmentsIn: m, to: htmlBody)
            htmlViewerViewController.display(html: displayHtml)
        } else {
            // We do not have HTML content.
            // Remove the HTML view if we just stepped from an HTML mail to one without
            if htmlViewerViewControllerExists &&
                htmlViewerViewController.view.superview == contentCell.contentView {
                htmlViewerViewController.view.removeFromSuperview()
            }
            contentCell.updateCell(model: rowData, message: m, clickHandler: clickHandler)
        }
    }

    private func appendInlinedPlainText(fromAttachmentsIn message: Message, to text: String) -> String {
        var result = text
        let inlinedText = message.inlinedTextAttachments()
        for inlinedTextAttachment in inlinedText {
            guard
                let data = inlinedTextAttachment.data,
                let inlinedText = String(data: data, encoding: .utf8) else {
                    continue
            }
            result = append(appendText: inlinedText, to: result)
        }
        return result
    }

    private func append(appendText: String, to body: String) -> String {
        var result = body
        let replacee = result.contains(find: "</body>") ? "</body>" : "</html>"
        if result.contains(find: replacee) {
            result = result.replacingOccurrences(of: replacee, with: appendText + replacee)
        } else {
            result += "\n" + appendText
        }
        return result
    }
}

// MARK: - UITableViewDataSource

extension EmailViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData?.numberOfRows() ?? 0
    }

    override func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let row = tableData?.getRow(at: indexPath.row),
            let cell = tableView.dequeueReusableCell(withIdentifier: row.identifier,
                                                     for: indexPath) as? MessageCell,
            let m = message
            else {
                return UITableViewCell()
        }
        if let contentCell = cell as? MessageContentCell {
            setup(contentCell: contentCell, rowData: row)
        } else {
            cell.updateCell(model: row, message: m)
        }
        cell.delegate = self
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let row = tableData?.getRow(at: indexPath.row) else {
                Log.shared.errorAndCrash("Missing data")
                return tableView.estimatedRowHeight
        }

        if row.type == .content, htmlBody(message: message) != nil {
            return htmlViewerViewController.contentSize.height
        } else {
            return tableView.rowHeight
        }
    }
}

// MARK: - MessageContentCellDelegate

extension EmailViewController: MessageContentCellDelegate {
    func heightChanged() {
        tableView.updateSize()
    }
}

extension EmailViewController {

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            documentInteractionController.dismissMenu(animated: false)
        }

        splitViewController?.preferredDisplayMode = .allVisible

        coordinator.animate(alongsideTransition: nil)
    }
}

// MARK: - MessageAttachmentDelegate

extension EmailViewController: MessageAttachmentDelegate {

    func didTap(cell: MessageCell, attachment: Attachment, location: CGPoint, inView: UIView?) {
        let busyState = inView?.displayAsBusy()
        attachment.saveToTmpDirectory { [weak self] url in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let url = url else {
                Log.shared.errorAndCrash("No Local URL")
                return
            }
            let safeAttachment = attachment.safeForSession(Session.main)
            GCD.onMain {
                defer {
                    if let bState = busyState {
                        inView?.stopDisplayingAsBusy(viewBusyState: bState)
                    }
                }
                me.showToUser(documentAt: url,
                              givenMimeType: safeAttachment.mimeType,
                              representedBy: cell,
                              showAt: location,
                              in: inView)
            }
        }
    }

    private func showToUser(documentAt url: URL,
                            givenMimeType: String?,
                            representedBy cell: MessageCell,
                            showAt location: CGPoint,
                            in view: UIView?) {
        let mimeType = MimeTypeUtils.findBestMimeType(forFileAt: url,
                                                      withGivenMimeType: givenMimeType)

        if url.pathExtension == "pEp12" || url.pathExtension == "pfx" {
            setupClientCertificateImportViewController(forClientCertificateAt: url)
            guard let vc = clientCertificateImportViewController else {
                Log.shared.errorAndCrash("No VC")
                return
            }
            present(vc, animated: true)
        } else if mimeType == MimeTypeUtils.MimesType.pdf
            && QLPreviewController.canPreview(url as QLPreviewItem) {
            delegate?.showPdfPreview(forPdfAt: url)
        } else {
            documentInteractionController.url = url
            let presentingView = view ?? cell
            let dim: CGFloat = 40
            let rect = CGRect.rectAround(center: location, width: dim, height: dim)
            documentInteractionController.presentOptionsMenu(from: rect,
                                                             in: presentingView,
                                                             animated: true)
        }
    }

    private func setupClientCertificateImportViewController(forClientCertificateAt url: URL) {
        guard let vc = UIStoryboard.init(name: "Certificates", bundle: nil)
            .instantiateViewController(withIdentifier: ClientCertificateImportViewController.storyboadIdentifier) as? ClientCertificateImportViewController else {
                Log.shared.errorAndCrash("No VC")
            return
        }
        vc.viewModel = ClientCertificateImportViewModel(certificateUrl: url, delegate: vc)
        vc.modalPresentationStyle = .fullScreen
        clientCertificateImportViewController = vc
    }
}

// MARK: - SecureWebViewControllerDelegate

extension EmailViewController: SecureWebViewControllerDelegate {
    func didFinishLoading() {
        tableView.updateSize()
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension EmailViewController: UIPopoverPresentationControllerDelegate {

    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect:
        UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {

        guard let titleView = navigationItem.titleView else {
            return
        }

        rect.initialize(to: CGRect(x:titleView.bounds.midY,
                                   y: titleView.bounds.midX,
                                   width:0,
                                   height:0))
        view.pointee = titleView
    }
}
