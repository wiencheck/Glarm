//
//  RootController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 10/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import SnapKit
import CoreLocation
import AWAlertController

class RootController: UIViewController {
    private let manager: AlarmsManagerProtocol
    private let locationManager: CLLocationManager
    
    private(set) lazy var navigation: UINavigationController = {
        let model = BrowseViewModel(manager: manager)
        let vc = BrowseViewController(model: model)
        return RootNavigationController(rootViewController: vc)
    }()
    
    private lazy var blurOverlayView = UIVisualEffectView(effect: nil)
    
    fileprivate lazy var drawer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()
    fileprivate lazy var contentContainer = UIView()
    private var drawerContentController: UIViewController?
    
    init(manager: AlarmsManagerProtocol) {
        self.manager = manager
        self.locationManager = CLLocationManager()
        super.init(nibName: nil, bundle: nil)
        locationManager.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigation.navigationBar.prefersLargeTitles = true
        add(child: navigation, duration: 0)
        setupView()
        startObservingKeyboard()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        endObservingKeyboard()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigation.topViewController?.additionalSafeAreaInsets.bottom = drawer.frame.height - view.safeAreaInsets.bottom
    }
    
    private func setupView() {
        view.addSubview(drawer)
        drawer.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
        }
        
        let blur = UIBlurEffect(style: .default)
        let visualView = UIVisualEffectView(effect: blur)
        drawer.addSubview(visualView)
        visualView.pinToSuperView()
        
        contentContainer.backgroundColor = .clear
        drawer.addSubview(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.edges.equalTo(drawer.safeAreaLayoutGuide)
            make.bottom.equalTo(drawer.safeAreaLayoutGuide).priority(.high)
        }
    }
    
    fileprivate func setDrawerContentViewController(_ controller: UIViewController?, animated: Bool) {
        if controller == drawerContentController {
            return
        }
        defer {
            drawerContentController = controller
        }
        guard let new = controller else {
            drawerContentController?.removeFromParent(duration: 0.15)
            return
        }
        if let old = drawerContentController {
            old.removeFromParent(duration: 0.15) { _ in
                self.add(child: new, superview: self.contentContainer, duration: 0.15)
            }
        } else {
            add(child: new, superview: contentContainer, duration: 0.15)
        }
    }
}

extension RootController {
    func startObservingKeyboard() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self,
                let info = notification.userInfo,
                let value = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
                let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
                return
            }
            let converted = self.view.convert(value.cgRectValue, from: nil)
            let corrected = CGRect(origin: converted.origin, size: CGSize(width: converted.width, height: converted.height - self.view.safeAreaInsets.bottom))
            self.keyboardWillAppear(in: corrected, duration: duration.doubleValue)
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self,
                let info = notification.userInfo,
                let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
                return
            }
            self.keyboardWillDisappear(duration: duration.doubleValue)
        }
    }
    
    func endObservingKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func keyboardWillAppear(in frame: CGRect, duration: TimeInterval) {
        guard let drawerable = navigation.topViewController as? Drawerable, drawerable.shouldAdjustDrawerContentToKeyboard else {
            return
        }
        UIView.animate(withDuration: duration) {
            self.contentContainer.snp.updateConstraints { make in
                make.bottom.equalTo(self.drawer.safeAreaLayoutGuide).offset(-frame.height)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    internal func keyboardWillDisappear(duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            self.contentContainer.snp.updateConstraints { make in
                make.bottom.equalTo(self.drawer.safeAreaLayoutGuide)
            }
            self.view.layoutIfNeeded()
        }
    }
}

extension RootController: CLLocationManagerDelegate {
    private func displayLocationBlockedMessage(visible: Bool) {
        if blurOverlayView.superview == nil {
            view.addSubview(blurOverlayView)
            blurOverlayView.pinToSuperView()
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.blurOverlayView.effect = visible ? UIBlurEffect(style: .systemMaterial) : nil
        }, completion: { _ in
            if visible {
                return
            }
            self.blurOverlayView.removeFromSuperview()
        })
        
        guard visible else {
            return
        }
        let model = AlertViewModel(title: "Location services are disabled for Glarm", message: "Please enable location services for Glarm to use the app.", actions: [
                                    UIAlertAction(title: .localized(.permission_openSettingsAction), style: .default, handler: { _ in
                                        UIApplication.shared.openSettings()
                                    })
        ], style: .alert)
        AWAlertController(model: model).show()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined, .authorizedAlways, .authorizedWhenInUse:
            displayLocationBlockedMessage(visible: false)
        default:
            displayLocationBlockedMessage(visible: true)
        }
    }
}

fileprivate class RootNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
}

extension RootNavigationController: UINavigationControllerDelegate {
        
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard let root = parent as? RootController,
        let drawerable = viewController as? Drawerable else {
            return
        }
        root.setDrawerContentViewController(drawerable.drawerContentViewController, animated: animated)
        root.drawer.isUserInteractionEnabled = true
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let root = parent as? RootController,
            let drawerable = viewController as? Drawerable {
            root.setDrawerContentViewController(drawerable.drawerContentViewController, animated: animated)
            root.drawer.isUserInteractionEnabled = false
        }
        
        transitionCoordinator?.notifyWhenInteractionChanges { context in
            guard context.isCancelled, let fromViewController = context.viewController(forKey: UITransitionContextViewControllerKey.from) else { return }
            self.navigationController(self, willShow: fromViewController, animated: animated)
            let animationCompletion: TimeInterval = context.transitionDuration * Double(context.percentComplete)
            DispatchQueue.main.asyncAfter(deadline: .now() + animationCompletion) {
                self.navigationController(self, didShow: fromViewController, animated: animated)
            }
        }
    }
}

protocol Drawerable: UIViewController {
    var drawerContentViewController: UIViewController? { get }
    var shouldAdjustDrawerContentToKeyboard: Bool { get }
}

extension Drawerable {
    var drawer: UIView? {
        guard let root = UIApplication.shared.keyWindow()?.rootViewController as? RootController else {
            return nil
        }
        return root.drawer
    }
    
    var shouldAdjustDrawerContentToKeyboard: Bool { true }
    
    func updateDrawerContent(animated: Bool) {
        guard let root = UIApplication.shared.keyWindow()?.rootViewController as? RootController else {
            return
        }
        root.setDrawerContentViewController(drawerContentViewController, animated: animated)
    }
}
