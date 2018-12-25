//
//  PostToolbarView.swift
//  beam
//
//  Created by Rens Verhoeven on 16-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import AWKGallery
import CherryKit
import Trekker

enum moderatorAction {
    case distinguish
    case undistinguish
    case sticky
    case unsticky
    case approve
    case reapprove
    case remove
    case markSpam
    case markNsfw
    case markSpoiler
    case unmarkSpam
    case unmarkNsfw
    case unmarkSpoiler
//    case setPostFlair
    case announce
    case unannounce
    case lock
    case unlock
    case ignoreReports
    case unignoreReports
//    case banUser
//    case viewReports
}
protocol PostToolbarViewDelegate: class {
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapCommentsOnPost post: Post)
    func postToolbarView(_ toolbarView: PostToolbarView, didTapPointsOnPost post: Post)
    func postToolbarView(_ toolbarView: PostToolbarView, didTapMoreOnPost post: Post)
    func postToolbarView(_ toolbarView: PostToolbarView, didTapUpvoteOnPost post: Post)
    func postToolbarView(_ toolbarView: PostToolbarView, didTapDownvoteOnPost post: Post)
    
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapModeratorOnPost post: Post)
    func visibleSubredditForToolbarView(_ toolbarView: PostToolbarView) -> Subreddit?
    
}
fileprivate enum moderateType {
    case post
    case comment
    case subreddit
}
extension PostToolbarViewDelegate where Self: UIViewController {
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapUpvoteOnPost post: Post) {
        if post.voteStatus?.intValue != VoteStatus.up.rawValue {
            self.vote(.up, forPost: post, toolbarView: toolbarView)
        } else {
            self.vote(.neutral, forPost: post, toolbarView: toolbarView)
        }
    }
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapDownvoteOnPost post: Post) {
        if post.voteStatus?.intValue != VoteStatus.down.rawValue {
            self.vote(.down, forPost: post, toolbarView: toolbarView)
        } else {
            self.vote(.neutral, forPost: post, toolbarView: toolbarView)
        }
    }
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapCommentsOnPost post: Post) {
        guard !(self is PostDetailEmbeddedViewController) || self.shownInGallery() else {
            return
        }
        Trekker.default.track(event: TrekkerEvent(event: "Open comments"))
        
        if self.shownInGallery() || self.navigationController == nil {
            let storyboard = UIStoryboard(name: "Comments", bundle: nil)
            let commentsNavigationController = storyboard.instantiateInitialViewController() as! BeamNavigationController
            let commentsViewController = commentsNavigationController.topViewController as! CommentsViewController
            
            let commentsQuery = CommentCollectionQuery()
            commentsQuery.post = post
            commentsViewController.query = commentsQuery
            commentsNavigationController.useScalingTransition = false
            
            self.modallyPresentToolBarActionViewController(commentsNavigationController, toolbarView: toolbarView)
            if UserSettings[.postMarking] {
                post.markVisited()
            }
        } else {
            let detailViewController = PostDetailViewController(post: post, contextSubreddit: toolbarView.delegate?.visibleSubredditForToolbarView(toolbarView))
            detailViewController.scrollToCommentsOnLoad = true
            self.navigationController?.show(detailViewController, sender: nil)
            if UserSettings[.postMarking] {
                post.markVisited()
            }
        }
    }
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapPointsOnPost post: Post) {
        postToolbarView(toolbarView, didTapCommentsOnPost: post)
    }
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapMoreOnPost post: Post) {
        let activityViewController = ShareActivityViewController(object: post)
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> Void in
            if completed {
                Trekker.default.track(event: TrekkerEvent(event: "Share post", properties: [
                    "Activity type": activityType?.rawValue ?? "Unknown",
                    "Used reddit link": NSNumber(value: true)
                    ]))
            }
        }
        
        self.modallyPresentToolBarActionViewController(activityViewController, toolbarView: toolbarView, sender: toolbarView.moreButton)
    }
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapModeratorOnPost post: Post) {
        let viewController = moderate(post: post)
        self.present(viewController, animated: true, completion: nil)
    }
    
    fileprivate func vote(_ status: VoteStatus, forPost post: Post, toolbarView: PostToolbarView) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            let alertController = UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.VotePost)
            self.modallyPresentToolBarActionViewController(alertController, toolbarView: toolbarView)
            return
        }
        
        
        
        if UserSettings[.postMarking] {
            post.markVisited()
        }
        
        let oldVoteStatus = VoteStatus(rawValue: post.voteStatus?.intValue ?? 0) ?? VoteStatus.neutral
        post.updateScore(status, oldVoteStatus: oldVoteStatus)
        post.voteStatus = NSNumber(value: status.rawValue)
        status.soundType.play()
        
        if #available(iOS 10, *), [VoteStatus.up, VoteStatus.down].contains(status) {
            let feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.selectionChanged()
        }
        
        let operation = post.voteOperation(status, authenticationController: AppDelegate.shared.authenticationController)
        DataController.shared.executeOperations([operation]) { [weak self] (error: Error?) -> Void in
            post.managedObjectContext?.perform {
                if let error = error {
                    print("Error \(error)")
                    post.updateScore(oldVoteStatus, oldVoteStatus: status)
                    post.voteStatus = NSNumber(value: oldVoteStatus.rawValue)
                    self?.presentVoteError(error)
                }
            }
        }
    }
    
    fileprivate func shownInGallery() -> Bool {
        if self.presentedViewController is AWKGalleryViewController {
            return true
        } else if AppDelegate.shared.galleryWindow?.rootViewController != nil {
            return true
        }
        return false
    }
    
    fileprivate func modallyPresentToolBarActionViewController(_ viewController: UIViewController, toolbarView: PostToolbarView, sender: UIControl? = nil) {
        if let activityViewController = viewController as? UIActivityViewController, self.traitCollection.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = toolbarView
            if let sender = sender {
                activityViewController.popoverPresentationController?.sourceRect = sender.frame
            }
            activityViewController.title = "Share"
        }
        if let gallery = self.presentedViewController as? AWKGalleryViewController {
            gallery.present(viewController, animated: true, completion: nil)
        } else if let galleryRootViewController = AppDelegate.shared.galleryWindow?.rootViewController, let topViewController = AppDelegate.topViewController(galleryRootViewController) {
            topViewController.present(viewController, animated: true, completion: nil)
        } else {
            self.present(viewController, animated: true, completion: nil)
        }
    }
    fileprivate func modallyPresentToolBarModeratorActionViewController(_ viewController: UIViewController, toolbarView: PostToolbarView, sender: UIControl? = nil) {
        //        if let viewController as? BeamAlertController {
        
        self.present(viewController, animated: true, completion: nil)
        //        }
    }
    func moderatorActionHandler(action: moderatorAction, post: Post) {
        switch action {
        case .distinguish:
            let operation = post.distinguish(true, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Distinguishing!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Distinguished!")
                        }
                        NotificationCenter.default.post(name: .PostDidChangeApprovedState, object: post)
                    }
                })
            })
        case .undistinguish:
            let operation = post.distinguish(false, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Unistinguishing!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Unistinguished!")
                        }
                        NotificationCenter.default.post(name: .PostDidChangeApprovedState, object: post)
                    }
                })
            })
        case .sticky:
            let operation = post.sticky(authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Stickying!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Stickied!")
                        }

                    }
                })
            })
        case .unsticky:
            let operation = post.unsticky(keepDistinguished: true ,authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Unstickying!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Unstickied!")
                        }

                    }
                })
            })
        case .approve:
            let operation = post.approve(authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Approving!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Approved!")
                        }

                    }
                })
            })
        case .reapprove:
            let operation = post.approve(authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Reapproving!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Reapproved!")
                        }

                    }
                })
            })
        case .remove:
            let operation = post.remove(authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Removing!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Removed!")
                        }

                    }
                })
            })
        case .markSpam:
            let operation = post.markSpam(authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Marking Spam!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Marked Spam!")
                        }

                    }
                })
            })
        case .markNsfw:
            let operation = post.markNsfw(true, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Marking NFSW!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Marked NFSW!")
                        }

                    }
                })
            })
        case .markSpoiler:
            let operation = post.markSpoiler(true, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Marking Spoiler!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Marked Spoiler!")
                        }

                    }
                })
            })
        case .unmarkSpam:
            let operation = post.approve(authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Unmarking Spam!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Unmarked Spam!")
                        }

                    }
                })
            })
        case .unmarkNsfw:
            let operation = post.markNsfw(false, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Unmarking NSFW!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Unmarked NSFW!")
                        }

                    }
                })
            })
        case .unmarkSpoiler:
            let operation = post.markNsfw(false, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Unmarking NSFW!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Unmarked NSFW!")
                        }

                    }
                })
            })
//        case .setPostFlair:

        case .announce:
            let operation = post.markSticky(true, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Stickying Announcement!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Stickied Announcement!")
                        }

                    }
                })
            })
        case .unannounce:
            let operation = post.markSticky(false, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Unstickying Announcement!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Unstickied Announcement!")
                        }

                    }
                })
            })
        case .lock:
            let operation = post.lock(true, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Locking Thread!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Locked Thread!")
                        }

                    }
                })
            })
        case .unlock:
            let operation = post.lock(false, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Unlocking Thread!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Unlocked Thread!")
                        }

                    }
                })
            })
        case .ignoreReports:
            let operation = post.ignoreReports(true, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Ignoring Reports!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Ignored Reports!")
                        }

                    }
                })
            })
        case .unignoreReports:
            let operation = post.ignoreReports(false, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentErrorMessage("Error Unignoring Reports!")
                        }
                    } else {
                        if let noticeHandler = self as? NoticeHandling {
                            noticeHandler.presentModeratorSuccessMessage("Unignored Reports!")
                        }

                    }
                })
            })
//        case .banUser:
//            let operation = post.ban(false, authenticationController: AppDelegate.shared.authenticationController)
//            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
//                DispatchQueue.main.async(execute: { () -> Void in
//                    if error != nil {
//                        if let noticeHandler = self as? NoticeHandling {
//                            noticeHandler.presentErrorMessage("Error Unignoring Reports!")
//                        }
//                    } else {
//                        if let noticeHandler = self as? NoticeHandling {
//                            noticeHandler.presentModeratorSuccessMessage("Unignored Reports!")
//                        }
//
//                    }
//                })
//            })
//        case .viewReports:

        }
    }

    fileprivate func getModerateActions(type: moderateType, post: Post) -> [UIAlertAction] {
        let distinguish = UIAlertAction(title: "Distinguish", style: .default, handler: {_ in self.moderatorActionHandler(action: .distinguish, post: post)})
        distinguish.setValue(UIImage(named: "distinguish"), forKey: "image")
        let undistinguish = UIAlertAction(title: "Undistinguish", style: .default, handler: {_ in self.moderatorActionHandler(action: .undistinguish, post: post)})
        undistinguish.setValue(UIImage(named: "distinguish"), forKey: "image")
        let sticky = UIAlertAction(title: "Sticky", style: .default, handler: {_ in self.moderatorActionHandler(action: .sticky, post: post)})
        sticky.setValue(UIImage(named: "sticky"), forKey: "image")
        let unsticky = UIAlertAction(title: "Unsticky", style: .default, handler: {_ in self.moderatorActionHandler(action: .unsticky, post: post)})
        unsticky.setValue(UIImage(named: "sticky"), forKey: "image")
        let approve = UIAlertAction(title: "Approve", style: .default, handler: {_ in  self.moderatorActionHandler(action: .approve, post: post)})
        approve.setValue(UIImage(named: "approve"), forKey: "image")
        let reapprove = UIAlertAction(title: "Reapprove", style: .default, handler: {_ in self.moderatorActionHandler(action: .reapprove, post: post)})
        reapprove.setValue(UIImage(named: "approve"), forKey: "image")
        let remove = UIAlertAction(title: "Remove", style: .default, handler: {_ in self.moderatorActionHandler(action: .remove, post: post)})
        remove.setValue(UIImage(named: "remove"), forKey: "image")
        let markSpam = UIAlertAction(title: "Mark Spam", style: .default, handler: {_ in self.moderatorActionHandler(action: .markSpam, post: post)})
        markSpam.setValue(UIImage(named: "spam"), forKey: "image")
        let markNsfw = UIAlertAction(title: "Mark NSFW", style: .default, handler: {_ in self.moderatorActionHandler(action: .markNsfw, post: post)})
        markNsfw.setValue(UIImage(named: "nsfw"), forKey: "image")
        let markSpoiler = UIAlertAction(title: "Mark Spoiler", style: .default, handler: {_ in self.moderatorActionHandler(action: .markSpoiler, post: post)})
        markSpoiler.setValue(UIImage(named: "spoiler"), forKey: "image")
        let unmarkSpam = UIAlertAction(title: "Unmark Spam", style: .default, handler: {_ in self.moderatorActionHandler(action: .unmarkSpam, post: post)})
        unmarkSpam.setValue(UIImage(named: "spam"), forKey: "image")
        let unmarkNsfw = UIAlertAction(title: "Unmark NSFW", style: .default, handler: {_ in self.moderatorActionHandler(action: .unmarkNsfw, post: post)})
        unmarkNsfw.setValue(UIImage(named: "nsfw"), forKey: "image")
        let unmarkSpoiler = UIAlertAction(title: "Unmark Spoiler", style: .default, handler: {_ in self.moderatorActionHandler(action: .unmarkSpoiler, post: post)})
        unmarkSpoiler.setValue(UIImage(named: "spoiler"), forKey: "image")
        let setPostFlair = UIAlertAction(title: "Set Post Flair", style: .default, handler: nil/*{_ in self.moderatorActionHandler(action: .setPostFlair, post: post)}*/)
        setPostFlair.setValue(UIImage(named: "flair"), forKey: "image")
        let announce = UIAlertAction(title: "Announce", style: .default, handler: {_ in self.moderatorActionHandler(action: .announce, post: post)})
        announce.setValue(UIImage(named: "announce"), forKey: "image")
        let unannounce = UIAlertAction(title: "Unannounce", style: .default, handler: {_ in self.moderatorActionHandler(action: .unannounce, post: post)})
        unannounce.setValue(UIImage(named: "announce"), forKey: "image")
        let lock = UIAlertAction(title: "Lock", style: .default, handler: {_ in self.moderatorActionHandler(action: .lock, post: post)})
        lock.setValue(UIImage(named: "lock"), forKey: "image")
        let unlock = UIAlertAction(title: "Unlock", style: .default, handler: {_ in self.moderatorActionHandler(action: .unlock, post: post)})
        unlock.setValue(UIImage(named: "unlock"), forKey: "image")
        let ignoreReports = UIAlertAction(title: "Ignore Reports", style: .default, handler: {_ in self.moderatorActionHandler(action: .ignoreReports, post: post)})
        ignoreReports.setValue(UIImage(named: "ignoreReports"), forKey: "image")
        let unignoreReports = UIAlertAction(title: "Unignore Reports", style: .default, handler: {_ in self.moderatorActionHandler(action: .unignoreReports, post: post)})
        unignoreReports.setValue(UIImage(named: "ignoreReports"), forKey: "image")
        let banUser = UIAlertAction(title: "Ban User", style: .default, handler: nil/*{_ in self.moderatorActionHandler(action: .banUser, post: post)}*/)
        banUser.setValue(UIImage(named: "ban"), forKey: "image")
        let viewReports = UIAlertAction(title: "View Reports", style: .default, handler: nil/*{_ in self.moderatorActionHandler(action: .viewReports, post: post)}*/)
        viewReports.setValue(UIImage(named: "report"), forKey: "image")

        var actions: [UIAlertAction] = []
        let reports = post.numReports
        
        var approved = false
        if post.approved == 1 {
            approved = true
        }
        
        var hasReports = false
        if reports as! Int >= 1 {
            hasReports = true
        }
        
        var removed = false
        if post.removed == 1 {
            removed = true
        }
        
        var distinguished = false
        if post.distinguished != nil {
            distinguished = true
        }
        
        var isOwner = false
        if  AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username == post.author {
            isOwner = true
        }
        
        var locked = false
        if post.locked == 1 {
            locked = true
        }
        
        var reapproveNeeded = false
        //        if post.reapproveNeeded == 1 {
        //            reapproveNeeded = true
        //        }
        
        var markedSpam = false
        if post.spam == 1 {
            markedSpam = true
        }
        
        var markedNsfw = false
        if post.isContentNSFW == 1 {
            markedNsfw = true
        }
        
        var markedSpoiler = false
        if post.isContentSpoiler == 1 {
            markedSpoiler = true
        }
        
        var stickied = false
        if post.stickied == 1 {
            stickied = true
        }
        
        var reportsIgnored = false
        if post.ignoreReports == 1 {
            reportsIgnored = true
        }
        
        
        
        if isOwner {
            if distinguished {
                actions.append(undistinguish)
            } else {
                actions.append(distinguish)
            }
        }
        if approved {
            actions.append(remove)
        } else if reapproveNeeded {
            actions.append(reapprove)
            actions.append(remove)
        } else {
            actions.append(approve)
        }
        if removed {
            actions.append(remove)
        }
        if markedSpam {
            actions.append(unmarkSpam)
        } else {
            actions.append(markSpam)
        }
        if markedNsfw {
            actions.append(unmarkNsfw)
        } else {
            actions.append(markNsfw)
        }
        if markedSpoiler {
            actions.append(unmarkSpoiler)
        } else {
            actions.append(markSpoiler)
        }
        actions.append(setPostFlair)
        if stickied {
            actions.append(unannounce)
        } else {
            actions.append(announce)
        }
        if locked {
            actions.append(unlock)
        } else {
            actions.append(lock)
        }
        if hasReports {
            actions.append(viewReports)
        }
        if reportsIgnored {
            actions.append(unignoreReports)
        } else {
            actions.append(ignoreReports)
        }
        if hasReports {
            actions.append(viewReports)
        }
        actions.append(banUser)
        
        return actions
    }
    
    func moderate(post: Post) -> BeamAlertController {
        var approvedByString = ""
        print(post)
        if post.approved == 1 {
            if let approvedBy = post.approvedBy {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short

                if let date = post.approvedAtUtc {
                    let postApprovedAt = dateFormatter.string(from: date as Date)
                    print(postApprovedAt)
                    approvedByString = "Approved by: \(approvedBy) at \(postApprovedAt)"
                } else {
                    print("There was an error decoding the string")
                    approvedByString = "Approved by: \(approvedBy)"
                }

            }
        }
        var removedByString = ""

        if post.removed == 1 {
            if let removedBy = post.bannedBy {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short

                if let date = post.bannedAtUtc {
                    let postRemovedAt = dateFormatter.string(from: date as Date)
                    print(postRemovedAt)
                    removedByString = "Removed by: \(removedBy) at \(postRemovedAt)"
                } else {
                    print("There was an error decoding the string")
                    removedByString = "Removed by: \(removedBy)"
                }

            }
        }

        let alert = BeamAlertController(title: approvedByString, message: nil, preferredStyle: .actionSheet)
        for action in getModerateActions(type: moderateType.post, post: post) {
            alert.addAction(action)
        }
        alert.addCancelAction()
        alert.view.tintColor = #colorLiteral(red: 0.3047083318, green: 0.6231384277, blue: 0.2308172882, alpha: 1)
        return alert
    }
    
    fileprivate func presentVoteError(_ error: Error?) {
        if let error = error as NSError? {
            if let noticeHandler = self as? NoticeHandling {
                if error.code == NSURLErrorNotConnectedToInternet && error.domain == NSURLErrorDomain {
                    noticeHandler.presentErrorMessage(AWKLocalizedString("error-vote-internet"))
                } else {
                    noticeHandler.presentErrorMessage(AWKLocalizedString("error-vote"))
                }
            }
        }
        
    }
    
    func  visibleSubredditForToolbarView(_ toolbarView: PostToolbarView) -> Subreddit? {
        return nil
    }
    
}

class PostToolbarView: BeamView {
    
    weak var delegate: PostToolbarViewDelegate?
    
    var popoverController: UIPopoverPresentationController?
    
    weak var post: Post? {
        didSet {
            UIView.performWithoutAnimation { () -> Void in
                self.updateContent()
            }
        }
    }
    
    override var isOpaque: Bool {
        didSet {
            if self.isOpaque != oldValue {
                self.displayModeDidChange()
            }
        }
    }
    
    var shouldShowSeperator = true {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    fileprivate let commentsButton: BeamPlainButton = {
        let button = BeamPlainButton(frame: CGRect())
        button.setImage(UIImage(named: "actionbar_comments"), for: UIControlState())
        button.setTitle("comments", for: UIControlState())
        return button
    }()
    
    fileprivate let pointsButton: BeamPlainButton = {
        let button = BeamPlainButton(frame: CGRect())
        button.setImage(UIImage(named: "actionbar_points"), for: UIControlState())
        button.setTitle("points", for: UIControlState())
        return button
    }()
    
    fileprivate let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "actionbar_more"), for: UIControlState())
        return button
    }()
    
    fileprivate let moderatorButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "moderator"), for: UIControlState())
        button.tintColor = #colorLiteral(red: 0.3047083318, green: 0.6231384277, blue: 0.2308172882, alpha: 1)
        return button
    }()
    fileprivate let reportsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "report"), for: UIControlState())
        button.setTitle("reports", for: UIControlState())
        
        button.tintColor = #colorLiteral(red: 1, green: 0.8392156863, blue: 0.03921568627, alpha: 1)
        return button
    }()
    
    fileprivate let upvoteButton: VoteButton = {
        let voteButton = VoteButton()
        voteButton.arrowDirection = .up
        return voteButton
    }()
    
    fileprivate let downvoteButton: VoteButton = {
        let voteButton = VoteButton()
        voteButton.arrowDirection = .down
        return voteButton
    }()
    
    fileprivate var tintedButtons = [UIButton]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    fileprivate func setupView() {
        
        self.isOpaque = true
        self.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 12)
        
        self.configureLabeledButton(self.commentsButton)
        self.configureLabeledButton(self.pointsButton)
        self.configureLabeledButton(self.reportsButton)

        self.commentsButton.addTarget(self, action: #selector(PostToolbarView.viewComments(_:)), for: .touchUpInside)
        self.pointsButton.addTarget(self, action: #selector(PostToolbarView.viewPoints(_:)), for: .touchUpInside)
        self.moreButton.addTarget(self, action: #selector(PostToolbarView.more(_:)), for: .touchUpInside)
        self.moderatorButton.addTarget(self, action: #selector(PostToolbarView.moderator(_:)), for: .touchUpInside)
        self.downvoteButton.addTarget(self, action: #selector(PostToolbarView.downvote(_:)), for: .touchUpInside)
        self.upvoteButton.addTarget(self, action: #selector(PostToolbarView.upvote(_:)), for: .touchUpInside)
        
        self.tintedButtons.append(self.commentsButton)
        self.addSubview(self.commentsButton)
        
        self.tintedButtons.append(self.pointsButton)
        self.addSubview(self.pointsButton)
        
        self.tintedButtons.append(self.moreButton)
        self.addSubview(self.moreButton)
        

        self.tintedButtons.append(self.moderatorButton)
        self.addSubview(self.moderatorButton)

        self.addSubview(self.reportsButton)

        
        
        self.addSubview(self.downvoteButton)
        
        self.addSubview(self.upvoteButton)
        
    }
    
    fileprivate func updateContent() {
        self.commentsButton.setTitle("\(self.post?.commentCount?.intValue ?? 0)", for: UIControlState.normal)
        self.pointsButton.setTitle(self.pointsTitle(), for: UIControlState.normal)
        self.reportsButton.setTitle("×\(self.post?.numReports?.intValue ?? 0)", for: UIControlState.normal)
        self.upvoteButton.voted = self.post?.voteStatus?.intValue == VoteStatus.up.rawValue
        self.downvoteButton.voted = self.post?.voteStatus?.intValue == VoteStatus.down.rawValue
        self.moderatorButton.isHidden = self.post?.canModPost != 1
        self.reportsButton.isHidden = self.post?.canModPost != 1

        self.setNeedsLayout()
    }
    
    fileprivate func pointsTitle() -> String {
        guard let score = self.post?.score else {
            return "0"
        }
        let floatValue = score.floatValue / 1000
        if floatValue >= 100 {
            return String(format: "%.0fk", floatValue)
        } else if floatValue >= 10 {
            return String(format: "%.1fk", floatValue)
        } else {
            return score.stringValue
        }
    }
    
    // MARK: - Convenience
    
    fileprivate func configureLabeledButton(_ button: UIButton) {
        let font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        let insetAmount: CGFloat = 2.0
        
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
        button.titleLabel?.font = font
    }
    
    // MARK: - Actions
    
    @objc func viewComments(_ sender: UIButton?) {
        if let post = self.post {
            self.delegate?.postToolbarView(self, didTapCommentsOnPost: post)
        }
    }
    
    @objc func viewPoints(_ sender: UIButton?) {
        if let post = self.post {
            self.delegate?.postToolbarView(self, didTapPointsOnPost: post)
        }
    }
    
    @objc func more(_ sender: UIButton?) {
        if let post = self.post {
            self.delegate?.postToolbarView(self, didTapMoreOnPost: post)
        }
    }
    
    @objc func moderator(_ sender: UIButton?) {
        if let post = self.post {
            self.delegate?.postToolbarView(self, didTapModeratorOnPost: post)
        }
    }
    
    @objc func upvote(_ sender: UIButton?) {
        if let post = self.post, !self.upvoteButton.animating && !self.downvoteButton.animating {
            self.delegate?.postToolbarView(self, didTapUpvoteOnPost: post)
            self.upvoteButton.setVoted(self.post?.voteStatus?.intValue == VoteStatus.up.rawValue, animated: true)
            self.downvoteButton.setVoted(self.post?.voteStatus?.intValue == VoteStatus.down.rawValue, animated: true)
        }
    }
    
    @objc func downvote(_ sender: UIButton?) {
        if let post = self.post, !self.upvoteButton.animating && !self.downvoteButton.animating {
            self.delegate?.postToolbarView(self, didTapDownvoteOnPost: post)
            self.downvoteButton.setVoted(self.post?.voteStatus?.intValue == VoteStatus.down.rawValue, animated: true)
            self.upvoteButton.setVoted(self.post?.voteStatus?.intValue == VoteStatus.up.rawValue, animated: true)
        }
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        if self.shouldShowSeperator {
            let seperatorPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: rect.width, height: 0.5))
            var seperatorColor = UIColor.beamGreyExtraExtraLight()
            if self.displayMode == .dark {
                seperatorColor = UIColor.beamDarkTableViewSeperatorColor()
            }
            seperatorColor.setFill()
            seperatorPath.fill()
        }
    }
    
    // MARK: - Display mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let tintColor = DisplayModeValue(UIColor(red: 170 / 255.0, green: 168 / 255.0, blue: 179 / 255.0, alpha: 1), darkValue: UIColor(red: 153 / 255.0, green: 153 / 255.0, blue: 153 / 255.0, alpha: 1))
        if self.tintColor != tintColor {
            self.tintColor = tintColor
        }
        self.upvoteButton.color = tintColor
        self.downvoteButton.color = tintColor
        if self.tintAdjustmentMode != UIViewTintAdjustmentMode.normal {
            self.tintAdjustmentMode = UIViewTintAdjustmentMode.normal
        }
        
        UIView.performWithoutAnimation { () -> Void in
            for button in self.tintedButtons {
                if button.tintColor != tintColor {
                    button.tintColor = tintColor
                }
                button.setTitleColor(tintColor, for: UIControlState())
                button.setTitleColor(tintColor, for: UIControlState.highlighted)
            }
            
            //Update opaque views
            let opaqueViews = [self.commentsButton, self.pointsButton, self.moreButton, self.downvoteButton, self.upvoteButton]
            
            var backgroundColor = UIColor.white
            if self.displayMode == .dark {
                backgroundColor = UIColor.beamDarkContentBackgroundColor()
            }
            if !self.isOpaque {
                backgroundColor = UIColor.clear
            }
            for view in opaqueViews {
                if let button = view as? UIButton {
                    button.titleLabel?.backgroundColor = backgroundColor
                }
                view.backgroundColor = backgroundColor
            }
            self.backgroundColor = backgroundColor
            
            for view in opaqueViews {
                if let button = view as? UIButton {
                    button.titleLabel?.isOpaque = self.isOpaque
                }
                view.isOpaque = self.isOpaque
            }
            self.moderatorButton.tintColor = #colorLiteral(red: 0.3047083318, green: 0.6231384277, blue: 0.2308172882, alpha: 1)
            
            //Call setNeedsDisplay to update the seperator
            self.setNeedsDisplay()
            
            self.setNeedsLayout()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        /*
         This works around a bug with UIAlertController and UIAlertView in iOS 8.
         Sometimes after returning the views have the color of the UIWindow they are on, instead of the custom set tintColor or the superview tintColor
         */
        UIView.performWithoutAnimation { () -> Void in
            self.tintAdjustmentMode = .normal
            for button in self.tintedButtons {
                button.tintAdjustmentMode = .normal
            }
            
            self.setNeedsLayout()
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layoutLeftSideButtons()
        self.layoutRightSideButtons()
    }
    
    func layoutLeftSideButtons() {
        let buttonSpacing: CGFloat = 10.0
        //Remove 2 because of the top border
        let barHeight = self.bounds.height - 2
        
        var xPosition = self.layoutMargins.left
        //Because of the increased size of the comments button, substract 10 extra points
        xPosition -= 10
        
        var commentsButtonSize = self.commentsButton.intrinsicContentSize
        commentsButtonSize.height = barHeight
        commentsButtonSize.width += 20
        let commentsButtonFrame = CGRect(origin: CGPoint(x: xPosition, y: (self.bounds.size.height - commentsButtonSize.height) / 2), size: commentsButtonSize)
        self.commentsButton.frame = commentsButtonFrame
        
        xPosition += commentsButtonSize.width + buttonSpacing
        //Because of the increased size of the points button, substract 20 extra points
        xPosition -= 20
        
        var pointsButtonSize = self.pointsButton.intrinsicContentSize
        pointsButtonSize.height = barHeight
        pointsButtonSize.width += 20
        let pointsButtonFrame = CGRect(origin: CGPoint(x: xPosition, y: (self.bounds.size.height - pointsButtonSize.height) / 2), size: pointsButtonSize)
        self.pointsButton.frame = pointsButtonFrame

        xPosition += pointsButtonSize.width + buttonSpacing

        xPosition -= 20

        var reportsButtonSize = self.reportsButton.intrinsicContentSize
        reportsButtonSize.height = barHeight
        reportsButtonSize.width += 20
        let reportsButtonFrame = CGRect(origin: CGPoint(x: xPosition, y: (self.bounds.size.height - reportsButtonSize.height) / 2), size: reportsButtonSize)
        self.reportsButton.frame = reportsButtonFrame

    }
    
    func layoutRightSideButtons() {
        let buttonSpacing: CGFloat = 18.0
        //Remove 2 because of the top border
        let barHeight = self.bounds.height - 2
        
        var xPosition = self.bounds.width - self.layoutMargins.right
        //Because of the increased size of the vote buttons, add 10 extra points
        xPosition += 10
        
        var upvoteButtonSize = self.upvoteButton.intrinsicContentSize
        upvoteButtonSize.height = barHeight
        upvoteButtonSize.width += 20
        let upvoteButtonFrame = CGRect(origin: CGPoint(x: xPosition - upvoteButtonSize.width, y: (self.bounds.size.height - upvoteButtonSize.height) / 2), size: upvoteButtonSize)
        self.upvoteButton.frame = upvoteButtonFrame
        
        xPosition -= upvoteButtonSize.width + buttonSpacing
        //Because of the bigger and ivisible size of the vote button, add 20 extra points so the placement is still the same (10 points each side, times 2 buttons)
        xPosition += 20
        
        var downvoteButtonSize = self.downvoteButton.intrinsicContentSize
        downvoteButtonSize.height = barHeight
        downvoteButtonSize.width += 20
        let downvoteButtonFrame = CGRect(origin: CGPoint(x: xPosition - downvoteButtonSize.width, y: (self.bounds.size.height - downvoteButtonSize.height) / 2), size: downvoteButtonSize)
        self.downvoteButton.frame = downvoteButtonFrame
        
        xPosition -= downvoteButtonSize.width + buttonSpacing
        //Because of the bigger and ivisible size of the vote button, add 10 extra points so the placement is correct of the more button
        xPosition += 20
        
        var moreButtonSize = self.moreButton.intrinsicContentSize
        moreButtonSize.height = barHeight
        moreButtonSize.width += 20
        let moreButtonFrame = CGRect(origin: CGPoint(x: xPosition - moreButtonSize.width, y: (self.bounds.size.height - moreButtonSize.height) / 2), size: moreButtonSize)
        self.moreButton.frame = moreButtonFrame
        xPosition -= moreButtonSize.width + buttonSpacing
        xPosition += 20
        
        var moderatorButtonSize = self.moderatorButton.intrinsicContentSize
        moderatorButtonSize.height = barHeight
        moderatorButtonSize.width += 20
        let moderatorButtonFrame = CGRect(origin: CGPoint(x: xPosition - moderatorButtonSize.width, y: (self.bounds.size.height - moderatorButtonSize.height) / 2), size: moderatorButtonSize)
        self.moderatorButton.frame = moderatorButtonFrame

    }
}
