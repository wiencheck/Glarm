//
//  Notification.Name.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

extension Notification.Name {
    @discardableResult
    func observe(object: Any? = nil, queue: OperationQueue? = nil, handler: @escaping (Notification) -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(forName: self, object: object, queue: queue, using: handler)
    }
}
