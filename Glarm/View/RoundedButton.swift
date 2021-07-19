//
//  RoundedButton.swift
//  Glarm
//
//  Created by Adam Wienconek on 19/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import UIKit

class BorderedButton: UIButton {
    
    convenience init() {
        self.init(type: .custom)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        layer.cornerRadius = 8
        setTitleColor(.label, for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: 5,
                                         left: 14,
                                         bottom: 5,
                                         right: 14)
        backgroundColor = UIColor.label
            .resolvedColor(with: traitCollection)
            .withAlphaComponent(0.05)
        titleLabel?.font = .roundedButton
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        backgroundColor = UIColor.label
            .resolvedColor(with: traitCollection)
            .withAlphaComponent(0.05)
    }
}
