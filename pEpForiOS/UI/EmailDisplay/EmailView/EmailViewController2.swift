//
//  EmailViewController2.swift
//  pEp
//
//  Created by Martín Brude on 19/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import QuickLook

class EmailViewController2: UIViewController {

    public var viewModel: EmailViewModel?
    public weak var delegate: EmailViewControllerDelegate?

    private lazy var documentInteractionController = UIDocumentInteractionController()
    private var clientCertificateImportViewController: ClientCertificateImportViewController?
    private static let storyboard = "Main"
    private static let storyboardId = "EmailViewController"
    private lazy var clickHandler: UrlClickHandler = {
        return UrlClickHandler()
    }()
    private var htmlViewerViewControllerExists = false
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var showExternalContentView: UIView!
    @IBOutlet private weak var showExternalContentButton: UIButton!
    @IBOutlet private weak var showExternalContentLabel: UILabel!
    @IBAction private func showExternalContent() {
        viewModel?.shouldShowExternalContentButton = false
        tableView.reloadData()
    }

    private func removeExternalContentView() {
        showExternalContentView.isHidden = true
    }

    // MARK: - ViewController LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
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

// MARK: - Client Certificate

extension EmailViewController2 {
    //MB:- Who calls this?
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

extension EmailViewController2: EmailViewModelDelegate {
    func showQuickLookOfAttachment(qlItem: QLPreviewItem) {

    }

    func showDocumentsEditor(url: URL) {

    }

    func showClientCertificateImport(viewModel: ClientCertificateImportViewModel) {

    }

    func showLoadingView() {

    }

    func hideLoadingView() {
        
    }

    
}
