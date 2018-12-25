//
//  PostTitlePartCell.swift
//  beam
//
//  Created by Robin Speijer on 26-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

protocol PostTitlePartCellDelegate: class {
    
    func titlePartCell(_ cell: PostTitlePartCell, didTapThumbnail thumbnailImageView: UIImageView, onPost post: Post)
}

final class PostTitlePartCell: BeamTableViewCell, PostCell {
    
    weak var post: Post? {
        didSet {
            self.titleLabel.attributedText = self.attributedTitle
            self.reloadMetadata()
            if self.thumbnailView != nil {
                if PostTitleThumbnailView.shouldShowThumbnailForPost(post) && self.showThumbnail {
                    self.thumbnailView?.post = self.post
                    self.thumbnailView?.isHidden = false
                    self.bottomLayoutConstraint?.isActive = true
                    self.titleThumbnailViewConstraint?.isActive = true
                    self.metadataThumbnailViewConstraint?.isActive = true
                } else {
                    self.thumbnailView?.stopImageLoading()
                    self.thumbnailView?.isHidden = true
                    self.bottomLayoutConstraint?.isActive = false
                    self.titleThumbnailViewConstraint?.isActive = false
                    self.metadataThumbnailViewConstraint?.isActive = false
                }

            }
            if self.post?.approved == 1 {
                self.approvedButton.alpha = 1.0
                self.removedButton.isHidden = true
                self.removedButton.alpha = 0.0
            } else if self.post?.removed == 1 {
                self.approvedButton.alpha = 0.0
                self.approvedButton.isHidden = true
                self.removedButton.isHidden = false
                self.removedButton.alpha = 1.0
                self.backgroundColor = #colorLiteral(red: 1, green: 0.3098039216, blue: 0.2666666667, alpha: 1)
            } 

            self.reloadTitleColor()
            
            self.setNeedsLayout()
            
        }
    }
    
    var onDetailView: Bool = false {
        didSet {
            if self.onDetailView != oldValue {
                self.reloadFont()
                self.reloadMetadata()
            }
        }
    }
    
    var showThumbnail: Bool = true
    
    weak var delegate: PostTitlePartCellDelegate?
    
    var attributedTitle: NSAttributedString? {
        guard let title = self.post?.title else {
            return nil
        }
        let paragrapthStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragrapthStyle.minimumLineHeight = 21
        paragrapthStyle.maximumLineHeight = 21
        let attributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.paragraphStyle: paragrapthStyle]
        return NSAttributedString(string: title, attributes: attributes)
    }

  
    @IBAction func didTapRemovedButton(_ sender: UIButton) {
    }
    @IBAction func didTapApprovedButton(_ sender: UIButton) {
        if let post = self.post {
            var approvedByString = ""

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
                    let viewController = BeamAlertController(title: approvedByString, message: nil, preferredStyle: .alert)
                    viewController.present(viewController, animated: true, completion: nil)
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
                    let viewController = BeamAlertController(title: removedByString, message: nil, preferredStyle: .alert)
                    viewController.present(viewController, animated: true, completion: nil)
                }
            }


        }
    }
    @IBOutlet var removedButton: UIButton!
    @IBOutlet var approvedButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var thumbnailView: PostTitleThumbnailView?
    @IBOutlet var titleThumbnailViewConstraint: NSLayoutConstraint?
    @IBOutlet var metadataThumbnailViewConstraint: NSLayoutConstraint?
    @IBOutlet var metadataTitleConstraint: NSLayoutConstraint?
    @IBOutlet var metadataView: PostMetadataView?
    @IBOutlet var topSeperatorView: UIView?
    @IBOutlet var topSeperatorViewHeightConstraint: NSLayoutConstraint?
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint?
    
    var shouldShowNSFWOverlay: Bool {
        set {
            self.thumbnailView?.shouldShowNSFWOverlay = newValue
        }
        get {
            return self.thumbnailView?.shouldShowNSFWOverlay ?? true
        }
    }
    var shouldShowSpoilerOverlay: Bool {
        set {
            self.thumbnailView?.shouldShowSpoilerOverlay = newValue
        }
        get {
            return self.thumbnailView?.shouldShowSpoilerOverlay ?? true
        }
    }
    
    var showTopSeperator: Bool = true {
        didSet {
            self.topSeperatorView?.isHidden = !self.showTopSeperator
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.thumbnailView?.prepareForReuse()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupView()
    }
    
    private func setupView() {
        self.preservesSuperviewLayoutMargins = false
        self.contentView.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 12)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PostTitlePartCell.postDidChangeVisitedState(_:)), name: .PostDidChangeVisitedState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PostTitlePartCell.contentSizeCategoryDidChange(_:)), name: .FontSizeCategoryDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PostTitlePartCell.contentApprovedStateDidChange(_:)), name: .PostDidChangeApprovedState, object: nil)
        
        self.reloadFont()
        
        self.thumbnailView?.addTarget(self, action: #selector(PostTitlePartCell.thumbnailTapped(_:)), for: UIControlEvents.touchUpInside)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func reloadMetadata() {
        if self.metadataView != nil {
            if UserSettings[.showPostMetadata] {
                self.metadataView!.post = self.post
                self.metadataView!.isHidden = false
                self.metadataTitleConstraint!.isActive = true
            } else {
                self.metadataView!.isHidden = true
                self.metadataTitleConstraint!.isActive = false
            }
        } else {
            var useBottomSpacing = !UserSettings[.showPostMetadata]
            if self.post?.isSelfText.boolValue == true && NSString(string: self.post?.content ?? "").length > 0 {
                useBottomSpacing = false
            }
            self.bottomLayoutConstraint?.constant = (useBottomSpacing ? 10: 0)
        }

    }
    
    func reloadFont() {
        let fontSize: CGFloat = FontSizeController.adjustedFontSize(17)
        if self.onDetailView && self.post?.isSelfText == true {
            self.titleLabel.font = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.semibold)
        } else {
            self.titleLabel.font = UIFont.systemFont(ofSize: fontSize)
        }
        postApprovedChanged()
    }
    func postApprovedChanged() {
        if self.post?.approved == 1 {
            self.approvedButton.alpha = 1.0
            self.removedButton.isHidden = true
            self.removedButton.alpha = 0.0
        } else if self.post?.removed == 1 {
            self.approvedButton.alpha = 0.0
            self.approvedButton.isHidden = true
            self.removedButton.isHidden = false
            self.removedButton.alpha = 1.0
            self.backgroundColor = #colorLiteral(red: 1, green: 0.3098039216, blue: 0.2666666667, alpha: 1)
        }
    }

    override func displayModeDidChange() {
        super.displayModeDidChange()

        self.reloadTitleColor()
        
        self.titleLabel.isOpaque = true
        self.titleLabel.backgroundColor = self.contentView.backgroundColor
        
        self.thumbnailView?.backgroundColor = self.contentView.backgroundColor
        
        self.topSeperatorView?.backgroundColor = DisplayModeValue(UIColor.beamGreyExtraExtraLight(), darkValue: UIColor.beamDarkTableViewSeperatorColor())
//        if post?.approved == 1 {
//            self.approvedButton.tintColor = #colorLiteral(red: 0.3047083318, green: 0.6231384277, blue: 0.2308172882, alpha: 1)
//            self.approvedButton.alpha = 1.0
//        }
    }
    
    func reloadTitleColor() {
        if self.post?.isVisited == true && UserSettings[.postMarking] && self.onDetailView == false {
            self.titleLabel.textColor = DisplayModeValue(UIColor(red: 127 / 225, green: 127 / 225, blue: 127 / 225, alpha: 1.0), darkValue: UIColor(red: 153 / 225, green: 153 / 225, blue: 153 / 225, alpha: 1.0))
        } else {
            self.titleLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        }
    }

    func pointInsideThumbnail(_ point: CGPoint) -> Bool {
        guard self.thumbnailView?.isHidden == false else {
            return false
        }
        return self.thumbnailView?.frame.contains(point) ?? false
    }
    
    @objc fileprivate func contentSizeCategoryDidChange(_ notification: Notification) {
        self.reloadFont()
    }

    @objc fileprivate func postDidChangeVisitedState(_ notification: Notification) {
        DispatchQueue.main.async {
            if let post = notification.object as? Post, post == self.post {
                self.reloadTitleColor()
            }
        }
    }

    @objc fileprivate func contentApprovedStateDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            if let post = notification.object as? Post, post == self.post {
                self.postApprovedChanged()
            }
        }
    }
    @objc fileprivate func thumbnailTapped(_ sender: AnyObject) {
        if let post = self.post, let imageView = self.thumbnailView?.mediaImageView {
            self.delegate?.titlePartCell(self, didTapThumbnail: imageView, onPost: post)
        }
    }
}
