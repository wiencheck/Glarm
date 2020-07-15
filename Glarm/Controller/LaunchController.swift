//
//  LaunchController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 08/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import CoreLocation
import BoldButton

final class LaunchController: UIViewController, Drawerable {
    var drawerContentViewController: UIViewController? {
        didSet {
            updateDrawerContent(animated: true)
        }
    }
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [label1, label2, label3, label4])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 2
        stack.isHidden = true
        return stack
    }()
    
    /// Disclaimer first.
    private lazy var label1: UILabel = {
        let l = UILabel()
        l.text = LocalizedStringKey.disclaimerFirst.localized
        l.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        l.textAlignment = .left
        l.numberOfLines = 0
        l.textColor = .secondaryLabel()
        return l
    }()
    
    /// Location.
    private lazy var label2: UILabel = {
        let l = UILabel()
        l.text = LocalizedStringKey.locationDisclaimer.localized
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.textAlignment = .left
        l.numberOfLines = 0
        l.textColor = .secondaryLabel()
        return l
    }()
    
    /// Notifications.
    private lazy var label3: UILabel = {
        let l = UILabel()
        l.text = LocalizedStringKey.notificationDisclaimer.localized
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.textAlignment = .left
        l.numberOfLines = 0
        l.textColor = .secondaryLabel()
        return l
    }()
    
    /// Disclaimer second.
    private lazy var label4: UILabel = {
        let l = UILabel()
        l.text = LocalizedStringKey.disclaimerSecond.localized
        l.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        l.textAlignment = .left
        l.numberOfLines = 0
        l.textColor = .secondaryLabel()
        return l
    }()
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        navigationItem.title = LocalizedStringKey.launchTitle.localized
        
        checkPermissions { location, notifications in
            if location == .authorized && notifications == .authorized {
                self.openApp()
            } else {
                self.showPermissionsDrawer(shouldAskForLocation: location != .authorized, shouldAskForNotifications: notifications != .authorized)
            }
        }
    }
    
    private func openApp() {
        LocationManager.shared.start()
        let model = BrowseViewModel(manager: AlarmsManager())
        let vc = BrowseViewController(model: model)
        navigationController?.setViewControllers([vc], animated: true)
    }
    
    /// Completion: Location, Notifications
    private func checkPermissions(completion: @escaping (AuthorizationStatus, AuthorizationStatus) -> Void) {
        let group = DispatchGroup()
        
        var location: AuthorizationStatus!
        group.enter()
        PermissionsManager.shared.getLocationPermissionStatus { status in
            location = status
            group.leave()
        }
        
        var notifications: AuthorizationStatus!
        group.enter()
        PermissionsManager.shared.getNotificationsPermissionStatus { status in
            notifications = status
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(location, notifications)
        }
    }
    
    private func showPermissionsDrawer(shouldAskForLocation: Bool, shouldAskForNotifications: Bool) {
        let vc = PermissionsController(shouldAskForLocation: shouldAskForLocation, shouldAskForNotifications: shouldAskForNotifications)
        vc.delegate = self
        drawerContentViewController = vc
        
        stack.isHidden = false
        label2.alpha = shouldAskForLocation ? 1 : 0.4
        label3.alpha = shouldAskForNotifications ? 1 : 0.4
    }
}

extension LaunchController {
    func setupView() {
        view.backgroundColor = .background
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.leading.greaterThanOrEqualToSuperview().offset(24)
        }
    }
}

extension LaunchController: PermissionsControllerDelegate {
    private var locationPermissionRestrictedAlert: UIAlertController {
        let actions: [UIAlertAction] = [
            UIAlertAction(localizedTitle: .openSettings, style: .default, handler: { _ in
                UIApplication.shared.openSettings()
            }),
            .cancel(text: LocalizedStringKey.openApp.localized, action: {
                self.openApp()
            })
        ]
        let model = AlertViewModel(localizedTitle: .locationPermissionDeniedTitle, message: .locationPermissionDeniedMessage, actions: actions, style: .alert)
        return AWAlertController(model: model)
    }
    
    private var notificationsPermissionRestrictedAlert: UIAlertController {
        let actions: [UIAlertAction] = [
            UIAlertAction(localizedTitle: .openSettings, style: .default, handler: { _ in
                UIApplication.shared.openSettings()
            }),
            .cancel(text: LocalizedStringKey.openApp.localized, action: {
                self.openApp()
            })
        ]
        let model = AlertViewModel(localizedTitle: .notificationPermissionDeniedTitle, message: .notificationPermissionDeniedMessage, actions: actions, style: .alert)
        return AWAlertController(model: model)
    }
    
    func permissionsChanged() {
        checkPermissions { location, notifications in
            if location == .authorized && notifications == .authorized {
                self.openApp()
            } else if location == .resticted {
                self.present(self.locationPermissionRestrictedAlert, animated: true, completion: nil)
            } else if notifications == .resticted {
                self.present(self.notificationsPermissionRestrictedAlert, animated: true, completion: nil)
            } else {
                self.showPermissionsDrawer(shouldAskForLocation: location != .authorized, shouldAskForNotifications: notifications != .authorized)
            }
        }
    }
    
    func continueButtonPressed() {
        openApp()
    }
}

protocol PermissionsControllerDelegate: class {
    func permissionsChanged()
    func continueButtonPressed()
}

fileprivate class PermissionsController: UIViewController {
    
    private let shouldAskForLocation: Bool
    private let shouldAskForNotifications: Bool
    
    weak var delegate: PermissionsControllerDelegate?
    
    init(shouldAskForLocation: Bool, shouldAskForNotifications: Bool) {
        self.shouldAskForLocation = shouldAskForLocation
        self.shouldAskForNotifications = shouldAskForNotifications
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var locationButton: BoldButton = {
        let b = BoldButton()
        b.isEnabled = shouldAskForLocation
        b.text = LocalizedStringKey.permissionLocation.localized
        b.pressHandler = { _ in
            PermissionsManager.shared.requestLocationPermission { _ in
                self.delegate?.permissionsChanged()
            }
        }
        return b
    }()
    
    private lazy var notificationsButton: BoldButton = {
        let b = BoldButton()
        b.isEnabled = shouldAskForNotifications
        b.text = LocalizedStringKey.permissionNotifications.localized
        b.pressHandler = { _ in
            PermissionsManager.shared.requestNotificationsPermission { _ in
                self.delegate?.permissionsChanged()
            }
        }
        return b
    }()
    
    private lazy var buttonsStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [locationButton, notificationsButton])
        s.axis = .vertical
        s.distribution = .fillEqually
        s.spacing = 12
        return s
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
}

extension PermissionsController {
    internal func setupView() {
        locationButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        notificationsButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        view.addSubview(buttonsStack)
        buttonsStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalToSuperview().multipliedBy(0.6)
        }
    }
}
