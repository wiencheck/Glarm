//
//  UIView.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 09/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import SnapKit

extension UIView {
    func pinToSuperView() {
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
