//
//  MilestonesViewController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/15/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

final class MilestonesViewController: UITableViewController {

    private var selectedNumber: Int?
    private var owner: String!
    private var repo: String!
    private var milestones = [Milestone]()
    private var client: GithubClient!
    private let feedRefresh = FeedRefresh()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.refreshControl = feedRefresh.refreshControl
        feedRefresh.refreshControl.addTarget(self, action: #selector(LabelsViewController.onRefresh), for: .valueChanged)

        feedRefresh.beginRefreshing()
        fetch()
    }

    // MARK: Public API

    func configure(client: GithubClient, owner: String, repo: String, selectedNumber: Int?) {
        self.client = client
        self.owner = owner
        self.repo = repo
        self.selectedNumber = selectedNumber
    }

    // MARK: Private API

    @objc func onRefresh() {
        fetch()
    }

    func fetch() {
        client.fetchMilestones(owner: owner, repo: repo) { [weak self] (result) in
            switch result {
            case .success(let milestones):
                self?.milestones = milestones
                self?.tableView.reloadData()
            case .error:
                ToastManager.showGenericError()
            }
            self?.feedRefresh.endRefreshing()
        }
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return milestones.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let cell = cell as? MilestoneCell {
            let milestone = milestones[indexPath.row]
            cell.configure(
                title: milestone.title,
                date: milestone.dueOn,
                showCheckmark: milestone.number == selectedNumber
            )
        }
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let milestone = milestones[indexPath.row]
        if milestone.number == selectedNumber {
            selectedNumber = nil
        } else {
            selectedNumber = milestone.number
        }
        tableView.reloadData()
    }

}
