
import Foundation
import MessageModel

public enum FilterTypeCell {
    case Account, Flagg, Unread, Attachments
}

public class FilterCellViewModel {

    var icon: UIImage?
    var title: String
    var enabled: Bool
    let filterType : FilterTypeCell
    public init(image: UIImage, title: String, enabled: Bool? = false, type: FilterTypeCell) {
        self.icon = image
        self.title = title
        if let filterEnabled = enabled {
            self.enabled = filterEnabled
        } else {
            self.enabled = false
        }
        self.filterType = type
    }

}
