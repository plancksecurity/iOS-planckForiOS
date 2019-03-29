
import Foundation
import MessageModel

public protocol FilterCellProtocol {
    var icon: UIImage { get }
    var title: String { get }
    var enabled: Bool { get }
}

public enum FilterTypeCell {
    case Account, Flagg, Unread, Attachments
}

public struct FilterCellAccountViewModel : FilterCellProtocol {


}
