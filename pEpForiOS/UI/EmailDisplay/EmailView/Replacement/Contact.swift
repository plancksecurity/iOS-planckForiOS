///// Delegate to comunicate with Email View.
//protocol EmailViewModelDelegate: class {
//    /// Show the item
//    /// - Parameter item: The item to show
//    func show(item: QLPreviewItem)
//    /// Show Documents Editor
//    func showDocumentsEditor()
//    /// Show Certificates Import View.
//    /// - Parameter viewModel: The view model to setup the view.
//    func showClientCertificateImport(viewModel: ClientCertificateImportViewModel)
//    /// Shows the loading
//    func showLoadingView()
//    /// Hides the loading
//    func hideLoadingView()
//}
//
//enum EmailRowType: String {
//  case from, to, cc, bcc, subject, body, attachment
//}
//
///// Protocol that represents the basic data in a row.
//protocol EmailRowProtocol {
//    /// The type of the row
//    var type: EmailRowType
//    /// The title of the row.
//    var title: String?
//    /// Returns the cell identifier
//    var cellIdentifier: String
//    /// The content of the row
//    var content: String?
//}
//
//struct EmailViewModel {
//    /// Delegate to comunicate with Email View.
//    weak var delegate: EmailViewModelDelegate?
//
//    /// Constructor
//    /// - Parameter message: The message to display
//    init(message: Message)
//
//    struct EmailRow: EmailRowProtocol {
//        var type: EmailRowType
//        var content: String?
//        var title: String?
//        var height: CGFloat
//        var cellIdentifier: String
//
//        /// Constructor
//        /// - Parameter type: The type of the row
//        init(type: EmailRowType)
//    }
//
//    /// Indicates if the show external content button should be shown.
//    var shouldShowExternalContentButton: Bool
//
//    /// Indicates if the html viewer should be shown.
//    var shouldShowHtmlViewer: Bool
//
//    /// Yields the HTML message body if we can show it in a secure way or we have non-empty HTML content at all
//    var htmlBody: String?
//
//    /// Number of rows
//    var numberOfRows: Int
//
//    /// Retrieves the row
//    subscript(index: Int) -> EmailRowProtocol
//
//    /// Evaluates the pepRating to provide the body
//    /// Use it for non-html content.
//    /// - Parameter completion: The callback with the body.
//    func body(completion: @escaping (NSMutableAttributedString) -> Void)
//
//    Handle the user tap gesture over the mail attachment
//    - Parameter index: The index of the attachment
//    func handleDidTapAttachment(at index: Int)
