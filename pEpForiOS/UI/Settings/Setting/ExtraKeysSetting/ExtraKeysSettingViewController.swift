//
//  ExtraKeysSettingViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.08.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import PlanckToolbox

class ExtraKeysSettingViewController: UIViewController {
    static private let uiTableViewCellID = "ExtraKeysSettingCell"

    @IBOutlet private weak var addExtraKeyButton: UIButton!
    @IBOutlet private weak var addFprView: UIStackView!
    @IBOutlet private weak var fpr: UITextView!
    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var noExtraKeysFoundLabel: UILabel!

    private var viewModel: ExtraKeysSettingViewModel?

    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }
    
    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        fpr.delegate = self
        fpr.font = UIFont.planckFont(style: .callout, weight: .regular)
        addExtraKeyButton.titleLabel?.font = UIFont.planckFont(style: .body, weight: .regular)
        subscribeForKeyboardNotifications()

        noExtraKeysFoundLabel.text = NSLocalizedString("No extra keys were found", comment: "No extra keys were found")
        noExtraKeysFoundLabel.setPEPFont(style: .body, weight: .regular)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeForKeyboardNotifications()
        setup()
        tableView.reloadData()

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        if vm.numRows == 0 {
            noExtraKeysFoundLabel.isHidden = false
            view.bringSubviewToFront(noExtraKeysFoundLabel)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppSettings.shared.extraKeysEditable = false
        navigationItem.setHidesBackButton(true, animated: false)
    }

    deinit {
        unsubscribeAll()
    }

    // MARK: - Action

    @IBAction func addExtraKeyButtonPressed(_ sender: UIButton) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleAddButtonPress(fpr: fpr.text)
        fpr.resignFirstResponder()
        fpr.text = ""
    }
}

// MARK: - Private

extension ExtraKeysSettingViewController {
    
    private func setup() {
        viewModel = ExtraKeysSettingViewModel(delegate: self)

        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRect.zero) // Hides lines for non empty rows
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: ExtraKeysSettingViewController.uiTableViewCellID)
        tableView.rowHeight = UITableView.automaticDimension


        // Editable
        let isEditable = vm.isEditable
        tableView.isEditing = isEditable
        addFprView.isHidden = !isEditable

        // FPR input field
        fpr.layer.borderWidth = 5.0
        fpr.layer.borderColor = UIColor.primary().cgColor
        fpr.backgroundColor = UIColor.pEpLightBackground
        if UITraitCollection.current.userInterfaceStyle == .dark {
            fpr.backgroundColor = UIColor.tertiarySystemBackground
        }

        // add button
        addExtraKeyButton.tintColor = UIColor.primary()

        showNavigationBar()
    }

    private func subscribeForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    private func unsubscribeAll() {
        NotificationCenter.default.removeObserver(self)
    }

    private func removeCell(at indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
}

// MARK: - UITableViewDataSource

extension ExtraKeysSettingViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return 0
        }
        return vm.numRows
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: ExtraKeysSettingViewController.uiTableViewCellID,
                                                 for: indexPath)
        // Multi line to avoud truncation of FPRs
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = viewModel?[indexPath.row]
        cell.textLabel?.font = UIFont.planckFont(style: .body, weight: .regular)

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return false
        }
        // Enables swipe to delete
        return vm.isEditable
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

       let title = NSLocalizedString("Delete", comment: "swipe delete ExtraKey action title")
        let deleteAction =
            UITableViewRowAction(style: .destructive, title: title) {
                [weak self] (action , indexPath) -> Void in
                guard let me = self, let vm = me.viewModel else {
                    Log.shared.lostMySelf()
                    return
                }
                vm.handleDeleteActionTriggered(for: indexPath.row)
                me.removeCell(at: indexPath)
        }
        return [deleteAction]
    }
}

// MARK: - UITableViewDelegate

extension ExtraKeysSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
    }
}

// MARK: - ExtraKeysSettingViewModelDelegate

extension ExtraKeysSettingViewController: ExtraKeysSettingViewModelDelegate {

    func showFprInvalidAlert() {
        let title = NSLocalizedString("Invalid FPR",
                                      comment: "alert title. trying to add an invalid fingerprint")
        let message = NSLocalizedString("Invalid FPR",
                                        comment: "alert message. trying to add an invalid fingerprint")
        UIUtils.showAlertWithOnlyPositiveButton(title: title,
                                                message: message)
    }

    func refreshView() {
        tableView.reloadData()
    }
}

// MARK: - Keyboard

extension ExtraKeysSettingViewController {

    @objc
    func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize =
            (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        self.view.frame.origin.y = -keyboardSize.height
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
            self.view.frame.origin.y = 0
    }
}

extension ExtraKeysSettingViewController: UITextViewDelegate {

    // Dismiss keyboard on return key
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
