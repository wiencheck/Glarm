//
//  AWTableView.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import UIKit
import EmptyBackgroundView

final class AWTableView: UITableView {
    
    private var emptyView: EmptyBackgroundView? {
        get {
            return backgroundView as? EmptyBackgroundView
        } set {
            backgroundView = newValue
        }
    }
    
    override func reloadData(animated: Bool, options: UIView.AnimationOptions = .transitionCrossDissolve, completion: ((Bool) -> Void)? = nil) {
        super.reloadData(animated: animated, options: options, completion: { succ in
            completion?(succ)
            self.updateEmptyView(isEmpty: self.isEmpty)
        })
    }
    
    func setEmptyView(image: UIImage?, title: String?, message: String?) {
        if emptyView == nil {
            emptyView = EmptyBackgroundView(image: image, top: title, bottom: message)
            return
        }
        emptyView!.image = image
        emptyView!.title = title
        emptyView!.message = message
    }
    
    func setDefaultEmptyView() {
        setEmptyView(image: nil, title: "No data", message: "Woopsie")
    }
    
    fileprivate func updateEmptyView(isEmpty: Bool) {
        guard let emptyView = emptyView else {
            backgroundView = nil
            isScrollEnabled = true
            return
        }
        if backgroundView is EmptyBackgroundView == false {
            backgroundView = emptyView
        }
        if !isMoving {
            isScrollEnabled = !isEmpty
        }
        emptyView.isVisible = isEmpty
    }
}
