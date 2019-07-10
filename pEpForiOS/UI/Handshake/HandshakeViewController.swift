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

class HandshakeViewController: BaseTableViewController {
    private var backTitle: String?
    private var currentLanguageCode = Locale.current.languageCode ?? "en"
    private let identityViewModelCache = NSCache<Identity, HandshakePartnerTableViewCellViewModel>()

    private var indexPathRequestingLanguage: IndexPath?

    var message: Message? {
        didSet {
            handshakeCombinations = message?.handshakeActionCombinations() ?? []
        }
    }

    var handshakeCombinations = [HandshakeCombination]()
    //    { //BUFF: can we reuse the view by setting the combinations for KeySync? I am afraid it is not a good idea?
//        didSet {
//            tableView.reloadData()
//        }
//    }

    var ratingReEvaluator: RatingReEvaluator?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableView.automaticDimension

        let item = UIBarButtonItem(customView: languageButton())
        self.navigationItem.rightBarButtonItems = [item]

        let leftItem = UIBarButtonItem(customView: backButton())
        self.navigationItem.leftBarButtonItem = leftItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatusBadge()
    }
}

// MARK: - Target & Action

extension HandshakeViewController {

    @IBAction
    private func languageSelectedAction(_ sender: Any) {
        let theSession = PEPSession()
        var languages: [PEPLanguage] = []
        do {
            languages = try theSession.languageList()
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
        self.showPepRating(pEpRating: message?.pEpRating())
    }

    // MARK: - UI & Layout

    @objc
    private func back(sender: UIBarButtonItem) {
        // Perform your custom action
        self.dismiss(animated: true, completion: nil)
    }

    private func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    private func languageButton() -> UIButton {
        //language button
        let img = UIImage(named: "pEpForiOS-icon-languagechange")
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.imageEdgeInsets = UIEdgeInsets.init(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
        button.setImage(img, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(self.languageSelectedAction(_:)), for: .touchUpInside)
        return button
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

    /// Adjusts the background color of the given view model depending on its position in the list,
    /// and the color of the previous one.
    private func adjustBackgroundColor(viewModel: HandshakePartnerTableViewCellViewModel,
                                       indexPath: IndexPath) {
        if indexPath.row == 0 {
            viewModel.backgroundColorDark = false
        } else {
            let prevRow = indexPath.row - 1
            let handshakeCombo = handshakeCombinations[prevRow]
            let prevViewModel = createViewModel(partnerIdentity: handshakeCombo.partnerIdentity,
                                                selfIdentity: handshakeCombo.ownIdentity)
            if prevViewModel.showTrustwords {
                viewModel.backgroundColorDark = true
            } else {
                viewModel.backgroundColorDark = !prevViewModel.backgroundColorDark
            }
        }
    }

    override func viewDidLayoutSubviews() {
        popoverPresentationController?.sourceView = navigationItem.titleView
        var changedPreferredMaxLayoutWidth = false

        let cells = tableView.visibleCells
        for cell in cells {
            if let c = cell as? HandshakePartnerTableViewCell {
                let width = c.trustWordsLabel.frame.size.width
                if width != c.trustWordsLabel.preferredMaxLayoutWidth {
                    c.trustWordsLabel.preferredMaxLayoutWidth = width
                    changedPreferredMaxLayoutWidth = true
                }
            }
        }

        if changedPreferredMaxLayoutWidth {
            tableView.updateSize()
        }
    }
}

// MARK: - UITableViewDataSource

extension HandshakeViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return handshakeCombinations.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: "handshakePartnerCell",
            for: indexPath) as? HandshakePartnerTableViewCell {
            cell.delegate = self

            let handshakeCombo = handshakeCombinations[indexPath.row]
            let viewModel = createViewModel(partnerIdentity: handshakeCombo.partnerIdentity,
                                            selfIdentity: handshakeCombo.ownIdentity)
            adjustBackgroundColor(viewModel: viewModel, indexPath: indexPath)
            viewModel.trustwordsLanguage = currentLanguageCode
            cell.viewModel = viewModel
            cell.indexPath = indexPath
            cell.sizeToFit()
            cell.needsUpdateConstraints()
            cell.updateConstraintsIfNeeded()


            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UITableViewDelegate

extension HandshakeViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? HandshakePartnerTableViewCell {
            cell.didChangeSelection()
            tableView.updateSize()
        }
    }
}

// MARK: - Data

extension HandshakeViewController {

    ///Returns: A cached view model for the given `partnerIdentity` or a newly created one.
    private func createViewModel(partnerIdentity: Identity,
                                 selfIdentity: Identity) -> HandshakePartnerTableViewCellViewModel {
        if let vm = identityViewModelCache.object(forKey: partnerIdentity) {
            return vm
        } else {
            let vm = HandshakePartnerTableViewCellViewModel(ownIdentity: selfIdentity,
                                                            partner: partnerIdentity)
            identityViewModelCache.setObject(vm, forKey: partnerIdentity)
            return vm
        }
    }
}

// MARK: - HandshakePartnerTableViewCellDelegate

extension HandshakeViewController: HandshakePartnerTableViewCellDelegate {
    func updateSize() {
        tableView.updateSize()
    }

    func invokeTrustAction(cell: HandshakePartnerTableViewCell, indexPath: IndexPath,
                           action: () -> ()) {
        action()
        cell.updateView()
        tableView.updateSize()

        ratingReEvaluator?.delegate = self
        ratingReEvaluator?.reevaluateRating()

        // reload cells after that one, to ensure the alternating colors are upheld
        var paths = [IndexPath]()
        let i1 = indexPath.row + 1
        let i2 = handshakeCombinations.count
        if i1 < i2 {
            for i in i1..<i2 {
                paths.append(IndexPath(row: i, section: indexPath.section))
            }
        }
        tableView.reloadRows(at: paths, with: .automatic)
    }

    func resetTrustOrUndoMistrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
                                  indexPath: IndexPath,
                                  viewModel: HandshakePartnerTableViewCellViewModel?) {
        invokeTrustAction(cell: cell, indexPath: indexPath) {
            viewModel?.resetOrUndoTrustOrMistrust()
        }
    }

    func confirmTrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
                      indexPath: IndexPath,
                      viewModel: HandshakePartnerTableViewCellViewModel?) {
        invokeTrustAction(cell: cell, indexPath: indexPath) { viewModel?.confirmTrust() }
    }

    func denyTrust(sender: UIButton, cell: HandshakePartnerTableViewCell,
                   indexPath: IndexPath,
                   viewModel: HandshakePartnerTableViewCellViewModel?) {
        invokeTrustAction(cell: cell, indexPath: indexPath) { viewModel?.denyTrust() }
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

// MARK: - RatingReEvaluatorDelegate

extension HandshakeViewController : RatingReEvaluatorDelegate {
    func ratingChanged(message: Message) {
        DispatchQueue.main.async {
            self.updateStatusBadge()
        }

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
        let theSession = PEPSession()
        do {
            destination.languages = try theSession.languageList()
        } catch let err as NSError {
            Log.shared.error("%@", "\(err)")
            destination.languages = []
        }
    }
}
