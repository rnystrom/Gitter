//
//  GithubClient.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/16/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation
import Alamofire
import Apollo
import AlamofireNetworkActivityIndicator
import FlatCache
import GitHubAPI

struct GithubClient {

    let sessionManager: GithubSessionManager
    let apollo: ApolloClient
    let networker: Alamofire.SessionManager
    let userSession: GithubUserSession?
    let cache = FlatCache()
    let bookmarksStore: BookmarkStore?
    let client: Client

    init(
        sessionManager: GithubSessionManager,
        apollo: ApolloClient,
        networker: Alamofire.SessionManager,
        userSession: GithubUserSession? = nil
        ) {
        self.sessionManager = sessionManager
        self.apollo = apollo
        self.networker = networker
        self.userSession = userSession

        self.client = Client(httpPerformer: networker, apollo: apollo, token: userSession?.token)

        if let token = userSession?.token {
            self.bookmarksStore = BookmarkStore(token: token)
        } else {
            self.bookmarksStore = nil
        }
    }

    @discardableResult
    func fetch<Query: GraphQLQuery>(
        query: Query,
        resultHandler: OperationResultHandler<Query>? = nil
        ) -> Cancellable {
        NetworkActivityIndicatorManager.shared.incrementActivityCount()
        return apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData, resultHandler: { (result, error) in
            NetworkActivityIndicatorManager.shared.decrementActivityCount()
            resultHandler?(result, error)
        })
    }

    @discardableResult
    func perform<Mutation: GraphQLMutation>(
        mutation: Mutation,
        resultHandler: OperationResultHandler<Mutation>?
        ) -> Cancellable {
        NetworkActivityIndicatorManager.shared.incrementActivityCount()
        return apollo.perform(mutation: mutation, resultHandler: { (result, error) in
            NetworkActivityIndicatorManager.shared.decrementActivityCount()
            resultHandler?(result, error)
        })
    }

}
