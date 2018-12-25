//
//  ContentModeration+Operations.swift
//  Snoo
//
//  Created by Joel Payne on 10/19/18.
//  Copyright © 2018 Awkward. All rights reserved.
//
/*
api_type - the string json
how - one of (yes, no, admin, special)
id - fullname of a thing
sticky - boolean value
 */
import Foundation

extension Content {

    public func distinguish(_ distinguish: Bool, authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession
            let command = distinguish ? "yes" : "no"
            let distinguishedType = "moderator"
            let url = URL(string: "/api/distinguish", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "api_type", value: "json"), URLQueryItem(name: "how", value: command), URLQueryItem(name: "id", value: self.objectName), URLQueryItem(name: "sticky", value: "false")]
            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.distinguished = distinguishedType
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
    public func sticky(authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let sticky = true
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession
            let command = "yes"
            let distinguishedType = "moderator"
            let url = URL(string: "/api/distinguish", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "api_type", value: "json"), URLQueryItem(name: "how", value: command), URLQueryItem(name: "id", value: self.objectName), URLQueryItem(name: "sticky", value: sticky.description)]
            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.stickied = NSNumber(value: sticky as Bool)
                    self?.distinguished = distinguishedType
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
    public func unsticky(keepDistinguished: Bool, authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let sticky = false
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession
            let command = keepDistinguished ? "yes" : "no"
            let url = URL(string: "/api/distinguish", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "api_type", value: "json"), URLQueryItem(name: "how", value: command), URLQueryItem(name: "id", value: self.objectName), URLQueryItem(name: "sticky", value: sticky.description)]
            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.stickied = NSNumber(value: sticky as Bool)
                    self?.distinguished = nil
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
    public func approve(authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession

            let url = URL(string: "/api/approve", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "id", value: self.objectName)]

            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.approved = NSNumber(value: true as Bool)
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
    public func remove(authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession

            let url = URL(string: "/api/remove", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "id", value: self.objectName), URLQueryItem(name: "spam", value: "false")]

            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.removed = NSNumber(value: true as Bool)
                    self?.approved = NSNumber(value: true as Bool)
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
    public func markSpam(authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession

            let url = URL(string: "/api/remove", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "id", value: self.objectName), URLQueryItem(name: "spam", value: "true")]

            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.spam = NSNumber(value: true as Bool)
                    self?.removed = NSNumber(value: true as Bool)
                    self?.approved = NSNumber(value: true as Bool)
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
    
    public func ignoreReports(_ ignoreReports: Bool, authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession
            let command = ignoreReports ? "ignore_reports" : "unignore_reports"
            let url = URL(string: "/api/\(command)", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "id", value: self.objectName)]

            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest

            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.ignoreReports = NSNumber(value: ignoreReports as Bool)
                })
            }

            return request
        } else {
            return BlockOperation(block: { () -> Void in
            })
        }

    }
}
/*
/api/distinguish
/api/remove
/api/approve
/api/ignore_reports
/api/unignore_reports
 */
