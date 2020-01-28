// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2019.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import UIKit
import Datastore
import LayoutExtensions
import ViewExtensions

public class DatastorePropertyController: UIViewController {
    public typealias SectionOrder = [PropertyKey]
    public typealias SectionsList = [SectionOrder]
    
    // MARK: Configuration Properties
    public var selfSizing = false

    // MARK: Private Properties
    
    var entity: EntityReference
    var sections: SectionsList
    let store: Datastore
    
    var valueViews: [PropertyType : DatastorePropertyView.Type] = [
        .boolean: BooleanPropertyView.self,
        .date: DatePropertyView.self,
        .double: DoublePropertyView.self,
        .entity: RelationshipPropertyView.self,
        .integer: IntegerPropertyView.self,
        .string: StringPropertyView.self,
    ]
    
    var typeMap: [EntityType: EntityType] = [ // TODO: move this into the datastore, build it automatically
        EntityType("author"): EntityType("entity"),
        EntityType("publisher"): EntityType("entity"),
        EntityType("editor"): EntityType("entity"),
        EntityType("tag"): EntityType("entity")
    ]

    var tableView: UITableView!
    
    var labelConstraints: [NSLayoutConstraint] = []
    var labelWidth: CGFloat = 0.0
    var labelMaxWidth: CGFloat = 100.0
    var labelFont: UIFont!
    
    public init(for entity: EntityReference, sections: SectionsList, store: Datastore) {
        self.entity = entity
        self.sections = sections
        self.store = store
        
        super.init(nibName: nil, bundle: nil)

        let font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
        labelFont = font.withSize(font.fontDescriptor.pointSize - 2.0)
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
    
    func registeredViewClass(for value: PropertyValue) -> DatastorePropertyView.Type {
        var type = value.type
        if let entityType = type?.asEntityType, let mapped = typeMap[entityType]?.asPropertyType {
            type = mapped
        }
        
        guard let entryType = type, let entry = valueViews[entryType] else {
            return GenericPropertyView.self
        }
        
        return entry
    }
    
    func updateLabelConstraints() {
        for constraint in labelConstraints {
            constraint.constant = min(labelWidth, labelMaxWidth)
        }
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        labelMaxWidth = view.frame.width * 0.3
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLabelConstraints()
    }
}

extension DatastorePropertyController: UITableViewDelegate, UITableViewDataSource {
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
        
        let stack = UIStackView(axis: .horizontal, alignment: .firstBaseline)
        cell.addSubview(stack)
        stack.stickTo(view: cell)
        stack.spacing = DatastoreKit.spacing

        let label = UILabel()
        label.text = key.value
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.textAlignment = .right
        label.textColor = .gray
        label.font = labelFont
        stack.addArrangedSubview(label)

        if let value = item {
            let viewClass = registeredViewClass(for: value)
            let valueView = viewClass.init()
            valueView.setup(value: value, withKey: key, label: label, for: self)
            stack.addArrangedSubview(valueView)
        }

        label.sizeToFit()
        let width = label.frame.size.width
        if width > labelWidth {
            labelWidth = width
            updateLabelConstraints()
        }
        let labelConstraint = label.widthAnchor.constraint(equalToConstant: min(labelWidth, labelMaxWidth))
        labelConstraint.isActive = true
        labelConstraints.append(labelConstraint)

        return cell
    }
    
//    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let item = items[indexPath.row]
//        onSelect?(item)
//    }
}
#endif
