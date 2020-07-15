//
//  UITableView.swift
//  Plum
//
//  Created by Adam Wienconek on 15.04.2019.
//  Copyright © 2019 adam.wienconek. All rights reserved.
//

import UIKit

extension UITableView {
    func reloadData(animated: Bool, options: UIView.AnimationOptions = .transitionCrossDissolve, completion: ((Bool) -> Void)? = nil) {
        let animations = {
            self.reloadData()
            self.updateEmptyView()
        }
        if animated {
            UIView.transition(with: self, duration: 0.3, options: options, animations: animations, completion: completion)
        } else {
            animations()
            completion?(true)
        }
    }
    
    func deleteRow(at indexPath: IndexPath, with animation: RowAnimation) {
        deleteRows(at: [indexPath], with: animation)
        updateEmptyView()
    }
    
    func reloadSection(_ section: Int, with animation: RowAnimation) {
        reloadSections([section], with: animation)
        updateEmptyView()
    }
    
    func updateEmptyView() {
        guard let emptyView = self.backgroundView as? EmptyBackgroundView else {
            return
        }
        isScrollEnabled = !isEmpty
        emptyView.isEmpty = isEmpty
    }
    
    var isEmpty: Bool {
        var number = 0
        for i in 0 ..< numberOfSections {
            number += numberOfRows(inSection: i)
        }
        return number == 0
    }
}
