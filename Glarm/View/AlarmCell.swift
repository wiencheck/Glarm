//
//  AlarmCell.swift
//  Glarm
//
//  Created by Adam Wienconek on 19/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import SnapKit

protocol AlarmCellDelegate: class {
    func alarmCell(didPressShowNote cell: AlarmCell)
}

class AlarmCell: UITableViewCell {
    internal lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .title
        l.textColor = .label()
        return l
    }()
    
    internal lazy var detailLabel: UILabel = {
        let l = UILabel()
        l.font = .subtitle
        l.textColor = .secondaryLabel()
        l.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return l
    }()
    
    internal lazy var noteButton: UIButton = {
        let b = UIButton(type: .system)
        b.text = LocalizedStringKey.browse_showNote.localized
        b.textColor = .tint
        b.pressHandler = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.alarmCell(didPressShowNote: self)
        }
        b.contentHorizontalAlignment = .leading
        b.titleLabel?.font = .subtitle
        return b
    }()
    
    internal lazy var rightDetailLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel()
        l.setContentHuggingPriority(.required, for: .vertical)
        l.font = .preferredFont(forTextStyle: .caption1)
        return l
    }()
    
    internal lazy var categoryLabel: UILabel = {
        let l = UILabel()
        l.textColor = .tint
        l.textAlignment = .right
        l.setContentHuggingPriority(.required, for: .vertical)
        l.font = .subtitle
        return l
    }()
    
    internal lazy var categoryImageView: UIImageView = {
        let i = UIImageView(image: .folder)
        i.tintColor = .tint
        i.contentMode = .scaleAspectFit
        return i
    }()
    
    internal lazy var indicatorView: UIImageView = {
        let i = UIImageView(image: .disclosure)
        i.tintColor = .gray
        i.contentMode = .scaleAspectFit
        return i
    }()
    
    weak var delegate: AlarmCellDelegate?
    
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
    
    func configure(with model: AlarmCell.Model?) {
        guard let model = model else {
            return
        }
        titleLabel.text = model.locationInfo.name
        noteButton.isHidden = model.note == nil || model.note?.isEmpty == true
        detailLabel.text = model.locationInfo.radius.readableRepresentation()
        rightDetailLabel.text = model.date
        categoryLabel.text = model.category
        if let category = model.category {
            categoryImageView.isHidden = category.isEmpty
        } else {
            categoryImageView.isHidden = true
        }
    }
    
    internal func commonInit() {
        setupView()
    }
    
    /// This method should be completely overwritten by subclasses.
    internal func setupView() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel, noteButton])
        stack.axis = .vertical
        stack.spacing = 4
        addSubview(stack)
        
        stack.snp.makeConstraints { make in
            make.top.bottom.leading.equalTo(layoutMarginsGuide)
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
            make.leading.greaterThanOrEqualTo(stack.snp.trailing).offset(4)
            make.centerY.equalTo(indicatorView)
            make.trailing.equalTo(indicatorView.snp.leading).offset(-2)
        }
        
        addSubview(categoryLabel)
        categoryLabel.snp.makeConstraints { make in
            make.trailing.equalTo(layoutMarginsGuide)
            make.centerY.equalTo(detailLabel)
        }
        
        addSubview(categoryImageView)
        categoryImageView.snp.makeConstraints { make in
            make.height.equalTo(categoryImageView.snp.width)
            make.height.equalTo(16)
            make.leading.greaterThanOrEqualTo(detailLabel.snp.trailing).offset(2)
            make.trailing.equalTo(categoryLabel.snp.leading).offset(-2)
            make.centerY.equalTo(detailLabel)
        }
    }
}

extension AlarmCell {
    struct Model {
        init(locationInfo: LocationNotificationInfo, note: String?, date: String? = nil, category: String? = nil) {
            self.locationInfo = locationInfo
            self.note = note
            self.date = date
            self.category = category
        }
        
        init(alarm: AlarmEntry) {
            self.init(locationInfo: alarm.locationInfo, note: alarm.note, date: DateFormatter.localizedString(from: alarm.date, dateStyle: .short, timeStyle: .none), category: alarm.category)
        }
        
        var locationInfo: LocationNotificationInfo
        var note: String?
        var date: String?
        var category: String?
    }
}
