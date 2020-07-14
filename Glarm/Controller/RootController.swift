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
    private lazy var navigation = RootNavigationController(rootViewController: LaunchController())
    
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
            make.edges.equalTo(drawer.safeAreaLayoutGuide)
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

fileprivate class RootNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
}

extension RootNavigationController: UINavigationControllerDelegate {
        
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if let root = parent as? RootController {
            root.setDrawerContentViewController((viewController as? Drawerable)?.drawerContentViewController, animated: animated)
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let root = parent as? RootController {
            root.setDrawerContentViewController((viewController as? Drawerable)?.drawerContentViewController, animated: animated)
            viewController.additionalSafeAreaInsets.bottom = root.contentContainer.frame.height
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
}

extension Drawerable {
    var drawer: UIView? {
        guard let root = UIApplication.shared.keyWindow()?.rootViewController as? RootController else {
            return nil
        }
        return root.drawer
    }
    
    func updateDrawerContent(animated: Bool) {
        guard let root = UIApplication.shared.keyWindow()?.rootViewController as? RootController else {
            return
        }
        root.setDrawerContentViewController(drawerContentViewController, animated: animated)
    }
}
