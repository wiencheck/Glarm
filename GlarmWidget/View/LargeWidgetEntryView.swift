//
//  LargeWidgetEntryView.swift
//  GlarmWidgetExtension
//
//  Created by Adam Wienconek on 02/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI
import WidgetKit

struct LargeWidgetEntryView: View {
    let entry: WidgetAlarmsProvider.Entry
    
    var body: some View {
        GeometryReader { gp in
            HStack(alignment: .top) {
                Image(uiImage: entry.snapshot)
                    .resizable()
                    .scaledToFill()
                    .frame(width: gp.size.width * Constants.largeWidgetImageSizeRatio.width,
                           height: gp.size.height * Constants.largeWidgetImageSizeRatio.height)
                LargeWidgetDetailsView(entry: entry)
            }
        }
    }
}

fileprivate struct LargeWidgetDetailsView: View {
    let entry: WidgetAlarmsProvider.Entry
    
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.name)
                .font(.subheadline)
            
            Divider()
            Text("Distance")
                .font(.headline)
                .foregroundColor(Color(UIColor.tint))
            Text(entry.distance.readableRepresentation())
                .font(.callout)
            
            if let timeOfArrival = entry.timeOfArrival {
                Divider()
                Text("ETA")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.tint))
                Text(timeOfArrival.timeDescription)
            }
            
            if !entry.note.isEmpty {
                Divider()
                Text("Note")
                    .font(.headline)
                    .foregroundColor(Color(UIColor.tint))
                Text(entry.note)
            }
        }.padding()
    }
}

struct LargeWidgetEntryView_Previews: PreviewProvider {

  static var previews: some View {
    LargeWidgetEntryView(entry: .placeholder)
    .previewContext(WidgetPreviewContext(family: .systemLarge))
  }
}
