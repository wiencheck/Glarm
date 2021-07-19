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
        ZStack {
            Color(.secondarySystemGroupedBackground)
            if isEmpty {
                EmptyWidgetEntryView()
            } else {
                switch family {
                case .systemLarge:
                    LargeWidgetEntryView(entry: entry)
                case .systemMedium:
                    MediumWidgetEntryView(entry: entry)
                default:
                    SmallWidgetEntryView(entry: entry)
                }
            }
        }
        .widgetURL(url)
    }
    
    private var isEmpty: Bool { entry.name == "None" }
    
    private var url: URL? {
        if isEmpty {
            return URL(scheme: SharedConstants.newAlarmURLScheme)
        } else {
            let urlString = SharedConstants.editAlarmURLScheme + .schemeAppendix + entry.uid
            return URL(string: urlString)
        }
    }
}

@main
struct AlarmEntryWidget: Widget {
    private let kind = "com.glarm.map-widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WidgetAlarmsProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Map Widget")
        .description("Displays your position on the map.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
