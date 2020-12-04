//protocol EditableAccountSettingsDelegate: class {
//    /// Changes loading view visibility
//    func setLoadingView(visible: Bool)
//    /// Shows an alert
//    func showAlert(error: Error)
//    /// Informs that the account settings had chaged
//    func accountSettingsDidChange()
//    /// Dismiss the currently presented VC
//    func popViewController()
//}
//
//class EditableAccountSettingsViewModel: VerifiableAccountDelegate {
//
//    var isOAuth2: Bool = false
//    weak var delegate: EditableAccountSettingsDelegate?
//    let securityViewModel: SecurityViewModel
//    var sections = [AccountSettingsViewModel.Section]()
//
//    /// Constructor
//    /// - Parameters:
//    ///   - account: The account to configure the editable account settings view model.
//    ///   - delegate: The delegate to communicate to the View Controller.
//    init(account: Account, editableAccountSettingsDelegate: EditableAccountSettingsDelegate? = nil)
//
//    /// Validates the user input
//    /// Upload the changes if everything is OK, else informs the user
//    func handleSaveButtonPressed()
//
//    /// Updates the data of the row
//    func handleRowDidChange(row: Int, value: String)
//
//
//// MARK: -  enums & structs
//
//extension EditableAccountSettingsViewModel {
//    enum Transport {
//        case plain
//        case tls
//        case startTls
//    }
//
//}
//
//extension EditableAccountSettingsViewModel {
//
//    func setLoadingView(visible: Bool)
//
//    func showAlert(error: Error)
//
//    func didEndVerification(result: Result<Void, Error>)
//}
