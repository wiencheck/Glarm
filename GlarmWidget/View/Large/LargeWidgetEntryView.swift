//
//  LargeWidgetEntryView.swift
//  GlarmWidgetExtension
//
//  Created by Adam Wienconek on 02/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI

struct LargeWidgetEntryView: View {
    let entry: WidgetAlarmsProvider.Entry
    
    var body: some View {
        GeometryReader { gp in
            HStack {
                Image(uiImage: entry.snapshot)
                    //.frame(width: gp.size.width * Constants.largeWidgetImageSizeRatio.width, height: Constants.largeWidgetImageSizeRatio.height)
                LargeWidgetDetailsView(entry: entry)
            }
        }
    }
}
