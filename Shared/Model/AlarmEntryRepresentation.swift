//
//  AlarmEntryRepresentation.swift
//  Glarm
//
//  Created by Adam Wienconek on 23/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import Foundation

/// Stripped-down representation of alarm entry object.
struct AlarmEntryRepresentation: Codable {
    let locationInfo: LocationNotificationInfo?
    let note: String
}
