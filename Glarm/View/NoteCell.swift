//
//  NoteCell.swift
//  Glarm
//
//  Created by Adam Wienconek on 19/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import SnapKit

protocol NoteCellDelegate: class {
    func noteCell(shouldBeginEditingTextIn cell: NoteCell) -> Bool
    func noteCell(didChangeTextIn cell: NoteCell)
}

final class NoteCell: UITableViewCell {
    private lazy var placeholderTextView: UITextView = {
        let t = UITextView()
        t.isScrollEnabled = false
        t.isEditable = false
        t.backgroundColor = .clear
        t.text = LocalizedStringKey.edit_notePlaceholder.localized
        t.font = .noteText
        t.textColor = .secondaryLabel()
        return t
    }()
    
    private lazy var textView: UITextView = {
        let t = UITextView()
        t.backgroundColor = .clear
        t.isScrollEnabled = false
        t.isEditable = true
        t.delegate = self
        t.font = .noteText
        return t
    }()
    
    weak var delegate: NoteCellDelegate?
    
    var noteText: String {
        get {
            return textView.text ?? ""
        } set {
            placeholderTextView.isHidden = !newValue.isEmpty
            textView.text = newValue
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func clearText() {
        textView.text = ""
        textViewDidChange(textView)
    }
    
    private func commonInit() {
        setupView()
        selectionStyle = .none
    }
}

extension NoteCell: UITextViewDelegate {
    internal func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return delegate?.noteCell(shouldBeginEditingTextIn: self) ?? true
    }
    
    internal func textViewDidChange(_ textView: UITextView) {
        placeholderTextView.isHidden = !textView.text.isEmpty
        delegate?.noteCell(didChangeTextIn: self)
    }
}

private extension NoteCell {
    func setupView() {
        contentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalTo(layoutMargins)
        }
        
        contentView.insertSubview(placeholderTextView, belowSubview: textView)
        placeholderTextView.snp.makeConstraints { make in
            make.edges.equalTo(textView)
        }
    }
}
