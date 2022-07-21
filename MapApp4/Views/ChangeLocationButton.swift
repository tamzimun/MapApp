//
//  NavigationButton.swift
//  MapApp4
//
//  Created by Aida Moldaly on 29.06.2022.
//

import UIKit


class ChangeLocationButton: UIButton {
    init(arrowString: String) {
        super.init(frame: .zero)
        
        setTitle(arrowString, for: .normal)
        backgroundColor = .systemGray3
        titleLabel?.textColor = .white
        layer.cornerRadius = 20
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

