// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

public class DatastoreIndexSearchButton: UIButton {
    let index: DatastoreIndexController?
    
    public init(index: DatastoreIndexController? = nil) {
        self.index = index
        super.init(frame: .zero)
        updateIcon()
        addTarget(self, action: #selector(doTapped(_:)), for: .primaryActionTriggered)
    }
    
    public required init?(coder: NSCoder) {
        index = nil
        super.init(coder: coder)
    }
    
    func updateIcon() {
        if let index = index {
            let imageName = index.searchBar.isHidden ? "magnifyingglass.circle" : "magnifyingglass.circle.fill"
            setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    @IBAction func doTapped(_ sender: Any) {
        index?.toggleSearchBar()
        updateIcon()
    }

}
