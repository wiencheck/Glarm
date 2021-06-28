//
//  AlarmCell.swift
//  Glarm
//
//  Created by Adam Wienconek on 19/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import SnapKit

protocol AlarmCellDelegate: AnyObject {
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
        i.setEqualAspectRatio()
        return i
    }()
    
    internal lazy var indicatorView: UIImageView = {
        let i = UIImageView(image: .disclosure)
        i.tintColor = .gray
        i.contentMode = .scaleAspectFit
        return i
    }()
    
    internal lazy var markedImageView: UIImageView = {
        let i = UIImageView(image: .star)
        i.contentMode = .scaleAspectFit
        i.setEqualAspectRatio()
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
        titleLabel.text = model.locationInfo?.name ?? "–"
        noteButton.isHidden = model.note == nil || model.note?.isEmpty == true
        detailLabel.text = model.locationInfo?.radius.readableRepresentation() ?? "–"
        rightDetailLabel.text = model.date
        markedImageView.isHidden = !model.isMarked
        
        categoryLabel.isHidden = model.category == nil
        categoryImageView.isHidden = model.category == nil
        categoryLabel.text = model.category?.name
        if let category = model.category {
            categoryImageView.image = UIImage(systemName: category.imageName ?? "folder")
        } else {
            categoryImageView.image = nil
        }
    }
    
    internal func commonInit() {
        setupView()
    }
    
    /// This method should be completely overwritten by subclasses.
    internal func setupView() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel, noteButton])
        stack.axis = .vertical
        stack.spacing = 5
        contentView.addSubview(stack)
        
        stack.snp.makeConstraints { make in
            make.top.bottom.leading.equalTo(contentView.layoutMarginsGuide)
        }
        
        contentView.addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.top.equalTo(contentView.layoutMarginsGuide)
            make.trailing.equalTo(contentView.layoutMarginsGuide)
            make.height.equalTo(indicatorView.snp.width)
            make.height.equalTo(10)
        }
        
        contentView.addSubview(rightDetailLabel)
        rightDetailLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(stack.snp.trailing).offset(4)
            make.centerY.equalTo(indicatorView)
            make.trailing.equalTo(indicatorView.snp.leading).offset(-2)
        }
        
        let categoryStack = UIStackView(arrangedSubviews: [categoryImageView, categoryLabel, markedImageView])
        categoryStack.axis = .horizontal
        categoryStack.spacing = 5
        
        contentView.addSubview(categoryStack)
        categoryStack.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(detailLabel.snp.trailing).offset(2)
            make.trailing.equalTo(contentView.layoutMarginsGuide)
            make.centerY.equalTo(detailLabel)
            make.height.equalTo(16)
        }
    }
}

extension AlarmCell {
    struct Model {
        init(locationInfo: LocationNotificationInfo?, note: String?, date: String? = nil, category: Category? = nil, isMarked: Bool = false) {
            self.locationInfo = locationInfo
            self.note = note
            self.date = date
            if let category = category {
                self.category = (category.name, category.imageName)
            } else {
                self.category = nil
            }
            self.isMarked = isMarked
        }
        
        init(alarm: AlarmEntryProtocol) {
            self.init(locationInfo: alarm.locationInfo, note: alarm.note, date: DateFormatter.localizedString(from: alarm.dateCreated, dateStyle: .short, timeStyle: .none), category: alarm.category, isMarked: alarm.isMarked)
        }
        
        var locationInfo: LocationNotificationInfo?
        var note: String?
        var date: String?
        var category: (name: String, imageName: String?)?
        var isMarked: Bool
    }
}
