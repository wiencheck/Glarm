//
//  AlarmCellViewModel.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 11/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import Foundation

struct AlarmCellViewModel {
    init(locationInfo: LocationNotificationInfo, date: String? = nil, marked: Bool? = nil) {
        self.locationInfo = locationInfo
        self.date = date
        self.marked = marked
    }
    
    let locationInfo: LocationNotificationInfo
    let date: String?
    let marked: Bool?
}
