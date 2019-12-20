//
//  File.swift
//  
//
//  Created by Developer on 20/12/2019.
//

import UIKit

public class DatastoreIndexController: UIViewController {
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Test"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20)
        label.backgroundColor = .red
        view.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        label.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        label.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
}

public class DatastoreEntityController: UIViewController {
    
}
