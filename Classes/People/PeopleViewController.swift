//
//  PeopleViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/2/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation
import IGListKit
import GitHubAPI
import Squawk

final class PeopleViewController: BaseListViewController2<String>,
BaseListViewController2DataSource,
PeopleSectionControllerDelegate {

    enum PeopleType {
        case assignee
        case reviewer
    }

    public let type: PeopleType

    private let selections: Set<String>
    private let selectionLimit = 10
    private let exclusions: Set<String>
    private var users = [IssueAssigneeViewModel]()
    private let client: GithubClient
    private var owner: String
    private var repo: String

    init(
        selections: [String],
        exclusions: [String],
        type: PeopleType,
        client: GithubClient,
        owner: String,
        repo: String
        ) {
        self.selections = Set<String>(selections)
        self.exclusions = Set<String>(exclusions)
        self.type = type
        self.client = client
        self.owner = owner
        self.repo = repo

        super.init(emptyErrorMessage: NSLocalizedString("Cannot load users.", comment: ""))

        self.dataSource = self

        feed.collectionView.backgroundColor = Styles.Colors.menuBackgroundColor.color
        feed.setLoadingSpinnerColor(to: .white)
        preferredContentSize = Styles.Sizes.contextMenuSize
        updateTitle()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        addMenuDoneButton()
        addMenuClearButton()
    }

    // MARK: Public API

    var selected: [IssueAssigneeViewModel] {
        return users.filter {
            if let sectionController: PeopleSectionController = feed.swiftAdapter.sectionController(for: $0) {
                return sectionController.selected
            }
            return false
        }
    }

    func updateClearButtonEnabled() {
        navigationItem.leftBarButtonItem?.isEnabled = selected.count > 0
    }

    func addMenuClearButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Clear", comment: ""),
            style: .plain,
            target: self,
            action: #selector(onMenuClear)
        )
        navigationItem.leftBarButtonItem?.tintColor = Styles.Colors.Gray.light.color
        updateClearButtonEnabled()
    }

    @objc func onMenuClear() {
        self.selected.forEach {
            if let sectionController: PeopleSectionController = feed.swiftAdapter.sectionController(for: $0) {
                sectionController.didSelectItem(at: 0)
            }
        }
    }
    
    static func sortUsers(users: [V3User], currentUser: String?) -> [V3User] {
        return users.sorted {
            if $0.login == currentUser {
                return true
            } else {
                return $0.login.caseInsensitiveCompare($1.login) == .orderedAscending
            }
        }
    }

    // MARK: Private API

    private func updateTitle() {
        let selectedCount = "\(selected.count)/\(selectionLimit)"
        switch type {
        case .assignee: title = "\(NSLocalizedString("Assignees", comment: "")) \(selectedCount)"
        case .reviewer: title = "\(NSLocalizedString("Reviewers", comment: "")) \(selectedCount)"
        }
        updateClearButtonEnabled()
    }

    // MARK: Overrides

    override func fetch(page: String?) {

        client.client.send(
            V3AssigneesRequest(
                owner: owner,
                repo: repo,
                page: (page as NSString?)?.integerValue ?? 1
            )
        ) { [weak self] result in
            switch result {
            case .success(let response):
                let sortedUsers = PeopleViewController.sortUsers(
                    users: response.data,
                    currentUser: self?.client.userSession?.username
                )
                let users = sortedUsers.map { IssueAssigneeViewModel(login: $0.login, avatarURL: $0.avatarUrl) }
                if page != nil {
                    self?.users += users
                } else {
                    self?.users = users
                }
                self?.update(animated: true)

                let nextPage: String?
                if let next = response.next {
                    nextPage = "\(next)"
                } else {
                    nextPage = nil
                }
                self?.update(page: nextPage, animated: true)
            case .failure(let error):
                Squawk.show(error: error)
            }
        }
    }

    // MARK: BaseListViewController2DataSource

    func models(adapter: ListSwiftAdapter) -> [ListSwiftPair] {
        return users
            .filter { [exclusions] user in !exclusions.contains(user.login) }
            .map { [selections] user in
                return ListSwiftPair.pair(user) { [weak self] in
                    let controller = PeopleSectionController(selected: selections.contains(user.login))
                    controller.delegate = self
                    return controller
                }
            }
    }

    // MARK: PeopleSectionControllerDelegate

    func didSelect(controller: PeopleSectionController) {
        updateTitle()
    }
}
