//
//  UIFont.swift
//  Glarm
//
//  Created by Adam Wienconek on 07/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit

extension UIFont {
    static let title = UIFont.preferredFont(forTextStyle: .headline)
    static let subtitle = UIFont.preferredFont(forTextStyle: .subheadline)
    static let noteButton = UIFont.preferredFont(forTextStyle: .footnote)
    static let noteText = UIFont.preferredFont(forTextStyle: .body)
    static let headerTitle = UIFont.preferredFont(forTextStyle: .subheadline, weight: .medium)
    
    static func preferredFont(forTextStyle style: TextStyle, weight: Weight) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        return metrics.scaledFont(for: font)
    }
}
