//
//  Capability.swift
//
//  Created by Yves Landert on 28.10.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import Contacts
import Photos
import pEpIOSToolbox


public struct Capability {
    public static let media = Media()
    
    public enum AccessError: Error {
        case notDetermined
        case restricted
        case denied
    }
    
    public class Media {
        public final func authorized() -> Bool {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized, .limited:
                return true
            case .denied, .notDetermined, .restricted:
                return false
            default:
                Log.shared.errorAndCrash("Unhandledcase")
                return false
            }
        }

        /// Figures out whether or not we have permission to access the Photo Gallery.
        ///
        /// - Parameters:
        ///   - completion: completion handler, passing result and possible error
        public final func request(completion:
            @escaping (_ granted: Bool, _ error: AccessError?) -> (Void)) {
            PHPhotoLibrary.requestAuthorization() { status in
                switch status {
                case .authorized, .limited: 
                    completion(true, nil)
                    break
                case .denied, .notDetermined:
                    completion(false, .denied)
                    break
                case .restricted:
                    completion(false, .restricted)
                    break
                @unknown default:
                    Log.shared.errorAndCrash("Unhandled case")
                    completion(false, .denied)
                }
            }
        }

        /// Figures out whether or not we have permission to access the Photo Gallery.
        /// Also informs the user (shows alert) hot grant access in case we do currently
        /// not have permissions
        ///
        /// - Parameters:
        ///   - vc: view controller to show alert to inform the user in case no permission is granted
        ///   - completion: completion handler, passing result and possible error
        public final func requestAndInformUserInErrorCase(viewController vc: UIViewController,
                                                          completion:
            @escaping (_ granted: Bool, _ error: AccessError?) -> (Void)) {

            request { (permissionsGranted: Bool, error: Capability.AccessError?) in
                GCD.onMain {
                    if permissionsGranted {
                        completion(permissionsGranted, error)
                        return
                    }
                    // We do not have permission. Kindly inform the user.
                    let title = NSLocalizedString("No Permissions",
                                                  comment:
                        "Alert title shown if user wants to add a photo attachment, but has denied to give the app permissions.")
                    let message = NSLocalizedString(
                        "p≡p has no permissions to access \nthe Photo Gallery. You can grand permissions in Settings App.",
                                                    comment:
                        "Alert message shown if user wants to add a photo attachment, but has denied to give the app permissions.")
                    UIUtils.showAlertWithOnlyPositiveButton(title: title,
                                                            message: message)
                    completion(permissionsGranted, error)
                }
            }
        }
    }
}
