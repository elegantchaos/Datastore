// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/01/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

public class DatastoreIndexSortButton: UIButton {
    let index: DatastoreIndexController?
    
    public init(index: DatastoreIndexController? = nil) {
        self.index = index
        super.init(frame: .zero)
        updateIcon()
        addTarget(self, action: #selector(doSort(_:)), for: .primaryActionTriggered)
    }
    
    public required init?(coder: NSCoder) {
        index = nil
        super.init(coder: coder)
    }
    
    func updateIcon() {
        if let index = index {
            let imageName = index.sortAscending ? "chevron.up.circle" : "chevron.down.circle"
            setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    @IBAction func doSort(_ sender: Any) {
        index?.toggleSortDirection()
        updateIcon()
    }

}
