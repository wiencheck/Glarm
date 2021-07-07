//
//  SmallWidgetEntryView.swift
//  GlarmWidgetExtension
//
//  Created by Adam Wienconek on 29/06/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI
import WidgetKit

struct SmallWidgetEntryView: View {
    let entry: WidgetAlarmsProvider.Entry
    
    var body: some View {
        GeometryReader { gp in
            HStack {
                Image(uiImage: entry.snapshot)
                VStack {
                    Text("To go")
                        .foregroundColor(Color(.tint))
                        .font(.title3)
                    Text(entry.distance.readableRepresentation())
                }
                    //.frame(width: gp.size.width * Constants.smallWidgetImageSizeRatio.width, height: Constants.smallWidgetImageSizeRatio.height)
            }
        }
    }
}

struct SmallWidgetEntryView_Previews: PreviewProvider {

  static var previews: some View {
    SmallWidgetEntryView(entry: .placeholder)
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
