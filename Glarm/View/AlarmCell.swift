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
    static let preferredHeight: CGFloat = 114
    
    internal lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.textColor = .label()
        return l
    }()
    
    internal lazy var detailLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel()
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
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        return b
    }()
    
    internal lazy var rightDetailLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel()
        l.setContentHuggingPriority(.required, for: .vertical)
        l.font = .systemFont(ofSize: 14, weight: .regular)
        return l
    }()
    
    internal lazy var markedView: UIImageView = {
        let i = UIImageView(image: .star)
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
        if let marked = model.marked {
            markedView.isHidden = !marked
        } else {
            markedView.isHidden = true
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
            make.top.leading.equalTo(layoutMarginsGuide)
            make.bottom.equalTo(layoutMarginsGuide).offset(6)
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

extension AlarmCell {
    struct Model {
        init(locationInfo: LocationNotificationInfo, note: String?, date: String? = nil, marked: Bool? = nil) {
            self.locationInfo = locationInfo
            self.note = note
            self.date = date
            self.marked = marked
        }
        
        init(alarm: AlarmEntry) {
            self.init(locationInfo: alarm.locationInfo, note: alarm.note, date: DateFormatter.localizedString(from: alarm.date, dateStyle: .short, timeStyle: .none), marked: alarm.isMarked)
        }
        
        let locationInfo: LocationNotificationInfo
        let note: String?
        let date: String?
        let marked: Bool?
    }
}
