//
//  SubredditsViewController.swift
//  beam
//
//  Created by Robin Speijer on 01-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

final class HomeViewController: BeamViewController, UIToolbarDelegate {
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var topButtonBarConstraint: NSLayoutConstraint!
    
    var touchForwardingView: TouchesForwardingView?
    
    var buttonBarItem: UIBarButtonItem {
        return toolbar.items![1]
    }
    
    @IBOutlet weak var buttonBar: ButtonBar!
    
    lazy private var subredditsViewController: SubredditsViewController = {
        return SubredditsViewController(style: .plain)
    }()
    
    lazy private var multiredditsViewController: MultiredditsViewController = {
        return MultiredditsViewController(style: .grouped)
    }()

    lazy private var moderatorSubredditsViewController: ModeratorSubredditsViewController = {
        return ModeratorSubredditsViewController(style: .plain)
    }()
    
    var currentViewController: UIViewController! {
        didSet {
            if oldValue != currentViewController {
                
                self.touchForwardingView?.receivingView = self.currentViewController.view
                
                self.navigationController?.navigationBar.setItems([currentViewController.navigationItem], animated: false)
                self.subredditsViewController.view.isHidden = currentViewController != self.subredditsViewController
                self.multiredditsViewController.view.isHidden = currentViewController != self.multiredditsViewController
                self.moderatorSubredditsViewController.view.isHidden = currentViewController != self.moderatorSubredditsViewController
                
                if currentViewController == self.subredditsViewController {
                    self.buttonBar.selectedItemIndex = 0
                } else if currentViewController == self.multiredditsViewController {
                    self.buttonBar.selectedItemIndex = 1
                } else {
                    self.buttonBar.selectedItemIndex = 2
                }
            }
        }
    }
    
    // MARK: - UIViewController
    
    private func setupView() {
        self.view.insertSubview(self.multiredditsViewController.view, belowSubview: self.toolbar)
        self.addChildViewController(self.multiredditsViewController)
        self.multiredditsViewController.didMove(toParentViewController: self)
        
        self.addContainerViewConstraints(viewController: self.multiredditsViewController, containerView: self.view)
        
        self.view.insertSubview(self.subredditsViewController.view, belowSubview: self.toolbar)
        self.addChildViewController(self.subredditsViewController)
        self.subredditsViewController.didMove(toParentViewController: self)
        
        self.addContainerViewConstraints(viewController: self.subredditsViewController, containerView: self.view)
        
        if self.touchForwardingView == nil {
            self.touchForwardingView = self.multiredditsViewController.tableView.expandScrollArea()
        }
        self.view.insertSubview(self.moderatorSubredditsViewController.view, belowSubview: self.toolbar)
        self.addChildViewController(self.moderatorSubredditsViewController)
        self.moderatorSubredditsViewController.didMove(toParentViewController: self)

        self.addContainerViewConstraints(viewController: self.moderatorSubredditsViewController, containerView: self.view)

        self.view.insertSubview(self.subredditsViewController.view, belowSubview: self.toolbar)
        self.addChildViewController(self.subredditsViewController)
        self.subredditsViewController.didMove(toParentViewController: self)

        self.addContainerViewConstraints(viewController: self.subredditsViewController, containerView: self.view)

        if self.touchForwardingView == nil {
            self.touchForwardingView = self.moderatorSubredditsViewController.tableView.expandScrollArea()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        
        self.buttonBar.items = [ButtonBarButton(title: AWKLocalizedString("subreddits-title")), ButtonBarButton(title: AWKLocalizedString("multireddits-title")), ButtonBarButton(title: "Moderated Subreddits")]
        self.buttonBar.addTarget(self, action: #selector(HomeViewController.buttonBarChanged(_:)), for: UIControlEvents.valueChanged)
        self.buttonBar.selectedItemIndex = UserSettings[.subscriptionsListType] == "multireddits" ? 1: 0
        
        self.configureContentInsets()
        
    }
    
    fileprivate func addContainerViewConstraints(viewController: UIViewController, containerView: UIView) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            viewController.view.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor),
            containerView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            containerView.rightAnchor.constraint(greaterThanOrEqualTo: viewController.view.rightAnchor),
            
            //Add horizontal constraints to make the view center with a max width
            viewController.view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            viewController.view.widthAnchor.constraint(lessThanOrEqualToConstant: UIView.MaximumViewportWidth)
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        //Limit the actual width, but give it a lower priority (750) so that it can be smaller if it needs to be (on iPhone for example)
        let widthConstraint = NSLayoutConstraint(item: viewController.view, attribute: .width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: UIView.MaximumViewportWidth)
        widthConstraint.priority = UILayoutPriority.defaultHigh
        viewController.view.addConstraint(widthConstraint)
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[viewController]|", options: [], metrics: nil, views: ["viewController": viewController.view]))
        
        //Disable the scrollbar on iPad, it looks weird
        if let tableView = viewController.view as? UITableView, UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            tableView.showsVerticalScrollIndicator = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        switch self.buttonBar.selectedItemIndex {
        case 1:
           self.currentViewController = self.multiredditsViewController
        case 2:
           self.currentViewController = self.moderatorSubredditsViewController
        default:
           self.currentViewController = self.subredditsViewController
        }
//        self.currentViewController = self.buttonBar.selectedItemIndex == 1 ? self.multiredditsViewController: self.subredditsViewController
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.buttonBarItem.width = self.toolbar.bounds.width
        configureContentInsets()
    }
    
    func configureContentInsets() {
        let contentInsets = UIEdgeInsets(top: self.toolbar.bounds.height, left: 0, bottom: 0, right: 0)
        
        self.subredditsViewController.tableView.contentInset = contentInsets
        self.subredditsViewController.tableView.scrollIndicatorInsets = contentInsets
        if self.subredditsViewController.tableView.contentOffset.y <= 0 {
            self.subredditsViewController.tableView.contentOffset = CGPoint(x: 0, y: -1 * contentInsets.top)
        }

        self.multiredditsViewController.tableView.contentInset = contentInsets
        self.multiredditsViewController.tableView.scrollIndicatorInsets = contentInsets
        if self.multiredditsViewController.tableView.contentOffset.y <= 0 {
            self.multiredditsViewController.tableView.contentOffset = CGPoint(x: 0, y: -1 * contentInsets.top)
        }

        self.moderatorSubredditsViewController.tableView.contentInset = contentInsets
        self.moderatorSubredditsViewController.tableView.scrollIndicatorInsets = contentInsets
        if self.moderatorSubredditsViewController.tableView.contentOffset.y <= 0 {
            self.moderatorSubredditsViewController.tableView.contentOffset = CGPoint(x: 0, y: -1 * contentInsets.top)
        }
    }
    
    // MARK: - UIBarPositioningDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.top
    }
    
    // MARK: - Actions
    
    @objc fileprivate func buttonBarChanged(_ sender: ButtonBar) {
        switch sender.selectedItemIndex {
        case 0:
             self.currentViewController = self.subredditsViewController
        case 1:
             self.currentViewController = self.multiredditsViewController
        case 2:
            self.currentViewController = self.moderatorSubredditsViewController
        default:
            self.currentViewController = self.subredditsViewController
        }
//        if sender.selectedItemIndex == 1 {
//            self.currentViewController = self.multiredditsViewController
//        } else {
//            self.currentViewController = self.subredditsViewController
//        }

    }

}

extension HomeViewController: NavigationBarNotificationDisplayingDelegate {

    func topViewForDisplayOfnotificationView<NotificationView: UIView>(_ view: NotificationView) -> UIView? where NotificationView: NavigationBarNotification {
        return self.buttonBar.superview
    }
    
}
