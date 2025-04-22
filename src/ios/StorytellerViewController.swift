//  StorytellerViewController.swift
import UIKit
import StorytellerSDK

class StorytellerViewController: UIViewController {
    
    private let storytellerStoriesRow = StorytellerStoriesRowView()
    private let storytellerClipsRow = StorytellerClipsRowView()
    private let storytellerStoriesGrid = StorytellerStoriesGridView(isScrollable: true)
    private let storytellerClipsGrid = StorytellerClipsGridView(isScrollable: true)
    private let storytellerDelegate = StorytellerHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupStorytellerViews()
    }
    
    private func setupStorytellerViews() {
        // Set delegates
        [storytellerStoriesRow, storytellerStoriesGrid, storytellerClipsRow, storytellerClipsGrid].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.delegate = storytellerDelegate
            view.addSubview($0)
        }
        
        // Stories Row
        let storiesRowConfig = StorytellerStoriesListConfiguration(
            categories: ["benfica-top-row", "benfica-singleton", "benfica-moments"],
            cellType: .round,
            displayLimit: 10
        )
        storytellerStoriesRow.configure(with: storiesRowConfig)

        // Stories Grid
        let storiesGridConfig = StorytellerStoriesListConfiguration(
            categories: ["benfica-top-row", "benfica-singleton", "benfica-moments"],
            cellType: .round,
            displayLimit: 10
        )
        storytellerStoriesGrid.configure(with: storiesGridConfig)

        // Clips Row
        let clipsRowConfig = StorytellerClipsListConfiguration(
            collectionId: "benfica-moments",
            cellType: .square,
            displayLimit: 10
        )
        storytellerClipsRow.configure(with: clipsRowConfig)

        // Clips Grid
        let clipsGridConfig = StorytellerClipsListConfiguration(
            collectionId: "benfica-moments",
            cellType: .square,
            displayLimit: 10
        )
        storytellerClipsGrid.configure(with: clipsGridConfig)
        
        // Layout
        NSLayoutConstraint.activate([
            storytellerStoriesRow.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            storytellerStoriesRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            storytellerStoriesRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            storytellerStoriesRow.heightAnchor.constraint(equalToConstant: 120),
            
            storytellerStoriesGrid.topAnchor.constraint(equalTo: storytellerStoriesRow.bottomAnchor, constant: 20),
            storytellerStoriesGrid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            storytellerStoriesGrid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            storytellerStoriesGrid.heightAnchor.constraint(equalToConstant: 300),
            
            storytellerClipsRow.topAnchor.constraint(equalTo: storytellerStoriesGrid.bottomAnchor, constant: 20),
            storytellerClipsRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            storytellerClipsRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            storytellerClipsRow.heightAnchor.constraint(equalToConstant: 120),
            
            storytellerClipsGrid.topAnchor.constraint(equalTo: storytellerClipsRow.bottomAnchor, constant: 20),
            storytellerClipsGrid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            storytellerClipsGrid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            storytellerClipsGrid.heightAnchor.constraint(equalToConstant: 300),
        ])
        
        // Load data
        [storytellerStoriesRow, storytellerStoriesGrid, storytellerClipsRow, storytellerClipsGrid].forEach {
            $0.reloadData()
        }
    }
}
