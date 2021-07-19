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
    
    private(set) lazy var label: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel()
        l.font = .headerTitle
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        return l
    }()
    
    private(set) lazy var imageView: UIImageView = {
        let i = UIImageView()
        i.tintColor = .label
        return i
    }()
    
    private(set) lazy var button: UIButton = {
        let b = UIButton(type: .system)
        b.alpha = 0
        b.text = "Button"
        b.backgroundColor = .tint
        b.textColor = .white
        b.titleLabel?.font = .headerTitle
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
    
    var image: UIImage? {
        get {
            imageView.image
        } set {
            imageView.image = newValue
        }
    }
    
    var buttonTitle: String? {
        get {
            return button.text
        } set {
            isUserInteractionEnabled = newValue != nil
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
        imageView.image = nil
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
        let stack = UIStackView(arrangedSubviews: [label, imageView])
        stack.axis = .horizontal
        stack.spacing = 8
        
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(contentView.layoutMarginsGuide)
        }
        
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.top.equalToSuperview().inset(6)

            make.trailing.equalTo(contentView.layoutMarginsGuide)
            make.leading.greaterThanOrEqualTo(stack.snp.trailing).offset(12)
        }
    }
}
