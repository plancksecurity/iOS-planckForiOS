//
//  ExtraKeysSettingViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.08.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

class ExtraKeysSettingViewController: BaseViewController {
    static private let uiTableViewCellID = "ExtraKeysSettingCell"

    @IBOutlet weak var addExtraKeyButton: UIButton!
    @IBOutlet weak var addFprView: UIStackView!
    @IBOutlet weak var fpr: UITextView!
    @IBOutlet weak var tableView: UITableView!

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
        subscribeForKeyboardNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeForKeyboardNotifications()
        setup()
        tableView.reloadData()
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
        viewModel?.handleAddButtonPress(fpr: fpr.text)
        fpr.resignFirstResponder()
        fpr.text = ""
    }
}

// MARK: - Private

extension ExtraKeysSettingViewController {
    
    private func setup() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRect.zero) // Hides lines for non empty rows
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: ExtraKeysSettingViewController.uiTableViewCellID)
        tableView.rowHeight = UITableView.automaticDimension

        viewModel = ExtraKeysSettingViewModel(delegate: self)

        // Editable
        let isEditable = viewModel?.isEditable ?? false
        tableView.isEditing = isEditable
        addFprView.isHidden = !isEditable

        // FPR input field
        fpr.layer.borderWidth = 5.0
        fpr.layer.borderColor = UIColor.pEpGreen.cgColor
        fpr.backgroundColor = UIColor.pEpLightBackground

        // add button
        addExtraKeyButton.tintColor = UIColor.pEpGreen

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
        return viewModel?.numRows ?? 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: ExtraKeysSettingViewController.uiTableViewCellID,
                                                 for: indexPath)
        // Multi line to avoud truncation of FPRs
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = viewModel?[indexPath.row]

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Enables swipe to delete
        return viewModel?.isEditable ?? false
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
                    Log.shared.errorAndCrash("Uups")
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
