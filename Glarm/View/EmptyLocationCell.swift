//
//  EmptyLocationCell.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 11/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

class EmptyLocationCell: UITableViewCell {
    
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel()
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        l.text = LocalizedStringKey.emptyCellTitle.localized
        return l
    }()
    
    private lazy var detailLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.numberOfLines = 0
        l.text = LocalizedStringKey.emptyCellDetail.localized
        return l
    }()
    
    private lazy var stack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        s.axis = .vertical
        s.alignment = .center
        return s
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setupView()
    }
}

private extension EmptyLocationCell {
    func setupView() {
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.top.greaterThanOrEqualTo(layoutMarginsGuide).offset(8)
        }
    }
}
