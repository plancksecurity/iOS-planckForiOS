//
//  ExtraKeysSettingViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.08.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

class ExtraKeysSettingViewController: BaseViewController {
    static private let uiTableViewCellID = "ExtraKeysSettingCell"

    @IBOutlet weak var addExtraKeyButton: UIButton!
    @IBOutlet weak var addFprView: UIStackView!
    @IBOutlet weak var fpr: UITextView!
    @IBOutlet weak var tableView: UITableView!

    private var viewModel: ExtraKeysSettingViewModel?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForKeyboardNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeForKeyboardNotifications()
        setup()
        tableView.reloadData()
    }

    deinit {
        unsubscribeAll()
    }

    // MARK: - Action

    @IBAction func addExtraKeyButtonPressed(_ sender: UIButton) {
        viewModel?.handleAddButtonPress(fpr: fpr.text)
    }
}

// MARK: - Private

extension ExtraKeysSettingViewController {
    
    private func setup() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SwipeTableViewCell.self,
                           forCellReuseIdentifier: ExtraKeysSettingViewController.uiTableViewCellID)
        tableView.isEditing = true

        addExtraKeyButton.tintColor = UIColor.pEpGreen

        viewModel = ExtraKeysSettingViewModel(delegate: self)

        addFprView.isHidden = !(viewModel?.isEditable ?? false)
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
        cell.textLabel?.text = viewModel?[indexPath.row]

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Enables swipe to delete
        return true
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
                                                message: message,
                                                inViewController: self)
    }

    func refreshView() {
        tableView.reloadData()
    }
}

// MARK: - Keyboard Notifications

extension ExtraKeysSettingViewController {

    @objc
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize =
            (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y > -keyboardSize.height {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
//        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
//        }
    }
}
