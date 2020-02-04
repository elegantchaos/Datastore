// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import UIKit
import ViewExtensions
import Datastore

public class DatastoreIndexFilterButton: PopoverMenuButton {
    let index: DatastoreIndexController?
    let types: [DatastoreType]
    
    public init(index: DatastoreIndexController, forTypes entityTypes: [DatastoreType]) {
        self.index = index
        self.types = entityTypes
        super.init(systemIconName: "line.horizontal.3.decrease.circle", label: "filter by:", spacing: DatastoreKit.spacing)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func updateIcon() {
        if let index = index {
            let imageName = index.filterType == nil ? "line.horizontal.3.decrease.circle" : "line.horizontal.3.decrease.circle.fill"
            setImage(UIImage(systemName: imageName), for: .normal)
        }
    }

    override open func itemCount() -> Int {
        return types.count
    }
    
    override open func item(at row: Int) -> Any? {
        return types[row]
    }
    
    override open func configure(cell: UITableViewCell, for item: Any) {
        if let typeConformance = item as? DatastoreType, let index = index {
            cell.textLabel?.text = typeConformance.name
            cell.accessoryType = index.filterType == typeConformance ? .checkmark : .none
        }
    }
    
    override open func select(item: Any) {
        if let typeConformance = item as? DatastoreType, let index = index {
            index.toggleFilter(for: typeConformance)
            updateIcon()
        }
    }
}
#endif
