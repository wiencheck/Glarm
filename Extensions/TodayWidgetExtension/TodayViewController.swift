//
//  TodayViewController.swift
//  TodayWidgetExtension
//
//  Created by Adam Wienconek on 07/08/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    private lazy var mapController = ExtensionViewController(shouldDisplayMap: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        add(child: mapController)
        mapController.delegate = self
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        preferredContentSize.height = mapController.contentHeight
//    }
    
    private func fetchActiveAlarm() -> SimplifiedAlarmEntry? {
        let suite = UserDefaults.appGroupSuite
        guard let alarm = suite.alarm(forKey: ExtensionConstants.activeAlarmDefaultsKey) else {
            return nil
        }
        return alarm
    }
    
    // Perform any setup necessary in order to update the view.
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        
        guard let alarm = fetchActiveAlarm() else {
            extensionContext?.widgetLargestAvailableDisplayMode = .compact
            completionHandler(.noData)
            return
        }
        mapController.configure(with: alarm)
        extensionContext?.widgetLargestAvailableDisplayMode = alarm.note.isEmpty ? .compact : .expanded
        completionHandler(.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            mapController.showNote(false, animated: true)
            preferredContentSize = maxSize
        } else {
            preferredContentSize.height = mapController.contentHeight
        }
    }
    
}

extension TodayViewController: ExtensionViewControllerDelegate {
    func extensionController(_ controller: ExtensionViewController, didUpdateHeight newHeight: CGFloat) {
        preferredContentSize.height = newHeight
    }
}
