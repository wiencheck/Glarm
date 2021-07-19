//
//  EmptyWidgetEntryView.swift
//  GlarmWidgetExtension
//
//  Created by Adam Wienconek on 07/07/2021.
//  Copyright © 2021 Adam Wienconek. All rights reserved.
//

import SwiftUI
import WidgetKit

struct EmptyWidgetEntryView: View {
    
    var body: some View {
        VStack(alignment: .center) {
            Text("No alarm scheduled")
                .font(.headline)
                .foregroundColor(Color(UIColor.tint))
                .multilineTextAlignment(.center)
            Text("Press here to create one +")
                .multilineTextAlignment(.center)
        }
        .widgetURL(URL(scheme: SharedConstants.newAlarmURLScheme))
    }
    
}

struct EmptyWidgetEntryView_Previews: PreviewProvider {

  static var previews: some View {
    EmptyWidgetEntryView()
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
