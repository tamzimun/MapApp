//
//  EditViewController.swift
//  MapApp4
//
//  Created by tamzimun on 27.06.2022.
//

import UIKit
import MapKit

protocol EditPlaceDelegate: AnyObject {
    func editPlace(title: String, subtitle: String)
}

class EditViewController: UIViewController {

    weak var editDelegate: EditPlaceDelegate?
    
    let pin = MKPointAnnotation()
    
    let titleField: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .center
        textField.backgroundColor = .white
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let subtitleField: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .center
        textField.backgroundColor = .white
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setUpNaviagtion()
        setTitleFieldConstraints()
        setSubtitleFieldConstraints()
    }
    
    func setUpNaviagtion() {
        navigationItem.title = "Edit"
        self.navigationController?.toolbar.backgroundColor = .black
        self.navigationController?.view.backgroundColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDone))
    }
    
    @objc func handleDone () {

        guard let title = titleField.text, titleField.hasText else {
            return
        }
        guard let subtitle = subtitleField.text, subtitleField.hasText else {
            return
        }
        
        editDelegate?.editPlace(title: title, subtitle: subtitle)
        navigationController?.popViewController ( animated: true)
    
    }
    
    // MARK: - Setup Constraints
    
    func setTitleFieldConstraints() {
        view.addSubview(titleField)
        
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50 ).isActive = true
        titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
        titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        titleField.heightAnchor.constraint(equalToConstant: view.frame.height * 0.05).isActive = true
        titleField.layer.borderWidth = 2
        titleField.layer.cornerRadius = 5
        titleField.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    func setSubtitleFieldConstraints() {
        view.addSubview(subtitleField)
        
        subtitleField.translatesAutoresizingMaskIntoConstraints = false
        subtitleField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 10).isActive = true
        subtitleField.leadingAnchor.constraint(equalTo: titleField.leadingAnchor).isActive = true
        subtitleField.trailingAnchor.constraint(equalTo: titleField.trailingAnchor).isActive = true
        subtitleField.heightAnchor.constraint(equalToConstant: view.frame.height * 0.05).isActive = true
        subtitleField.layer.borderWidth = 2
        subtitleField.layer.cornerRadius = 5
        subtitleField.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
}


