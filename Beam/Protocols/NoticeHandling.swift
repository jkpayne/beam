//
//  NoticeHandling.swift
//  beam
//
//  Created by Rens Verhoeven on 21-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Foundation

protocol NoticeHandling {
    
    func handleError(_ error: NSError)
    func presentErrorMessage(_ message: String)
    func presentInformationMessage(_ message: String)
    func presentSuccessMessage(_ message: String)
func presentModeratorSuccessMessage(_ message: String)
}

extension NoticeHandling where Self: UIViewController {
    
    func handleError(_ error: NSError) {
        let message = error.localizedDescription
        self.presentErrorMessage(message)
    }
    
    func presentErrorMessage(_ message: String) {
        self.presentNoticeNotificationViewWithMessage(message, type: .error)
        if #available(iOS 10, *) {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(.error)
        }
    }
    
    func presentInformationMessage(_ message: String) {
        self.presentNoticeNotificationViewWithMessage(message, type: .information)
        if #available(iOS 10, *) {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(.warning)
        }
    }
    
    func presentSuccessMessage(_ message: String) {
        self.presentNoticeNotificationViewWithMessage(message, type: .success)
        if #available(iOS 10, *) {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(.success)
        }
    }
    func presentModeratorSuccessMessage(_ message: String) {
        self.presentNoticeNotificationViewWithMessage(message, type: .moderatorSuccess)
        if #available(iOS 10, *) {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(.success)
        }
    }

    fileprivate func presentNoticeNotificationViewWithMessage(_ message: String, type: NoticeNotificationViewType) {
        let noticeView = NoticeNotificationView(message: message, type: type)
        self.navigationController?.presentNoticeNotificationView(noticeView)
    }
    
}
