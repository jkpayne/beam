//
//  Content+CoreDataProperties.swift
//  Snoo
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

extension Content {

    @NSManaged public var content: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var downvoteCount: NSNumber?
    @NSManaged public var gildCount: NSNumber?
    @NSManaged public var permalink: String?
    @NSManaged public var score: NSNumber?
    
    @NSManaged public var upvoteCount: NSNumber?
    @NSManaged public var voteStatus: NSNumber?
    @NSManaged public var author: String?
    @NSManaged public var authorFlairText: String?
    @NSManaged public var mediaObjects: NSOrderedSet?
    @NSManaged public var referencedByMessages: NSSet?
    
    //Required properties with a default value
    @NSManaged public var scoreHidden: NSNumber //Default: No
    @NSManaged public var isSaved: NSNumber //Default: No
    @NSManaged public var stickied: NSNumber //Default: No
    @NSManaged public var archived: NSNumber //Default: No
    @NSManaged public var locked: NSNumber //Default: No

    //Moderator
    @NSManaged public var approved: NSNumber
    @NSManaged public var approvedAtUtc: NSDate?
    @NSManaged public var approvedBy: String?
    @NSManaged public var bannedAtUtc: NSDate?
    @NSManaged public var bannedBy: String?
    @NSManaged public var banNote: String?
    @NSManaged public var canModPost: NSNumber
    @NSManaged public var distinguished: String?
    @NSManaged public var ignoreReports: NSNumber
    @NSManaged public var modNote: String?
    @NSManaged public var modReasonBy: String?
    @NSManaged public var modReasonTitle: String?
    @NSManaged public var modReports: [String : String]?
    @NSManaged public var numReports: NSNumber?
    @NSManaged public var removalReason: String?
    @NSManaged public var removed: NSNumber
    @NSManaged public var spam: NSNumber
    @NSManaged public var userReports: [String : Int]?
    @NSManaged public var userReportsDismissed: [String : Int]?
    @NSManaged public var modReportsDismissed: [String : String]?
    @NSManaged public var depth: NSNumber?
}
