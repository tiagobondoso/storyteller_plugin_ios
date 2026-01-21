// Storyteller+StoriesRow.swift
// Previously contained Stories Row UI helpers. Intentionally left empty for now
// to keep the extension file as a placeholder for future UI features.

import Foundation
import UIKit
import StorytellerSDK

/// Simple view controller that hosts a single `StorytellerStoriesRowView`
/// configured via `StorytellerStoriesListConfiguration`.
final class StoriesRowViewController: UIViewController {

    private let configuration: StorytellerStoriesListConfiguration
    private var storiesRowView: StorytellerStoriesRowView?

    init(configuration: StorytellerStoriesListConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let storiesRowView = StorytellerStoriesRowView()
        storiesRowView.translatesAutoresizingMaskIntoConstraints = false

        // Reuse the shared handler so taps and analytics flow as in the rest of the plugin
        storiesRowView.delegate = StorytellerHandler.shared
        storiesRowView.configuration = configuration

        view.addSubview(storiesRowView)

        // Center the row horizontally and vertically with a fixed height; it will
        // expand horizontally to fill the width of the screen.
        NSLayoutConstraint.activate([
            storiesRowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            storiesRowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            storiesRowView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            storiesRowView.heightAnchor.constraint(equalToConstant: 120)
        ])

        storiesRowView.reloadData()
        self.storiesRowView = storiesRowView
    }
}

// Keep the extension file around for future Stories Row–related helpers
// that might extend `CDVStoryteller`.
extension CDVStoryteller {
    // No additional Stories Row methods are currently exposed from this extension.
}
