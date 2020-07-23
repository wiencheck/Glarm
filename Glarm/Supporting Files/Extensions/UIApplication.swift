//
//  UIApplication.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 08/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import MessageUI

extension UIApplication {
    func keyWindow() -> UIWindow? {
        return windows.first { $0.isKeyWindow }
    }
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var lastInstalledAppVersion: String? {
        defer {
            UserDefaults.standard.set(appVersion, forKey: "lastInstalledAppVersion")
        }
        return UserDefaults.standard.string(forKey: "lastInstalledAppVersion")
    }
    
    /// Number indicating how many times the app was launched.
    var launchCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: "appLaunchCount")
        } set {
            UserDefaults.standard.set(newValue, forKey: "appLaunchCount")
        }
    }
    
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsURL)
            else {
                return
        }
        UIApplication.shared.open(settingsURL)
    }
    
    func openReviewPage() {
        guard let url = URL(string: "https://apps.apple.com/app/id1523237367" + "?action=write-review"),
        canOpenURL(url) else {
            return
        }
        open(url, options: [:], completionHandler: nil)
    }
    
    func openMail() {
        let email = "adwienc@icloud.com"
        let subject = "Glarm feedback"
        let bodyText = "\n\n_________________________\n\nIf you have any questions or want to provide feedback, this is the place to do it! I will do my best to respond to every message. If you have any issues please provide steps to re-create them and if the issue is related to interface, please provide a screenshot\n\n_________________________\n\nGlarm \(appVersion)\n\n\(UIDevice.modelName) - \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        if MFMailComposeViewController.canSendMail() {
            let mailComposerVC = MFMailComposeViewController()
            mailComposerVC.mailComposeDelegate = self
            mailComposerVC.setToRecipients([email])
            mailComposerVC.setSubject(subject)
            mailComposerVC.setMessageBody(bodyText, isHTML: false)
            keyWindow()?.rootViewController?.present(mailComposerVC, animated: true, completion: nil)
        } else {
            let coded = "mailto:\(email)?subject=\(subject)&body=\(bodyText)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            if let emailURL = URL(string: coded!)
            {
                if UIApplication.shared.canOpenURL(emailURL)
                {
                    UIApplication.shared.open(emailURL, options: [:], completionHandler: { (result) in
                        if !result {
                            self.keyWindow()?.rootViewController?.displayErrorMessage(title: "Failed to send mail", error: nil)
                        }
                    })
                }
            }
        }
    }
}

extension UIApplication: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        if let error = error {
            keyWindow()?.rootViewController?.displayErrorMessage(title: "Failed to send mail", error: error)
        } else {
            switch result {
            case .failed:
                keyWindow()?.rootViewController?.displayErrorMessage(title: "Failed to send mail", error: nil)
            default:
                return
            }
        }
    }
}
