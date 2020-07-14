//
//  AlarmCell.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 06/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import SnapKit

final class AlarmCell: UITableViewCell {
    static let preferredHeight: CGFloat = 114
    
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.textColor = .label()
        return l
    }()
    
    private lazy var detailLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel()
        return l
    }()
    
    private lazy var rightDetailLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel()
        l.setContentHuggingPriority(.required, for: .vertical)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        return l
    }()
    
    private lazy var markedView: UIImageView = {
        let i = UIImageView(image: .star)
        i.contentMode = .scaleAspectFit
        return i
    }()
    
    private lazy var indicatorView: UIImageView = {
        let i = UIImageView(image: .disclosure)
        i.tintColor = .gray
        i.contentMode = .scaleAspectFit
        return i
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        detailLabel.text = nil
        rightDetailLabel.text = nil
    }
    
    func configure(with model: AlarmCellViewModel?) {
        guard let model = model else {
            return
        }
        titleLabel.text = model.locationInfo.identifier
        detailLabel.text = model.locationInfo.radius.readableRepresentation
        rightDetailLabel.text = model.date
        if let marked = model.marked {
            markedView.isHidden = !marked
        } else {
            markedView.isHidden = true
        }
    }
    
    private func commonInit() {
        setupView()
    }
}

private extension AlarmCell {
    func setupView() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(layoutMarginsGuide)
        }
        
        addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.equalTo(layoutMarginsGuide)
            make.leading.equalTo(titleLabel)
        }
        
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.top.equalTo(layoutMarginsGuide)
            make.trailing.equalTo(layoutMarginsGuide)
            make.height.equalTo(indicatorView.snp.width)
            make.height.equalTo(10)
        }

        addSubview(rightDetailLabel)
        rightDetailLabel.snp.makeConstraints { make in
            make.centerY.equalTo(indicatorView)
            make.trailing.equalTo(indicatorView.snp.leading).offset(-2)
        }

        addSubview(markedView)
        markedView.snp.makeConstraints { make in
            make.trailing.equalTo(layoutMarginsGuide)
            make.top.equalTo(indicatorView.snp.bottom).offset(10)
            make.height.equalTo(markedView.snp.width)
            make.height.equalTo(12)
        }
    }
}
