//
//  UITableView.swift
//  Plum
//
//  Created by Adam Wienconek on 15.04.2019.
//  Copyright © 2019 adam.wienconek. All rights reserved.
//

import UIKit
import EmptyBackgroundView

extension UITableView {
    @objc func reloadData(animated: Bool, options: UIView.AnimationOptions = .transitionCrossDissolve, completion: ((Bool) -> Void)? = nil) {
        let animations = {
            self.reloadData()
        }
        if animated {
            UIView.transition(with: self, duration: 0.2, options: options, animations: animations, completion: completion)
        } else {
            animations()
            completion?(true)
        }
    }
    
    func deleteRow(at indexPath: IndexPath, with animation: RowAnimation) {
        deleteRows(at: [indexPath], with: animation)
    }
    
    func reloadSection(_ section: Int, with animation: RowAnimation) {
        reloadSections([section], with: animation)
    }
    
    var isEmpty: Bool {
        var number = 0
        for i in 0 ..< numberOfSections {
            number += numberOfRows(inSection: i)
        }
        return number == 0
    }
}
