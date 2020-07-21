//
//  RootController.swift
//  WakeMeApp
//
//  Created by Adam Wienconek on 10/07/2020.
//  Copyright © 2020 Adam Wienconek. All rights reserved.
//

import UIKit
import SnapKit

class RootController: UIViewController {
    private lazy var navigation: UINavigationController = {
        let model = BrowseViewModel(manager: AlarmsManager())
        let vc = BrowseViewController(model: model)
        return RootNavigationController(rootViewController: vc)
    }()
    
    fileprivate lazy var drawer = UIView()
    fileprivate lazy var contentContainer = UIView()
    private var drawerContentController: UIViewController?
    
    init() {
        super.init(nibName: nil, bundle: nil)
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
        drawer.backgroundColor = .clear
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
            make.edges.equalTo(drawer.safeAreaLayoutGuide).priority(.high)
            make.bottom.equalTo(drawer.safeAreaLayoutGuide).priority(.required)
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
    
    var shouldAdjustDrawerContentToKeyboard: Bool {
        return false
    }
    
    func updateDrawerContent(animated: Bool) {
        guard let root = UIApplication.shared.keyWindow()?.rootViewController as? RootController else {
            return
        }
        root.setDrawerContentViewController(drawerContentViewController, animated: animated)
    }
}
