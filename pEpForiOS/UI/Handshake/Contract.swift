//
///// Handshake View Mode Delegate
//protocol HandshakeViewModelDelegate {
//    
//    /// Delegate method to notify that shake's action has been performed
//    func didEndShakeMotion()
//    
//    /// Delegate method to notify the handshake has been reseted
//    /// - Parameter indexPath: The indexPath of the row where the handshake was reseted
//    func didResetHandshake(forRowAt indexPath: IndexPath)
//    
//    /// Delegate method to notify the handshake has been confirmed
//    /// - Parameter indexPath: The indexPath of the row where the handshake was confirmed
//    func didConfirmHandshake(forRowAt indexPath: IndexPath)
//
//    /// Delegate method to notify the handshake has been rejected
//    /// - Parameter indexPath: The indexPath of the row where the handshake was rejected
//    func didRejectHandshake(forRowAt indexPath: IndexPath)
//
//    /// Delegate method to notify when the protection status has changed
//    /// - Parameter status: enabled or disabled
//    func didChangeProtectionStatus(to status : HandshakeViewModel.ProtectionStatus)
//}
//
///// Protocol for a handshake row
///// It includes all data needed to display a handshake row.
//protocol HandshakeRowProtocol {
//    / Indicates the handshake partner's name
//    var name: String { get }
//    /// The current language
//    var currentLanguage: String { get }
//    /// The privacy status in between the current user and the partner
//    var privacyStatus: String? { get }
//    /// Indicates if the trustwords are long
//    var longTrustwords: Bool { get }
//    /// The row description
//    var description : String  { get }
//    /// The item trustwords
//    var trustwords : String? { get }
//    /// The row image
//    var image : UIImage { get }
//}
//
///// View Model to handle the handshake views.
//final class HandshakeViewModel {
//    
//    enum ProtectionStatus {
//        case enabled
//        case disabled
//    }
//
//    /// Constructor
//    /// - Parameters:
//    ///   - identities: The identities to handshake
//    public init(identities : [Identity])
//
//    ///MARK - Providers
//
//    ///Access method to get the rows
//    public func row(for index: Int) -> HandshakeRowProtocol
//    ///MARK - Actions
//    
//    /// Reject the handshake
//    /// - Parameter indexPath: The indexPath of the item to get the user to reject the handshake
//    public func handleRejectHandshakePressed(at indexPath: IndexPath)
//    
//    /// Confirm the handshake
//    /// - Parameter indexPath: The indexPath of the item to get the user to confirm the handshake
//    public func handleConfirmHandshakePressed(at indexPath: IndexPath)
//    
//    /// Reset the handshake
//    /// The privacy status will be unsecure.
//    /// - Parameter indexPath: The indexPath of the item to get the user to reset the handshake
//    public func handleResetPressed(at indexPath: IndexPath)
//    
//    /// Returns the list of languages available for that row.
//    public func handleChangeLanguagePressed() -> [String]
//    
//    /// Updates the selected language for that row.
//    /// - Parameters:
//    ///   - indexPath: The index path of the row
//    ///   - language: The chosen language
//    public func didSelectLanguage(forRowAt indexPath: IndexPath, language: String)
//
//    /// Toogle PeP protection status
//    public func handleToggleProtectionPressed()
//
//    /// Generate the trustwords
//    /// - Parameter long: Indicates if the trustwords MUST be long.
//    public func generateTrustwords(long : Bool) -> String?
//    
//    /// Method that reverts the last action performed by the user
//    /// After the execution of this method there won't be any action to un-do.
//    public func shakeMotionDidEnd()
//}
