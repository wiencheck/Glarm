//
//  MediumWidgetEntryView.swift
//  Glarm
//
//  Created by Adam Wienconek on 05/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI
import WidgetKit

struct MediumWidgetEntryView: View {
    let entry: WidgetAlarmsProvider.Entry
    
    var body: some View {
        GeometryReader { gp in
            HStack(alignment: .top) {
                Image(uiImage: entry.snapshot)
                    .resizable()
                    .scaledToFill()
                    .frame(width: gp.size.width * Constants.mediumWidgetImageSizeRatio.width,
                           height: gp.size.height * Constants.mediumWidgetImageSizeRatio.height)
                MediumWidgetDetailsView(entry: entry)
            }
        }
    }
}

fileprivate struct MediumWidgetDetailsView: View {
    let entry: WidgetAlarmsProvider.Entry
    
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.name)
                .font(.subheadline)
            
            Divider()
            Text("Distance")
                .font(.callout)
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
        }.padding()
    }
}

struct MediumWidgetEntryView_Previews: PreviewProvider {

  static var previews: some View {
    MediumWidgetEntryView(entry: .placeholder)
    .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
