//
//  PullRequestsViewController.swift
//  SwiftHub
//
//  Created by Sygnoos9 on 11/30/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

private let reuseIdentifier = R.reuseIdentifier.pullRequestCell.identifier

enum PullRequestSegments: Int {
    case open, closed

    var title: String {
        switch self {
        case .open: return R.string.localizable.issuesOpenSegmentTitle.key.localized()
        case .closed: return R.string.localizable.issuesClosedSegmentTitle.key.localized()
        }
    }

    var state: State {
        switch self {
        case .open: return .open
        case .closed: return .closed
        }
    }
}

class PullRequestsViewController: TableViewController {

    var viewModel: PullRequestsViewModel!

    lazy var segmentedControl: SegmentedControl = {
        let items = [IssueSegments.open.title,
                     IssueSegments.closed.title]
        let view = SegmentedControl(items: items)
        view.selectedSegmentIndex = 0
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func makeUI() {
        super.makeUI()

        navigationItem.titleView = segmentedControl

        tableView.register(R.nib.pullRequestCell)
    }

    override func bindViewModel() {
        super.bindViewModel()

        let segmentSelected = Observable.of(segmentedControl.rx.selectedSegmentIndex.map { PullRequestSegments(rawValue: $0)! }).merge()
        let refresh = Observable.of(Observable.just(()), headerRefreshTrigger, segmentSelected.mapToVoid().skip(1)).merge()
        let input = PullRequestsViewModel.Input(headerRefresh: refresh,
                                                footerRefresh: footerRefreshTrigger,
                                                segmentSelection: segmentSelected,
                                                selection: tableView.rx.modelSelected(PullRequestCellViewModel.self).asDriver())
        let output = viewModel.transform(input: input)

        viewModel.loading.asObservable().bind(to: isLoading).disposed(by: rx.disposeBag)
        viewModel.headerLoading.asObservable().bind(to: isHeaderLoading).disposed(by: rx.disposeBag)
        viewModel.footerLoading.asObservable().bind(to: isFooterLoading).disposed(by: rx.disposeBag)

        output.navigationTitle.drive(onNext: { [weak self] (title) in
            self?.navigationTitle = title
        }).disposed(by: rx.disposeBag)

        output.items.asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: reuseIdentifier, cellType: PullRequestCell.self)) { tableView, viewModel, cell in
                cell.bind(to: viewModel)
            }.disposed(by: rx.disposeBag)

        output.pullRequestSelected.drive(onNext: { [weak self] (url) in
            if let url  = url {
                self?.navigator.show(segue: .webController(url), sender: self)
            }
        }).disposed(by: rx.disposeBag)

        viewModel.error.asDriver().drive(onNext: { [weak self] (error) in
            self?.showAlert(title: R.string.localizable.commonError.key.localized(), message: error.localizedDescription)
        }).disposed(by: rx.disposeBag)
    }
}