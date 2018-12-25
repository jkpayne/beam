//
//  PostModeration+Operations.swift
//  Snoo
//
//  Created by Joel Payne on 10/19/18.
//  Copyright © 2018 Awkward. All rights reserved.
//

import Foundation


extension Post {


    public func lock(_ locked: Bool, authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession
            let command = locked ? "lock" : "unlock"
            let url = URL(string: "/api/\(command)", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "id", value: self.objectName)]

            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.locked = NSNumber(value: locked as Bool)
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
    public func markNsfw(_ nsfw: Bool, authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession
            let command = nsfw ? "marknsfw" : "unmarknsfw"
            let url = URL(string: "/api/\(command)", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "id", value: self.objectName)]

            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.isContentNSFW = NSNumber(value: nsfw as Bool)
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
    public func markSpoiler(_ spoiler: Bool, authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession
            let command = spoiler ? "spoiler" : "unspoiler"
            let url = URL(string: "/api/\(command)", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "id", value: self.objectName)]

            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.isContentSpoiler = NSNumber(value: spoiler as Bool)
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
    public func markSticky(_ stickied: Bool, authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession

            let url = URL(string: "/api/set_subreddit_sticky", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "api_type", value: "json"), URLQueryItem(name: "id", value: self.objectName), URLQueryItem(name: "state", value: stickied.description)]

            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.stickied = NSNumber(value: stickied as Bool)
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
//    public func setContestModeOperation(_ contestMode: Bool, authenticationController: AuthenticationController) -> Operation {
//        if authenticationController.isAuthenticated {
//            let request = RedditRequest(authenticationController: authenticationController)
//            request.urlSession = authenticationController.userURLSession
//            let url = URL(string: "/api/set_contest_mode", relativeTo: request.baseURL as URL)!
//            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
//            urlComponents.queryItems = [URLQueryItem(name: "api", value: self.objectName), URLQueryItem(name: "id", value: self.objectName), URLQueryItem(name: "state", value: contestMode.description)]
//
//            var urlRequest = URLRequest(url: urlComponents.url!)
//            urlRequest.httpMethod = "POST"
//            request.urlRequest = urlRequest
//
//            request.completionBlock = { [weak self] () in
//                self?.managedObjectContext?.perform({ () -> Void in
//                    self?.contestMode = NSNumber(value: contestMode as Bool)
//                })
//            }
//
//            return request
//        } else {
//            return BlockOperation(block: { () -> Void in
//                self.isSticky = true
//            })
//        }
//
//    }
}
/*


 /api/lock
 /api/unlock
 /api/marknsfw
 /api/unmarknsfw
 /api/spoiler
 /api/unspoiler
 /api/set_contest_mode
 /api/set_subreddit_sticky
 /api/set_suggested_sort

 */

