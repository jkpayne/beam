//
//  ModeratorPostImageCollectionPartCell.swift
//  beam
//
//  Created by Robin Speijer on 21-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

/// A protocol to communicate image collection part cell user interaction.
protocol ModeratorPostImageCollectionPartCellDelegate: class {
    
    /// The user tapped on a media object in the part cell.
    func ModeratorpostImageCollectionPartCell(_ cell: ModeratorPostImageCollectionPartCell, didTapMediaObjectAtIndex mediaIndex: Int)
    
    /// The user tapped on a more button in the part cell.
    func ModeratorpostImageCollectionPartCell(_ cell: ModeratorPostImageCollectionPartCell, didTapMoreButtonAtIndex mediaIndex: Int)
    
}

/**
A part of the post cell that represents an image album. Internally, it has a UICollectionView in it.
*/
final class ModeratorPostImageCollectionPartCell: BeamTableViewCell, PostCell {
    
    var post: Post?
    
    var onDetailView: Bool = false
    
    var visibleSubreddit: Subreddit? {
        didSet {
            self.albumView.shouldShowNSFWOverlay = self.visibleSubreddit?.shouldShowNSFWOverlay() ?? UserSettings[.showPrivacyOverlay]
            self.albumView.shouldShowSpoilerOverlay = self.visibleSubreddit?.shouldShowSpoilerOverlay() ?? UserSettings[.showSpoilerOverlay]
        }
    }
    
    /// Media objects that are being displayed in the part cell.
    var mediaObjects: [MediaObject]? {
        didSet {
            
            self.albumView.mediaObjects = self.mediaObjects

        }
    }
    
    /// Delegate to communicate user interaction back.
    weak var delegate: ModeratorPostImageCollectionPartCellDelegate?
    
    @IBOutlet fileprivate var albumView: StreamAlbumView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.albumView.delegate = self
    }
    
    func imageViewAtIndex(_ index: Int) -> UIImageView? {
        return self.albumView.albumItemViewAtIndex(index)?.mediaImageView
    }
    
    func albumItemViewAtLocation(_ location: CGPoint) -> StreamAlbumItemView? {
        return self.albumView.albumItemViewForLocation(location)
    }
    
    func mediaItemAtLocation(_ location: CGPoint) -> MediaObject? {
        return self.albumView.mediaObjectForLocation(location)
    }
    
}

extension ModeratorPostImageCollectionPartCell: StreamAlbumViewDelegate {
    
    func albumView(_ collectionView: StreamAlbumView, didTapItemView itemView: StreamAlbumItemView, atIndex index: Int) {
        if itemView.moreCount > 0 {
            self.delegate?.ModeratorpostImageCollectionPartCell(self, didTapMoreButtonAtIndex: index)
        } else {
            self.delegate?.ModeratorpostImageCollectionPartCell(self, didTapMediaObjectAtIndex: index)
        }
    }

}
