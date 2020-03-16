//import MessageModel
//
///// Utils for importing Client Certificates.
//final class ClientCertificateUIUtil: NSObject {
//    
//    private lazy var clientCertificatePasswordVC: ClientCertificateImportViewController? = {
//        let vc = UIStoryboard.init(name: "Certificates",
//                          bundle: nil).instantiateInitialViewController() as? ClientCertificateImportViewController
//        vc?.viewModel = ClientCertificatePasswordViewModel(delegate: vc,
//                                                           passwordChangeDelegate: self)
//        return vc
//    }()
//
//    public init(clientCertificateUtil: ClientCertificateUtilProtocol? = nil) {
//        
//    }
//
//    typealias Success = Bool
//    
//
//
//}

//// MARK: - Private
//
//extension ClientCertificateUIUtil {
//
//    private func presentAlertViewForClientImportPassPhrase() {
//        guard let viewControllerPresenter = viewControllerToPresentUiOn else {
//            Log.shared.errorAndCrash("No VC!")
//            return
//        }
//        guard let clientCertificatePasswordVC = clientCertificatePasswordVC else {
//            Log.shared.errorAndCrash("Certificates storyboard not found")
//            return
//        }
//        clientCertificatePasswordVC.modalPresentationStyle = .fullScreen
//        viewControllerPresenter.present(clientCertificatePasswordVC, animated: true)
//    }
//
//
//
//    private func dismiss(vc: UIViewController) {
//        vc.dismiss(animated: true)
//    }
//}

