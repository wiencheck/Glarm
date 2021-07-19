//
//  UITableViewCell.swift
//  Glarm
//
//  Created by Adam Wienconek on 20/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

extension UITableView {
    /**
     Shows a hint to the user indicating that cell can be swiped left.
     - Parameters:
        - width: Width of hint.
        - duration: Duration of animation (in seconds)
     */
    func presentTrailingSwipeHint(width: CGFloat = 20, duration: TimeInterval = 0.8) {
        var actionPath: IndexPath?
        var actionColor: UIColor?
        
        if #available(iOS 13.0, *) {
            // Use new API, UIContextualAction
            for path in indexPathsForVisibleRows ?? [] {
                if let config = delegate?.tableView?(self, trailingSwipeActionsConfigurationForRowAt: path), let action = config.actions.first {
                    actionPath = path
                    actionColor = action.backgroundColor
                    break
                }
            }
        } else {
            for path in indexPathsForVisibleRows ?? [] {
                if let actions = delegate?.tableView?(self, editActionsForRowAt: path), let action = actions.first {
                    actionPath = path
                    actionColor = action.backgroundColor
                    break
                }
            }
        }
        guard let path = actionPath, let cell = cellForRow(at: path) else { return }
        cell.presentTrailingSwipeHint(actionColor: actionColor ?? tintColor)
    }
}

fileprivate extension UITableViewCell {
    func presentTrailingSwipeHint(actionColor: UIColor, hintWidth: CGFloat = 20, hintDuration: TimeInterval = 0.8) {
        // Create fake action view
        let dummyView = UIView()
        dummyView.backgroundColor = actionColor
        dummyView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dummyView)
        // Set constraints
        NSLayoutConstraint.activate([
            dummyView.topAnchor.constraint(equalTo: topAnchor),
            dummyView.leadingAnchor.constraint(equalTo: trailingAnchor),
            dummyView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dummyView.widthAnchor.constraint(equalToConstant: hintWidth)
        ])
        // This animator reverses back the transform.
        let secondAnimator = UIViewPropertyAnimator(duration: hintDuration / 2, curve: .easeOut) {
            self.transform = .identity
        }
        // Don't forget to remove the useless view.
        secondAnimator.addCompletion { position in
            dummyView.removeFromSuperview()
        }

        // We're moving the cell and since dummyView
        // is pinned to cell's trailing anchor
        // it will move as well.
        let transform = CGAffineTransform(translationX: -hintWidth, y: 0)
        let firstAnimator = UIViewPropertyAnimator(duration: hintDuration / 2, curve: .easeIn) {
            self.transform = transform
        }
        firstAnimator.addCompletion { position in
            secondAnimator.startAnimation()
        }
        // Do the magic.
        firstAnimator.startAnimation()
    }
    
    func setTitle(text: String?) {
//        if #available(iOS 14.0, *) {
//            contentConfiguration
//        }
    }
    
    func setSubtitle(text: String?) {
        
    }
}
