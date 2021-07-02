//
//  WidgetLargeDetailsView.swift
//  GlarmWidgetExtension
//
//  Created by Adam Wienconek on 02/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI

struct LargeWidgetDetailsView: View {
    let entry: WidgetAlarmsProvider.Entry
    
    var body: some View {
        HStack {
            Text("entry.alarm.note")
        }
    }
}
