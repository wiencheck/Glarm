//
//  TableHeaderView.swift
//  Glarm
//
//  Created by Adam Wienconek on 20/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

final class TableHeaderView: UITableViewHeaderFooterView {
    static let preferredHeight: CGFloat = 34
    
    private lazy var label: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        return l
    }()
    
    private lazy var button: UIButton = {
        let b = UIButton(type: .system)
        b.alpha = 0
        b.text = "Button"
        b.backgroundColor = .tint
        b.textColor = .white
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        b.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        b.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return b
    }()
    
    var title: String? {
        get {
            return label.text
        } set {
            label.text = newValue?.uppercased()
        }
    }
    
    var buttonTitle: String? {
        get {
            return button.text
        } set {
            // To żeby nie było glitchy w animacji
            if let text = newValue {
                button.text = text
                UIView.animate(withDuration: 0.2) {
                    self.button.alpha = 1
                }
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.button.alpha = 0
                }) { _ in
                    self.button.text = nil
                }
            }
        }
    }
    
    var pressHandler: ((TableHeaderView) -> Void)? {
        didSet {
            isUserInteractionEnabled = pressHandler != nil
            button.pressHandler = { _ in
                self.pressHandler?(self)
            }
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        button.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.layer.cornerRadius = 12
    }
        
    private func commonInit() {
        isUserInteractionEnabled = false
        setupView()
    }
    
    func configure(with model: Model?) {
        title = model?.title
        buttonTitle = model?.buttonTitle
        pressHandler = model?.pressHandler
    }
}

extension TableHeaderView {
    struct Model {
        let title: String
        let buttonTitle: String?
        let pressHandler: ((TableHeaderView) -> Void)?
        
        init(title: String, buttonTitle: String? = nil, pressHandler: ((TableHeaderView) -> Void)? = nil) {
            self.title = title
            self.buttonTitle = buttonTitle
            self.pressHandler = pressHandler
        }
    }
}

private extension TableHeaderView {
    func setupView() {
        addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(layoutMarginsGuide)
        }
        
        addSubview(button)
        button.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(layoutMarginsGuide)
            make.leading.greaterThanOrEqualTo(label.snp.trailing).offset(12)
        }
    }
}