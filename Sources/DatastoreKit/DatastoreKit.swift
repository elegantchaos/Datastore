//
//  File.swift
//  
//
//  Created by Developer on 20/12/2019.
//

import UIKit

extension UIView {
    func stickTo(view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }
}
public class SelfSizingTable: UITableView {
    public override var intrinsicContentSize: CGSize {
        return contentSize
    }
}

public class DatastoreIndexController: UIViewController {
    var table: UITableView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        view.addSubview(stack)

        let label = UILabel()
        label.text = "Test"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20)
        label.backgroundColor = .red
        stack.addArrangedSubview(label)

        table = SelfSizingTable()
        table.delegate = self
        table.dataSource = self
        table.showsVerticalScrollIndicator = false
        table.isScrollEnabled = false
        stack.addArrangedSubview(table)

        let label2 = UILabel()
        label2.text = "Another Test Which Is Long Enough To Wrap Around Onto A Second Line"
        label2.textAlignment = .center
        label2.numberOfLines = 0
        label2.sizeToFit()
        label2.lineBreakMode = .byWordWrapping
        label2.font = .systemFont(ofSize: 20)
        label2.backgroundColor = .red
        stack.addArrangedSubview(label2)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.stickTo(view: view)
//        stack.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        stack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        stack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//        stack.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//        stack.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
}

extension DatastoreIndexController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        cell.textLabel?.text = "Cell \(indexPath)"
        return cell
    }
    
    
}

public class DatastoreEntityController: UIViewController {
    
}
