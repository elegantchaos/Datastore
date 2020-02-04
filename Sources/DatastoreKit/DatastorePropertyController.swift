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
    
    // MARK: Configuration Properties
    public var selfSizing = false

    // MARK: Private Properties
    
    var layout: DatastorePropertyLayout

    var tableView: UITableView!
    
    var labelConstraints: [NSLayoutConstraint] = []
    var labelWidth: CGFloat = 0.0
    var labelMaxWidth: CGFloat = 100.0
    var labelFont: UIFont!
    
    public init(layout: DatastorePropertyLayout) {
        self.layout = layout
        
        super.init(nibName: nil, bundle: nil)

        let font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
        labelFont = font.withSize(font.fontDescriptor.pointSize - 2.0)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder) not implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let table = EnhancedTableView(frame: .zero, style: .grouped)
        table.selfSizing = selfSizing
        table.delegate = self
        table.dataSource = self
        table.allowsSelection = false
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        self.tableView = table
        view.addSubview(table)
        table.stickTo(view: view)
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
        return layout.sections.count
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return layout.sections[section].count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let section = layout.sections[indexPath.section]
        let entry = section[indexPath.row]
        
        let stack = UIStackView(axis: .horizontal, alignment: .firstBaseline)
        cell.addSubview(stack)
        stack.stickTo(view: cell)
        stack.spacing = DatastoreKit.spacing

        let label = UILabel()
        label.text = entry.key.value
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.textAlignment = .right
        label.textColor = .gray
        label.font = labelFont
        stack.addArrangedSubview(label)

        let valueView = entry.viewer.init()
        valueView.setup(value: entry.value, withKey: entry.key, label: label, for: self)
        stack.addArrangedSubview(valueView)

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
