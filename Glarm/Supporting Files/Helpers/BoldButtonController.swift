//
//  BoldButtonController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 11/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import BoldButton

protocol BoldButtonViewControllerDelegate: AnyObject {
    func boldButtonPressed(_ sender: BoldButton)
}

class BoldButtonViewController: UIViewController {
    var text: String? {
           get {
               return button.text
           } set {
               button.text = newValue
           }
       }
    
    var isEnabled: Bool {
           get {
               return button.isEnabled
           } set {
               button.isEnabled = newValue
           }
       }
    
    var isSelected: Bool {
        get {
            return button.isSelected
        } set {
            button.isSelected = newValue
        }
    }
    
    var isLoading: Bool {
        get {
            return button.isLoading
        } set {
            button.isLoading = newValue
        }
    }
    
    private lazy var button: BoldButton = {
        let b = BoldButton()
        b.isSelected = true
        b.pressHandler = { [weak self] sender in
            self?.delegate?.boldButtonPressed(sender)
        }
        return b
    }()
    
    weak var delegate: BoldButtonViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView() {
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(48)
            make.height.equalToSuperview().multipliedBy(0.6)
        }
    }
}
