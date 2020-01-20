// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import ViewExtensions
import Datastore

public class DatastoreIndexFilterButton: PopoverMenuButton {
    let index: DatastoreIndexController?
    let types: [EntityType]
    
    public init(index: DatastoreIndexController, forTypes entityTypes: [EntityType]) {
        self.index = index
        self.types = entityTypes
        super.init(systemIconName: "line.horizontal.3.decrease.circle", label: "filter by:")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func itemCount() -> Int {
        return types.count
    }
    
    override open func item(at row: Int) -> Any? {
        return types[row]
    }
    
    override open func configure(cell: UITableViewCell, for item: Any) {
        if let type = item as? EntityType, let index = index {
            cell.textLabel?.text = type.name
            cell.accessoryType = index.filterType == type ? .checkmark : .none
        }
    }
    
    override open func select(item: Any) {
        if let type = item as? EntityType, let index = index {
            index.toggleFilter(for: type)
        }
    }
}
