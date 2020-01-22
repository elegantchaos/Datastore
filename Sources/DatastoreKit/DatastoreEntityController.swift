// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2019.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import UIKit
import Datastore
import LayoutExtensions
import ViewExtensions

public class DatastoreEntityController: UIViewController {
    public typealias SectionOrder = [PropertyKey]
    public typealias SectionsList = [SectionOrder]
    
    // MARK: Configuration Properties
    public var selfSizing = false

    // MARK: Private Properties
    
    var entity: EntityReference
    var sections: SectionsList

    var valueViews: [PropertyType : PropertyView.Type] = [ .string: StringPropertyView.self ]
    
    var tableView: UITableView!
    
    public init(for entity: EntityReference, sections: SectionsList) {
        self.entity = entity
        self.sections = sections

        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder) not implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let table = EnhancedTableView()
        table.selfSizing = selfSizing
        table.delegate = self
        table.dataSource = self
        self.tableView = table
        view.addSubview(table)
        table.stickTo(view: view)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.backgroundColor = .red
    }
    
    func registeredViewClass(for value: PropertyValue) -> PropertyView.Type {
        guard let type = value.type, let entry = valueViews[type] else {
            return GenericPropertyView.self
        }
        
        return entry
    }
}

extension DatastoreEntityController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let section = sections[indexPath.section]
        let key = section[indexPath.row]
        let item = entity[valueWithKey: key]
        
        let stack = UIStackView(axis: .horizontal)
        cell.addSubview(stack)
        stack.stickTo(view: cell)
        stack.spacing = 20.0

        let label = UILabel()
        label.text = key.value
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        stack.addArrangedSubview(label)

        if let value = item {
            let viewClass = registeredViewClass(for: value)
            let valueView = viewClass.init()
            valueView.setup(value: value, withKey: key, forEntity: entity)
            stack.addArrangedSubview(valueView)
        }
        
        return cell
    }
    
//    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let item = items[indexPath.row]
//        onSelect?(item)
//    }
}

protocol PropertyView: UIView {
    func setup(value: PropertyValue, withKey: PropertyKey, forEntity: EntityReference)
}

class GenericPropertyView: UILabel, PropertyView {
    func setup(value: PropertyValue, withKey: PropertyKey, forEntity: EntityReference) {
        if let actualValue = value.value {
            let type = value.type?.name ?? "<unknown type>"
            text = "\(actualValue) (\(type))"
        } else {
            text = "<nil>"
        }
    }
}

class StringPropertyView: UILabel, PropertyView {
    func setup(value: PropertyValue, withKey: PropertyKey, forEntity: EntityReference) {
        text = value.coerced(or: "")
    }
}
#endif
