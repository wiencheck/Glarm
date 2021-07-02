//
//  WidgetDetailsView.swift
//  GlarmWidgetExtension
//
//  Created by Adam Wienconek on 02/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI

struct WidgetmediumDetailsView: View {
    private let entry: WidgetAlarmsProvider.Entry
    
    var body: some View {
        VStack {
            Text(entry.alarm.locationInfo?.name ?? "Chuj")
        }
    }
}
