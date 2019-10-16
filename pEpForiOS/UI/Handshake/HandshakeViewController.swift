//
//  HandshakeViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import MessageModel
import PEPObjCAdapterFramework

/// READ!!!
/// Only set session, if the message was create on a private session. Else leave it nil.
/// Or i will just crash or maybe deadlock you :)
class HandshakeViewController: BaseTableViewController {
    private var backTitle: String?
    private var currentLanguageCode = Locale.current.languageCode ?? "en"
    private let identityViewModelCache = NSCache<Identity, HandshakePartnerTableViewCellViewModel>()

    private var indexPathRequestingLanguage: IndexPath?

    var message: Message? {
        didSet {
            handshakePartnerTableViewCellViewModel = handshakePartnerTableViewCellViewModels()
        }
    }

    private var session: Session? {
        return message?.session
    }
    var handshakePartnerTableViewCellViewModel = [HandshakePartnerTableViewCellViewModel]()

    /// Our own undo manager
    private let undoTrustOrMistrustManager = UndoManager()

    private var orientationChangeObserver: NSObjectProtocol?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 200.0
        tableView.rowHeight = UITableView.automaticDimension

        self.navigationItem.rightBarButtonItems = [languageButton()]

        let leftItem = UIBarButtonItem(customView: backButton())
        self.navigationItem.leftBarButtonItem = leftItem
        navigationController?.navigationBar.isTranslucent = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatusBadge()
        orientationChangeObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: OperationQueue.main) { [weak self] notification in
                self?.tableView.updateSize()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = orientationChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Target & Action

extension HandshakeViewController {
    @IBAction
    private func languageSelectedAction(_ sender: Any) {
        var languages: [PEPLanguage] = []
        do {
            languages = try PEPSession().languageList()
        } catch let err as NSError {
            Log.shared.error("%@", "\(err)")
            languages = []
        }

        let alertController = UIAlertController.pEpAlertController(title: nil,
                                                                   message: nil,
                                                                   preferredStyle: .actionSheet)

        for language in languages {
            let action =   UIAlertAction(title: language.name, style: .default) {_ in
                self.currentLanguageCode = language.code
                self.tableView.reloadData()
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }

        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Private

extension HandshakeViewController {

    private func updateStatusBadge() {
        showNavigationBarSecurityBadge(pEpRating: message?.pEpRating())
    }

    // MARK: - UI & Layout

    @objc
    private func back(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    private func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    /// Creates an overlay view of the globe and adds it to the given view in such a way
    /// that it will cover as much space as possible while not exceeding the parent view
    /// and maintaining aspect ratio.
    ///
    /// - Parameter parentView: The view (which is probably a button) to overlay.
    /// - Returns: The newly created overlay view that has been added to the given view.
    @discardableResult private func addLanguageButtonView(parentView: UIView) -> UIView {
        let totalHeightGap: CGFloat = 16 // Combined max gap to parent, top and bottom
        let img = UIImage(named: "pEpForiOS-icon-languagechange")

        let imgView = UIImageView(image: img)
        parentView.addSubview(imgView)

        // Turn off automatically created constraints that come into the way.
        imgView.translatesAutoresizingMaskIntoConstraints = false

        // aspect ratio
        imgView.heightAnchor.constraint(equalTo: imgView.widthAnchor).isActive = true

        // center in parent
        imgView.centerYAnchor.constraint(equalTo: parentView.centerYAnchor).isActive = true

        // glue to the right/trailing
        imgView.trailingAnchor.constraint(lessThanOrEqualTo: parentView.trailingAnchor).isActive = true

        // leave some space on top and bottom
        imgView.heightAnchor.constraint(lessThanOrEqualTo: parentView.heightAnchor,
                                        constant: -totalHeightGap).isActive = true

        return imgView
    }

    /// Creates a bar button item for invoking the trustwords language list.
    ///
    /// - Returns: UIBarButtonItem suitable for adding to the navigation bar.
    private func languageButton() -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.addTarget(self,
                         action: #selector(self.languageSelectedAction(_:)),
                         for: .touchUpInside)
        addLanguageButtonView(parentView: button)
        return UIBarButtonItem(customView: button)
    }

    private func backButton() -> UIButton {
        let img2 = UIImage(named: "arrow-rgt-active")
        let tintedimage = img2?.withRenderingMode(.alwaysTemplate)
        let buttonLeft = UIButton(type: UIButton.ButtonType.custom)
        buttonLeft.setImage(tintedimage, for: .normal)
        buttonLeft.imageView?.contentMode = .scaleToFill
        buttonLeft.imageView?.tintColor = UIColor.pEpGreen
        buttonLeft.setTitle(" Message", for: .normal)
        buttonLeft.addTarget(self, action: #selector(self.back(sender:)), for: .touchUpInside)
        buttonLeft.tintColor = UIColor.pEpGreen
        buttonLeft.setTitleColor(UIColor.pEpGreen, for: .normal)
        return buttonLeft
    }

    private func  handshakePartnerTableViewCellViewModels() -> [HandshakePartnerTableViewCellViewModel] {
        var result = [HandshakePartnerTableViewCellViewModel]()
        guard let message = message else {
            Log.shared.errorAndCrash("Fail to init handshakePartnerTableViewCellViewModel, since message is nil")
            return []
        }
        let handShakeCombinations = message.handshakeActionCombinations()
        for handshakeCombi in handShakeCombinations {
            guard let cellViewModel = createViewModel(partnerIdentity: handshakeCombi.partnerIdentity,
                                                      selfIdentity: handshakeCombi.ownIdentity) else {
                                                        Log.shared.errorAndCrash("Fail to init handshakePartnerTableViewCellViewModel")
                                                        continue
            }
            result.append(cellViewModel)
        }
        return result
    }

    /// Adjusts the background color of the given view model depending on its position in the list,
    /// and the color of the previous one.
    private func adjustBackgroundColor(viewModel: HandshakePartnerTableViewCellViewModel,
                                       indexPath: IndexPath) {
        // dark background on all odd rows
        viewModel.backgroundColorDark = indexPath.row % 2 == 1
    }

    override func viewDidLayoutSubviews() {
        popoverPresentationController?.sourceView = navigationItem.titleView
    }
}

// MARK: - UITableViewDataSource

extension HandshakeViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  handshakePartnerTableViewCellViewModel.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: "handshakePartnerCell",
            for: indexPath) as? HandshakePartnerTableViewCell {
            cell.delegate = self

            let viewModel = handshakePartnerTableViewCellViewModel[indexPath.row]
            adjustBackgroundColor(viewModel: viewModel, indexPath: indexPath)
            viewModel.trustwordsLanguage = currentLanguageCode
            cell.viewModel = viewModel
            cell.indexPath = indexPath

            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - Data

extension HandshakeViewController {

    ///Returns: A cached view model for the given `partnerIdentity` or a newly created one.
    private func createViewModel(partnerIdentity: Identity,
                                 selfIdentity: Identity) -> HandshakePartnerTableViewCellViewModel? {
        if let vm = identityViewModelCache.object(forKey: partnerIdentity) {
            return vm
        } else {
            var vm: HandshakePartnerTableViewCellViewModel?
            if let session = session {
                session.performAndWait {
                    vm = HandshakePartnerTableViewCellViewModel(ownIdentity: selfIdentity,
                                                                partner: partnerIdentity)
                }
            } else {
                vm = HandshakePartnerTableViewCellViewModel(ownIdentity: selfIdentity,
                                                            partner: partnerIdentity)
            }
            guard let safeVM = vm else {
                Log.shared.errorAndCrash("Fail to init HandshakePartnerTableViewCellViewModel")
                return nil
            }
            identityViewModelCache.setObject(safeVM, forKey: partnerIdentity)
            return safeVM
        }
    }
}

// MARK: - HandshakePartnerTableViewCellDelegate

extension HandshakeViewController: HandshakePartnerTableViewCellDelegate {
    func updateSize() {
        tableView.updateSize()
    }

    func invokeTrustAction(cell: HandshakePartnerTableViewCell,
                           indexPath: IndexPath,
                           viewModel: HandshakePartnerTableViewCellViewModel?,
                           undoSelector: Selector,
                           action: (HandshakePartnerTableViewCellViewModel) -> ()) {
        guard let vm = viewModel else {
            return
        }

        // set undo action
        let undoInfo = UndoInfoContainer(indexPath: indexPath, viewModel: vm)
        undoTrustOrMistrustManager.registerUndo(withTarget: self,
                                                selector: undoSelector,
                                                object: undoInfo)

        action(vm)

        reevaluateAndUpdate(indexPath: indexPath)
    }

    func reevaluateAndUpdate(indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .automatic)

        guard let msg = message else {
            Log.shared.errorAndCrash("No message")
            return
        }
        session?.performAndWait {
            RatingReEvaluator.reevaluate(message: msg)
        }
        updateStatusBadge()
    }

    func confirmTrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
                      indexPath: IndexPath,
                      viewModel: HandshakePartnerTableViewCellViewModel?) {
        invokeTrustAction(cell: cell,
                          indexPath: indexPath,
                          viewModel: viewModel,
                          undoSelector: #selector(undoTrust(_:))) { vm in
                            vm.confirmTrust()
        }
    }

    func denyTrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
                   indexPath: IndexPath,
                   viewModel: HandshakePartnerTableViewCellViewModel?) {
        invokeTrustAction(cell: cell,
                          indexPath: indexPath,
                          viewModel: viewModel,
                          undoSelector: #selector(undoMistrust(_:))) { vm in
                            vm.denyTrust()
        }
    }

    func pickLanguage(sender: UIView, cell: HandshakePartnerTableViewCell,
                      indexPath: IndexPath, viewModel: HandshakePartnerTableViewCellViewModel?) {
        indexPathRequestingLanguage = indexPath
        self.performSegue(withIdentifier: .showLanguagesSegue, sender: cell)
    }

    func toggleTrustwordsLength(sender: UIView, cell: HandshakePartnerTableViewCell,
                                indexPath: IndexPath,
                                viewModel: HandshakePartnerTableViewCellViewModel?) {
        viewModel?.toggleTrustwordsLength()
        cell.updateTrustwords()
        tableView.updateSize()
    }
}

// MARK: - Segue

extension HandshakeViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case showLanguagesSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showLanguagesSegue:
            let navVC = segue.destination as? UINavigationController
            if let destination = navVC?.viewControllers.first as? LanguageListViewController ??
                segue.destination as? LanguageListViewController {
                destination.appConfig = appConfig
                prepare(destination: destination)
            }
            break
        }
    }

    func prepare(destination: LanguageListViewController) {
        do {
            destination.languages = try PEPSession().languageList()
        } catch let err as NSError {
            Log.shared.error("%@", "\(err)")
            destination.languages = []
        }
    }
}

// MARK: - Undo

extension HandshakeViewController {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            undoTrustOrMistrustManager.undo()
        } else {
            super.motionEnded(motion, with: event)
        }
    }

    @objc func undoTrust(_ undoInfo: UndoInfoContainer) {
        undoInfo.viewModel.resetOrUndoTrustOrMistrust()
        reevaluateAndUpdate(indexPath: undoInfo.indexPath)
    }

    @objc func undoMistrust(_ undoInfo: UndoInfoContainer) {
        undoInfo.viewModel.resetOrUndoTrustOrMistrust()
        reevaluateAndUpdate(indexPath: undoInfo.indexPath)
    }
}
