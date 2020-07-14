//
//  LaunchController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 08/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import BoldButton

final class LaunchController: UIViewController, Drawerable {
    var drawerContentViewController: UIViewController? {
        didSet {
            updateDrawerContent(animated: true)
        }
    }
    
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
            if location && notifications {
                self.openApp()
            } else {
                self.showPermissionsDrawer(shouldAskForLocation: !location, shouldAskForNotifications: !notifications)
            }
        }
    }
    
    private func openApp() {
        let model = BrowseViewModel(manager: AlarmsManager())
        let vc = BrowseViewController(model: model)
        navigationController?.setViewControllers([vc], animated: true)
    }
    
    private func checkPermissions(completion: @escaping (Bool, Bool) -> Void) {
        let group = DispatchGroup()
        
        var location: Bool!
        group.enter()
        PermissionsManager.shared.getLocationPermissionStatus { authorized in
            location = authorized
            group.leave()
        }
        
        var notifications: Bool!
        group.enter()
        PermissionsManager.shared.getNotificationsPermissionStatus { authorized in
            notifications = authorized
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
        
        label2.alpha = shouldAskForLocation ? 1 : 0.4
        label3.alpha = shouldAskForNotifications ? 1 : 0.4
    }
}

extension LaunchController {
    func setupView() {
        view.backgroundColor = .background
        let stack = UIStackView(arrangedSubviews: [label1, label2, label3, label4])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 2
        
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.leading.greaterThanOrEqualToSuperview().offset(24)
        }
    }
}

extension LaunchController: PermissionsControllerDelegate {
    func permissionsChanged() {
        checkPermissions { location, notifications in
            guard location && notifications else {
                self.showPermissionsDrawer(shouldAskForLocation: !location, shouldAskForNotifications: !notifications)
                return
            }
            self.openApp()
        }
    }
}

protocol PermissionsControllerDelegate: class {
    func permissionsChanged()
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
        let s = UIStackView()
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
        buttonsStack.addArrangedSubview(locationButton)
        locationButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        buttonsStack.addArrangedSubview(notificationsButton)
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
