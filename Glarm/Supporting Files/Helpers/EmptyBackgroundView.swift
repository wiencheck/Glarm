//
//  EmptyBackgroundView.swift
//  Plum
//
//  Created by Adam Wienconek on 28.07.2019.
//  Copyright © 2019 adam.wienconek. All rights reserved.
//

import UIKit

final class EmptyBackgroundView: UIView {
    
    private var stackView: UIStackView!
    private var imageView: UIImageView!
    private var topLabel: UILabel!
    private var bottomLabel: UILabel!
    
    private let topColor = UIColor.darkGray
    private let topFont = UIFont.boldSystemFont(ofSize: 22)
    private let bottomColor = UIColor.gray
    private let bottomFont = UIFont.systemFont(ofSize: 18)
    
    private let spacing: CGFloat = 10
    private let imageViewHeight: CGFloat = 100
    private let bottomLabelWidth: CGFloat = 300
    
    var didSetupConstraints = false
    
    var isEmpty: Bool {
        get {
            return stackView.alpha == 1
        } set {
            stackView.alpha = newValue ? 1 : 0
        }
    }
    
    convenience init() {
        self.init(image: nil, top: nil, bottom: nil)
    }
    
    init(image: UIImage?, top: String?, bottom: String?) {
        super.init(frame: .zero)
        setupImageView(with: image)
        setupLabels(top: top, bottom: bottom)
        setupStackView()
        setConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupStackView() {
        topLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        bottomLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        stackView = UIStackView(arrangedSubviews: [imageView, topLabel, bottomLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        stackView.alpha = 0
        addSubview(stackView)
    }
    
    func setupImageView(with image: UIImage?) {
        imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = topColor
        imageView.isHidden = image == nil
    }
    
    func setupLabels(top: String?, bottom: String?) {
        topLabel = UILabel()
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        topLabel.numberOfLines = 0
        topLabel.textAlignment = .center
        topLabel.text = top
        topLabel.textColor = topColor
        topLabel.font = topFont
        topLabel.isHidden = top == nil

        bottomLabel = UILabel()
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.text = bottom
        bottomLabel.textColor = bottomColor
        bottomLabel.font = bottomFont
        bottomLabel.numberOfLines = 0
        bottomLabel.textAlignment = .center
        bottomLabel.isHidden = bottom == nil
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.6),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.7)
            ])
    }
}
