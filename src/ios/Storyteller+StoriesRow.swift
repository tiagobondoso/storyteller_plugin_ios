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
    private let closeButtonSize: CGFloat = 32

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

        addCloseButton()
    }

    private func addCloseButton() {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        // Use a simple "xmark" if SF Symbols are available; otherwise, fallback to text.
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "xmark")
            button.setImage(image, for: .normal)
        } else {
            button.setTitle("Close", for: .normal)
        }

        button.tintColor = .label
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        view.addSubview(button)

        let topAnchor: NSLayoutYAxisAnchor
        let leadingAnchor: NSLayoutXAxisAnchor

        if #available(iOS 11.0, *) {
            topAnchor = view.safeAreaLayoutGuide.topAnchor
            leadingAnchor = view.safeAreaLayoutGuide.leadingAnchor
        } else {
            topAnchor = topLayoutGuide.bottomAnchor
            leadingAnchor = view.leadingAnchor
        }

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            button.widthAnchor.constraint(equalToConstant: closeButtonSize),
            button.heightAnchor.constraint(equalToConstant: closeButtonSize)
        ])
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// Keep the extension file around for future Stories Row–related helpers
// that might extend `CDVStoryteller`.
extension CDVStoryteller {
    // No additional Stories Row methods are currently exposed from this extension.
}
