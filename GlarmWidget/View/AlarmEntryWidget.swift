//
//  AlarmEntryWidget.swift
//  GlarmWidgetExtension
//
//  Created by Adam Wienconek on 02/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    let entry: WidgetAlarmsProvider.Entry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemLarge:
            LargeWidgetEntryView(entry: entry)
        default:
            SmallWidgetEntryView(entry: entry)
        }
    }
}

@main
struct AlarmEntryWidget: Widget {
    private let kind = "My_widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WidgetAlarmsProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
