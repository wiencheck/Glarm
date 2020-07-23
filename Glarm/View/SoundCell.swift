//
//  SoundCell.swift
//  Glarm
//
//  Created by Adam Wienconek on 21/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

protocol SoundCellDelegate: class {
    func soundCell(didPressDownloadButtonIn cell: SoundCell)
}

class SoundCell: UITableViewCell {
    internal lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.textColor = .label()
        return l
    }()
    
    internal lazy var indicatorView: UIActivityIndicatorView = {
        let i: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            i = UIActivityIndicatorView(style: .medium)
        } else {
            i = UIActivityIndicatorView(style: .gray)
        }
        i.hidesWhenStopped = true
        return i
    }()
    
    private lazy var downloadButton: UIButton = {
        let b = UIButton()
        b.image = .download
        b.pressHandler = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.soundCell(didPressDownloadButtonIn: self)
        }
        return b
    }()
    
    weak var delegate: SoundCellDelegate?
    
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
    }
    
    func configure(with model: Model?) {
        guard let model = model else { return }
        titleLabel.text = model.name
        downloadButton.isHidden = model.isLocal
        accessoryType = model.isSelected ? .checkmark : .none
    }
    
    func setLoading(_ loading: Bool) {
        downloadButton.isHidden = loading
        loading ? indicatorView.startAnimating() : indicatorView.stopAnimating()
    }
        
    internal func commonInit() {
        setupView()
    }
    
    /// This method should be completely overwritten by subclasses.
    internal func setupView() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.greaterThanOrEqualTo(34)
            make.leading.equalTo(layoutMarginsGuide)
            make.bottom.equalTo(layoutMarginsGuide).offset(6)
        }
        
        addSubview(downloadButton)
        downloadButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(downloadButton.snp.height)
            make.width.equalTo(30)
            make.trailing.equalTo(layoutMarginsGuide)
        }
        
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.center.equalTo(downloadButton)
        }
    }
}

extension SoundCell {
    struct Model {
        init(name: String, isLocal: Bool = true, isSelected: Bool) {
            self.name = name
            self.isLocal = isLocal
            self.isSelected = isSelected
        }
        
        init(sound: Sound, isSelected: Bool) {
            self.init(name: sound.name, isLocal: sound.isLocal, isSelected: isSelected)
        }
        
        let name: String
        let isLocal: Bool
        let isSelected: Bool
    }
}
