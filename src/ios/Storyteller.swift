
// Storyteller.swift
// Main Cordova plugin entry point (CDVStoryteller) and core helpers
import Foundation
import UIKit
import WebKit
import StorytellerSDK

@objc(CDVStoryteller)
class CDVStoryteller: CDVPlugin {
    // MARK: - State

    private var inlineStoriesRowContainer: UIView?
    private var inlineStoriesRowView: StorytellerStoriesRowView?
    private var inlineTopConstraint: NSLayoutConstraint?
    private var inlineLeadingConstraint: NSLayoutConstraint?
    private var inlineTrailingConstraint: NSLayoutConstraint?
    private var inlineHeightConstraint: NSLayoutConstraint?
    private weak var inlineHostView: UIView?
    private var inlineAttachmentMode: InlineAttachmentMode?
    private weak var inlineScrollView: UIScrollView?
    private var inlineDocumentFrame: CGRect?
    private var currentInlineLayout: InlineLayoutOptions?

    /// Generic events callback id (JS listener) used for test events and later for analytics.
    private var genericEventsCallbackId: String?

    // MARK: - Cordova lifecycle

    override func pluginInitialize() {
        super.pluginInitialize()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStorytellerGenericEvent(_:)),
            name: Notification.Name("StorytellerGenericEvent"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Initialize SDK
    @objc(initializeSDK:)
    func initializeSDK(_ command: CDVInvokedUrlCommand) {
        guard let apiKey = command.argument(at: 0) as? String, !apiKey.isEmpty else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "API key is missing.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        guard let userId = command.argument(at: 1) as? String else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "User ID is missing.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        let userInput = UserInput(externalId: userId)

        Task {
            do {
                try await Storyteller.initialize(apiKey: apiKey, userInput: userInput)
                print("Storyteller SDK initialized for user: \(userId)")

                // Ensure StorytellerHandler is instantiated so it can register as delegate
                _ = StorytellerHandler.shared

                let result = CDVPluginResult(status: .ok, messageAs: "Storyteller SDK initialized for user: \(userId)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                print("Storyteller SDK Init Error: \(error)")
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    // MARK: - Generic Events Listener (test)

    /// Registers a long-lived JS listener for generic events.
    /// JS usage: Storyteller.setEventListener(function (event) { ... })
    @objc(setEventListener:)
    func setEventListener(_ command: CDVInvokedUrlCommand) {
        // Store callback id so we can push events later.
        genericEventsCallbackId = command.callbackId

        // Immediately acknowledge registration and keep callback alive.
        if let result = CDVPluginResult(status: .ok, messageAs: [
            "type": "listener_registered",
            "message": "Generic event listener registered"
        ]) {
            result.setKeepCallbackAs(true)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    /// Sends a generic event payload to JS if a listener is registered.
    @objc
    func sendGenericEventToJS(payload: [String: Any]) {
        guard let callbackId = genericEventsCallbackId else { return }

        if let result = CDVPluginResult(status: .ok, messageAs: payload) {
            result.setKeepCallbackAs(true)
            self.commandDelegate.send(result, callbackId: callbackId)
        }
    }

    /// Handles notifications from StorytellerHandler and forwards them to JS.
    @objc
    func handleStorytellerGenericEvent(_ notification: Notification) {
        guard let payload = notification.userInfo as? [String: Any] else { return }
        sendGenericEventToJS(payload: payload)
    }

    // MARK: - Debug helpers

    /// Simple ping method to verify Cordova wiring from JS/OutSystems.
    /// JS usage: Storyteller.debugPing().then(...)
    @objc(debugPing:)
    func debugPing(_ command: CDVInvokedUrlCommand) {
        let message = "Storyteller iOS plugin is reachable (debugPing)."
        let pluginResult = CDVPluginResult(status: .ok, messageAs: message)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    // MARK: - Show Full Native View
    @objc(showStorytellerView:)
    func showStorytellerView(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async {
            let vc = StorytellerViewController()
            vc.modalPresentationStyle = .fullScreen
            self.viewController.present(vc, animated: true, completion: nil)

            let pluginResult = CDVPluginResult(status: .ok, messageAs: "Storyteller view presented.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }

    // MARK: - Open story by id or externalId
    // JS usage: openStoryById(idOrExternalId)
    @objc(openStoryById:)
    func openStoryById(_ command: CDVInvokedUrlCommand) {
        guard let id = command.argument(at: 0) as? String, !id.isEmpty else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "Story ID is missing.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            do {
                // Try to open by internal id first, if it throws try externalId
                do {
                    try await Storyteller.openStory(id: id)
                } catch {
                    // If opening by id fails, attempt externalId fallback
                    try await Storyteller.openStory(externalId: id)
                }

                let result = CDVPluginResult(status: .ok, messageAs: "Story opened: \(id)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                print("openStory error: \(error)")
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    // MARK: - Open Player helpers (categories, pages, clips)

    // JS usage: openCategory(categoryId)
    @objc(openCategory:)
    func openCategory(_ command: CDVInvokedUrlCommand) {
        guard let category = command.argument(at: 0) as? String, !category.isEmpty else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "Category id is missing.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            do {
                try await Storyteller.openCategory(category: category)
                let result = CDVPluginResult(status: .ok, messageAs: "Category opened: \(category)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    // JS usage: openPage(pageId)
    @objc(openPage:)
    func openPage(_ command: CDVInvokedUrlCommand) {
        guard let pageId = command.argument(at: 0) as? String, !pageId.isEmpty else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "Page id is missing.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            do {
                try await Storyteller.openPage(id: pageId)
                let result = CDVPluginResult(status: .ok, messageAs: "Page opened: \(pageId)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    // JS usage: openCollection(configuration)
    // configuration is passed as a dictionary and mapped to StorytellerClipCollectionConfiguration on the native side.
    @objc(openCollection:)
    func openCollection(_ command: CDVInvokedUrlCommand) {
        guard let configDict = command.argument(at: 0) as? [String: Any] else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "Configuration dictionary is missing.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        // Minimal mapping: expect at least collectionId; destination is optional.
        guard let collectionId = configDict["collectionId"] as? String, !collectionId.isEmpty else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "collectionId is required in configuration.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            do {
                var configuration = StorytellerClipCollectionConfiguration(collectionId: collectionId)

                if let destinationDict = configDict["destination"] as? [String: Any] {
                    if let clipExternalId = destinationDict["clipExternalId"] as? String, !clipExternalId.isEmpty {
                        configuration.destination = .clipExternalId(clipExternalId)
                    } else if let categoryId = destinationDict["categoryId"] as? String, !categoryId.isEmpty {
                        configuration.destination = .categoryId(categoryId)
                    }
                }

                try await Storyteller.openCollection(configuration: configuration)
                let result = CDVPluginResult(status: .ok, messageAs: "Collection opened: \(collectionId)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    // JS usage: openClipByExternalId(collectionId, externalId)
    @objc(openClipByExternalId:)
    func openClipByExternalId(_ command: CDVInvokedUrlCommand) {
        guard let collectionId = command.argument(at: 0) as? String, !collectionId.isEmpty else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "collectionId is missing.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        guard let externalId = command.argument(at: 1) as? String, !externalId.isEmpty else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "externalId is missing.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            do {
                try await Storyteller.openClipByExternalId(collectionId: collectionId, externalId: externalId)
                let result = CDVPluginResult(status: .ok, messageAs: "Clip opened: \(externalId) in collection: \(collectionId)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    // COM ESTE CÓDIGO DÁ ERROS A GERAR A BUILD
    // JS usage: getFollowedCategories()
    /* @objc(getFollowedCategories:)
    func getFollowedCategories(_ command: CDVInvokedUrlCommand) {
        Task { @MainActor in
            do {
                let cats = try await Storyteller.user.getFollowedCategories()
                let result = CDVPluginResult(status: .ok, messageAs: cats)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }


    // JS usage: isCategoryFollowed(categoryId)
    @objc(isCategoryFollowed:)
    func isCategoryFollowed(_ command: CDVInvokedUrlCommand) {
        guard let category = command.argument(at: 0) as? String, !category.isEmpty else {
            let result = CDVPluginResult(status: .error, messageAs: "Category id is required.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

            Task { @MainActor in
                do {
                    let isFollowing = try await Storyteller.user.isCategoryFollowed(category)
                    let result = CDVPluginResult(status: .ok, messageAs: isFollowing)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                } catch {
                    let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            }
    }*/

    // Private UIViewController to host StorytellerStoriesRowView
    private class StoriesRowViewController: UIViewController {
        private let configuration: StorytellerStoriesListConfiguration?
        private let storiesRowView = StorytellerStoriesRowView()
        private let storytellerDelegate = StorytellerHandler.shared

        init(configuration: StorytellerStoriesListConfiguration?) {
            self.configuration = configuration
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .systemBackground
            storiesRowView.translatesAutoresizingMaskIntoConstraints = false
            storiesRowView.delegate = storytellerDelegate
            view.addSubview(storiesRowView)
            NSLayoutConstraint.activate([
                storiesRowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                storiesRowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                storiesRowView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                storiesRowView.heightAnchor.constraint(equalToConstant: 240)
            ])

            if let configuration = configuration {
                storiesRowView.configure(with: configuration)
            }

            storiesRowView.reloadData()
        }
    }

    // MARK: - Inline Stories Row helpers
    @MainActor
    private func mountInlineStoriesRow(configuration: StorytellerStoriesListConfiguration, layout: InlineLayoutOptions) throws {
        guard let hostView = self.viewController?.view else {
            throw InlineStoriesRowError.missingHostView
        }

        teardownInlineStoriesRow()

        inlineHostView = hostView
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = layout.backgroundColor ?? .clear
        container.layer.cornerRadius = layout.cornerRadius
        container.clipsToBounds = layout.cornerRadius > 0

        let storiesRowView = StorytellerStoriesRowView()
        storiesRowView.translatesAutoresizingMaskIntoConstraints = false
        storiesRowView.delegate = StorytellerHandler.shared
        storiesRowView.configure(with: configuration)

        container.addSubview(storiesRowView)
        NSLayoutConstraint.activate([
            storiesRowView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            storiesRowView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            storiesRowView.topAnchor.constraint(equalTo: container.topAnchor),
            storiesRowView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        inlineStoriesRowContainer = container
        inlineStoriesRowView = storiesRowView

        storiesRowView.reloadData()

        if !attachInlineContainerToScrollView(container: container, layout: layout) {
            attachInlineContainerAsOverlay(container: container, hostView: hostView, layout: layout)
        }

        applyInlineLayout(layout)
    }

    @MainActor
    private func applyInlineLayout(_ layout: InlineLayoutOptions) {
        currentInlineLayout = layout

        inlineStoriesRowContainer?.backgroundColor = layout.backgroundColor ?? .clear
        inlineStoriesRowContainer?.layer.cornerRadius = layout.cornerRadius
        inlineStoriesRowContainer?.clipsToBounds = layout.cornerRadius > 0
        inlineStoriesRowContainer?.isHidden = layout.isHidden

        if layout.prefersScrollAttachment, inlineAttachmentMode != .scrollContent {
            if attachInlineContainerToScrollView(container: inlineStoriesRowContainer, layout: layout) {
                inlineAttachmentMode = .scrollContent
            }
        } else if !layout.prefersScrollAttachment, inlineAttachmentMode == .scrollContent,
                  let hostView = inlineHostView,
                  let container = inlineStoriesRowContainer {
            attachInlineContainerAsOverlay(container: container, hostView: hostView, layout: layout)
        }

        switch inlineAttachmentMode {
        case .overlay:
            inlineTopConstraint?.constant = layout.top
            inlineLeadingConstraint?.constant = layout.leading
            inlineTrailingConstraint?.constant = -layout.trailing
            inlineHeightConstraint?.constant = layout.height
            inlineStoriesRowContainer?.setNeedsLayout()
            inlineStoriesRowContainer?.layoutIfNeeded()
        case .scrollContent:
            inlineDocumentFrame = layout.documentFrame ?? inlineDocumentFrame
            updateInlineScrollAttachmentFrame()
        case .none:
            break
        }
    }

    @MainActor
    private func teardownInlineStoriesRow() {
        inlineStoriesRowView?.delegate = nil
        inlineStoriesRowView?.removeFromSuperview()
        inlineStoriesRowContainer?.removeFromSuperview()
        inlineStoriesRowView = nil
        inlineStoriesRowContainer = nil
        inlineTopConstraint = nil
        inlineLeadingConstraint = nil
        inlineTrailingConstraint = nil
        inlineHeightConstraint = nil
        inlineHostView = nil
        inlineAttachmentMode = nil
        inlineScrollView = nil
        inlineDocumentFrame = nil
        currentInlineLayout = nil
    }

    @MainActor
    private func attachInlineContainerAsOverlay(container: UIView, hostView: UIView, layout: InlineLayoutOptions) {
        detachScrollAttachmentIfNeeded()
        if container.superview !== hostView {
            container.removeFromSuperview()
            container.translatesAutoresizingMaskIntoConstraints = false
            hostView.addSubview(container)
        }

        inlineAttachmentMode = .overlay
        inlineScrollView = nil
        inlineDocumentFrame = nil

        hostView.bringSubviewToFront(container)

        let topAnchorTarget: NSLayoutYAxisAnchor = layout.useSafeArea ? hostView.safeAreaLayoutGuide.topAnchor : hostView.topAnchor

        let topConstraint = container.topAnchor.constraint(equalTo: topAnchorTarget, constant: layout.top)
        let leadingConstraint = container.leadingAnchor.constraint(equalTo: hostView.leadingAnchor, constant: layout.leading)
        let trailingConstraint = container.trailingAnchor.constraint(equalTo: hostView.trailingAnchor, constant: -layout.trailing)
        let heightConstraint = container.heightAnchor.constraint(equalToConstant: layout.height)

        NSLayoutConstraint.activate([topConstraint, leadingConstraint, trailingConstraint, heightConstraint])

        inlineTopConstraint = topConstraint
        inlineLeadingConstraint = leadingConstraint
        inlineTrailingConstraint = trailingConstraint
        inlineHeightConstraint = heightConstraint
    }

    @MainActor
    @discardableResult
    private func attachInlineContainerToScrollView(container: UIView?, layout: InlineLayoutOptions) -> Bool {
        guard let container = container,
              layout.prefersScrollAttachment,
              let documentFrame = layout.documentFrame,
              let scrollView = resolveScrollView() else {
            return false
        }

        detachOverlayConstraintsIfNeeded()
        if container.superview !== scrollView {
            container.removeFromSuperview()
            container.translatesAutoresizingMaskIntoConstraints = true
            container.autoresizingMask = []
            scrollView.addSubview(container)
        }

        inlineAttachmentMode = .scrollContent
        inlineScrollView = scrollView
        inlineDocumentFrame = documentFrame

        scrollView.bringSubviewToFront(container)

        inlineTopConstraint = nil
        inlineLeadingConstraint = nil
        inlineTrailingConstraint = nil
        inlineHeightConstraint = nil

        updateInlineScrollAttachmentFrame(using: layout)
        return true
    }

    private func detachOverlayConstraintsIfNeeded() {
        inlineTopConstraint?.isActive = false
        inlineLeadingConstraint?.isActive = false
        inlineTrailingConstraint?.isActive = false
        inlineHeightConstraint?.isActive = false

        inlineTopConstraint = nil
        inlineLeadingConstraint = nil
        inlineTrailingConstraint = nil
        inlineHeightConstraint = nil
    }

    private func detachScrollAttachmentIfNeeded() {
        guard inlineAttachmentMode == .scrollContent else { return }
        inlineScrollView = nil
        inlineDocumentFrame = nil
    }

    @MainActor
    private func updateInlineScrollAttachmentFrame(using layoutOverride: InlineLayoutOptions? = nil) {
        guard inlineAttachmentMode == .scrollContent,
              let container = inlineStoriesRowContainer,
              let layout = layoutOverride ?? currentInlineLayout,
              let scrollView = inlineScrollView else {
            return
        }

        guard let baseFrame = layout.documentFrame ?? inlineDocumentFrame else { return }
        let resolvedFrame = normalizedScrollAttachmentFrame(baseFrame: baseFrame, layout: layout, in: scrollView)

        if container.frame.integral != resolvedFrame.integral {
            container.frame = resolvedFrame
            container.setNeedsLayout()
            container.layoutIfNeeded()
        }
    }

    @MainActor
    private func updateInlineScrollAttachmentFrame() {
        updateInlineScrollAttachmentFrame(using: nil)
    }

    private func normalizedScrollAttachmentFrame(baseFrame: CGRect, layout: InlineLayoutOptions, in scrollView: UIScrollView) -> CGRect {
        var frame = baseFrame

        if frame.width <= 0 {
            let viewportWidth = scrollView.bounds.width
            frame.size.width = max(0, viewportWidth - layout.leading - layout.trailing)
        }

        if frame.height <= 0 {
            frame.size.height = layout.height
        }

        return frame
    }

    private func resolveScrollView() -> UIScrollView? {
        if let direct = extractScrollView(from: self.webView) {
            return direct
        }

        if let engineView = self.webViewEngine?.engineWebView, let engineScroll = extractScrollView(from: engineView) {
            return engineScroll
        }

        if let host = self.viewController?.view, let nested = findNestedScrollView(in: host) {
            return nested
        }

        return nil
    }

    private func extractScrollView(from candidate: UIView?) -> UIScrollView? {
        if let wkWebView = candidate as? WKWebView {
            return wkWebView.scrollView
        }

        if let uiWebView = candidate as? UIWebView {
            return uiWebView.scrollView
        }

        if let scroll = candidate as? UIScrollView {
            return scroll
        }

        return nil
    }

    private func findNestedScrollView(in view: UIView) -> UIScrollView? {
        if let scroll = extractScrollView(from: view) {
            return scroll
        }

        for subview in view.subviews {
            if let found = findNestedScrollView(in: subview) {
                return found
            }
        }

        return nil
    }

    private enum StoriesRowConfigurationError: LocalizedError {
        case missingCategories

        var errorDescription: String? {
            switch self {
            case .missingCategories:
                return "At least one category or attribute identifier is required to filter the Stories Row."
            }
        }
    }

    private enum InlineStoriesRowError: LocalizedError {
        case missingHostView

        var errorDescription: String? {
            switch self {
            case .missingHostView:
                return "Unable to find a host view to display the inline Stories Row."
            }
        }
    }

    private enum InlineAttachmentMode {
        case overlay
        case scrollContent
    }

    private struct InlineLayoutOptions {
        let top: CGFloat
        let leading: CGFloat
        let trailing: CGFloat
        let height: CGFloat
        let useSafeArea: Bool
        let backgroundColor: UIColor?
        let cornerRadius: CGFloat
        let isHidden: Bool
        let prefersScrollAttachment: Bool
        let documentLeft: CGFloat?
        let documentTop: CGFloat?
        let documentWidth: CGFloat?
        let documentHeight: CGFloat?

        var documentFrame: CGRect? {
            guard let left = documentLeft, let top = documentTop else { return nil }
            let width = documentWidth ?? 0
            let resolvedHeight = documentHeight ?? height
            guard width > 0, resolvedHeight > 0 else { return nil }
            return CGRect(x: left, y: top, width: width, height: resolvedHeight)
        }
    }

    private enum InlineLayoutBuilder {
        static func makeLayout(from options: [String: Any]?) -> InlineLayoutOptions {
            let sanitized = PluginOptionsSanitizer.sanitize(dictionary: options) ?? [:]

            let horizontalPadding = PluginValueParser.double(from: sanitized["horizontalPadding"]) ?? 0
            let top = CGFloat(PluginValueParser.double(from: sanitized["top"] ?? sanitized["y"]) ?? 0)
            let leading = CGFloat(PluginValueParser.double(from: sanitized["left"] ?? sanitized["leading"] ?? sanitized["x"]) ?? horizontalPadding)
            let trailing = CGFloat(PluginValueParser.double(from: sanitized["right"] ?? sanitized["trailing"]) ?? horizontalPadding)
            let height = CGFloat(PluginValueParser.double(from: sanitized["height"]) ?? 220)
            let useSafeArea = PluginValueParser.bool(from: sanitized["useSafeArea"]) ?? true
            let cornerRadius = CGFloat(PluginValueParser.double(from: sanitized["cornerRadius"]) ?? 0)
            let isHidden = PluginValueParser.bool(from: sanitized["hidden"] ?? sanitized["isHidden"]) ?? false
            let prefersScrollAttachment = PluginValueParser.bool(from: sanitized["attachToScrollView"] ?? sanitized["attach_to_scroll_view"] ?? sanitized["scrollAttachment"]) ?? false

            let documentLeft = PluginValueParser.double(from: sanitized["documentLeft"] ?? sanitized["docLeft"] ?? sanitized["contentLeft"])
            let documentTop = PluginValueParser.double(from: sanitized["documentTop"] ?? sanitized["docTop"] ?? sanitized["contentTop"])
            let documentWidth = PluginValueParser.double(from: sanitized["documentWidth"] ?? sanitized["docWidth"] ?? sanitized["width"])
            let documentHeight = PluginValueParser.double(from: sanitized["documentHeight"] ?? sanitized["docHeight"])

            let backgroundColorHex = (sanitized["backgroundColor"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let backgroundColor: UIColor?
            if let hex = backgroundColorHex, !hex.isEmpty {
                backgroundColor = UIColor.from(hexString: hex)
            } else {
                backgroundColor = nil
            }

            return InlineLayoutOptions(
                top: top,
                leading: leading,
                trailing: trailing,
                height: height,
                useSafeArea: useSafeArea,
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                isHidden: isHidden,
                prefersScrollAttachment: prefersScrollAttachment,
                documentLeft: documentLeft.map { CGFloat($0) },
                documentTop: documentTop.map { CGFloat($0) },
                documentWidth: documentWidth.map { CGFloat($0) },
                documentHeight: documentHeight.map { CGFloat($0) }
            )
        }
    }

    private enum PluginOptionsSanitizer {
        static func sanitize(dictionary: [String: Any]?) -> [String: Any]? {
            guard let dictionary = dictionary else { return nil }
            var sanitized: [String: Any] = [:]
            dictionary.forEach { key, value in
                if !(value is NSNull) {
                    sanitized[key] = value
                }
            }
            return sanitized
        }
    }

    private enum PluginValueParser {
        static func int(from value: Any?) -> Int? {
            switch value {
            case let number as NSNumber:
                return number.intValue
            case let string as String:
                return Int(string.trimmingCharacters(in: .whitespacesAndNewlines))
            default:
                return nil
            }
        }

        static func double(from value: Any?) -> Double? {
            switch value {
            case let number as NSNumber:
                return number.doubleValue
            case let string as String:
                return Double(string.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines))
            default:
                return nil
            }
        }

        static func bool(from value: Any?) -> Bool? {
            switch value {
            case let number as NSNumber:
                return number.boolValue
            case let string as String:
                let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if ["true", "1", "yes", "y", "sim"].contains(normalized) { return true }
                if ["false", "0", "no", "n", "nao", "não"].contains(normalized) { return false }
                return nil
            default:
                return nil
            }
        }

    }

    private enum StoriesRowConfigurationBuilder {
        static func makeConfiguration(from options: [String: Any]?) throws -> StorytellerStoriesListConfiguration? {
            guard let options = PluginOptionsSanitizer.sanitize(dictionary: options), !options.isEmpty else {
                return nil
            }

            let categories = extractCategories(from: options)
            guard !categories.isEmpty else {
                throw StoriesRowConfigurationError.missingCategories
            }

            let cellType = cellType(from: options["cellType"] ?? options["cell_type"])
            let displayLimit = PluginValueParser.int(from: options["displayLimit"] ?? options["display_limit"])
            let visibleTiles = PluginValueParser.double(from: options["visibleTiles"] ?? options["visible_tiles"])

            return StorytellerStoriesListConfiguration(
                categories: categories,
                cellType: cellType,
                theme: nil,
                uiStyle: nil,
                displayLimit: displayLimit,
                visibleTiles: visibleTiles
            )
        }

        private static func extractCategories(from options: [String: Any]) -> [String] {
            let candidates: [Any?] = [
                options["categories"],
                options["categoryIds"],
                options["categoryId"],
                options["category"],
                options["attribute"],
                options["attributes"],
                options["attributeId"],
                options["attributeIds"],
                options["filter"],
                options["filters"],
                options["tag"],
                options["tags"]
            ]

            for candidate in candidates {
                let values = normalizeStrings(from: candidate)
                if !values.isEmpty {
                    return values
                }
            }

            return []
        }

        private static func cellType(from value: Any?) -> StorytellerListViewCellType? {
            guard let raw = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !raw.isEmpty else {
                return nil
            }
            return StorytellerListViewCellType(rawValue: raw)
        }

        private static func normalizeStrings(from value: Any?) -> [String] {
            if let strings = value as? [String] {
                return strings.compactMap { trimmed($0) }
            }

            if let array = value as? [Any] {
                return array.compactMap { ($0 as? String).flatMap(trimmed) }
            }

            if let nsArray = value as? NSArray {
                return nsArray.compactMap { ($0 as? String).flatMap(trimmed) }
            }

            if let single = value as? String, let trimmedValue = trimmed(single) {
                return [trimmedValue]
            }

            return []
        }

        private static func trimmed(_ string: String) -> String? {
            let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedString.isEmpty ? nil : trimmedString
        }
    }

}

private extension UIColor {
    static func from(hexString: String) -> UIColor? {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }

        guard hex.count == 6 || hex.count == 8 else { return nil }

        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

        let a, r, g, b: UInt64
        if hex.count == 8 {
            a = (int & 0xFF000000) >> 24
            r = (int & 0x00FF0000) >> 16
            g = (int & 0x0000FF00) >> 8
            b = int & 0x000000FF
        } else {
            a = 255
            r = (int & 0xFF0000) >> 16
            g = (int & 0x00FF00) >> 8
            b = int & 0x0000FF
        }

        return UIColor(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}