
// StorytellerPlugin.swift
import Foundation
import StorytellerSDK

@objc(CDVStoryteller)
class CDVStoryteller: CDVPlugin {

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
                let result = CDVPluginResult(status: .ok, messageAs: "Storyteller SDK initialized for user: \(userId)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                print("Storyteller SDK Init Error: \(error)")
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
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

    // MARK: - User locale
    // JS usage: setLocale(localeString)
    @objc(setLocale:)
    func setLocale(_ command: CDVInvokedUrlCommand) {
        // locale may be nil to clear
        let localeArg = command.argument(at: 0) as? String

        Task { @MainActor in
            do {
                // Storyteller.user is available from SDK; setLocale is synchronous
                Storyteller.user.setLocale(localeArg)

                let result = CDVPluginResult(status: .ok, messageAs: "Locale set")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                // setLocale doesn't throw, but keep defensive handling
                print("setLocale error: \(error)")
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    // MARK: - User customization (custom attributes)
    // JS usage: setUserCustomAttribute(key, value)
    @objc(setUserCustomAttribute:)
    func setUserCustomAttribute(_ command: CDVInvokedUrlCommand) {
        guard let key = command.argument(at: 0) as? String, !key.isEmpty,
              let value = command.argument(at: 1) as? String else {
            let result = CDVPluginResult(status: .error, messageAs: "Key and value are required.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            Storyteller.user.setCustomAttribute(key: key, value: value)
            let result = CDVPluginResult(status: .ok, messageAs: "Attribute set")
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    // JS usage: removeUserCustomAttribute(key)
    @objc(removeUserCustomAttribute:)
    func removeUserCustomAttribute(_ command: CDVInvokedUrlCommand) {
        guard let key = command.argument(at: 0) as? String, !key.isEmpty else {
            let result = CDVPluginResult(status: .error, messageAs: "Key is required.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            Storyteller.user.removeCustomAttribute(key: key)
            let result = CDVPluginResult(status: .ok, messageAs: "Attribute removed")
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }


    // MARK: - User customization (followed categories)
    // JS usage: addFollowedCategory(categoryId)
    @objc(addFollowedCategory:)
    func addFollowedCategory(_ command: CDVInvokedUrlCommand) {
        guard let category = command.argument(at: 0) as? String, !category.isEmpty else {
            let result = CDVPluginResult(status: .error, messageAs: "Category is required.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            Storyteller.user.addFollowedCategory(category)
            let result = CDVPluginResult(status: .ok, messageAs: "Category added")
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    // JS usage: addFollowedCategories(arrayOfCategoryIds)
    @objc(addFollowedCategories:)
    func addFollowedCategories(_ command: CDVInvokedUrlCommand) {
        guard let categories = command.argument(at: 0) as? [String], !categories.isEmpty else {
            let result = CDVPluginResult(status: .error, messageAs: "Categories array is required.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            Storyteller.user.addFollowedCategories(categories)
            let result = CDVPluginResult(status: .ok, messageAs: "Categories added")
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    // JS usage: removeFollowedCategory(categoryId)
    @objc(removeFollowedCategory:)
    func removeFollowedCategory(_ command: CDVInvokedUrlCommand) {
        guard let category = command.argument(at: 0) as? String, !category.isEmpty else {
            let result = CDVPluginResult(status: .error, messageAs: "Category is required.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            Storyteller.user.removeFollowedCategory(category)
            let result = CDVPluginResult(status: .ok, messageAs: "Category removed")
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    // JS usage: removeFollowedCategories(arrayOfCategoryIds)
    @objc(removeFollowedCategories:)
    func removeFollowedCategories(_ command: CDVInvokedUrlCommand) {
        guard let categories = command.argument(at: 0) as? [String], !categories.isEmpty else {
            let result = CDVPluginResult(status: .error, messageAs: "Categories array is required.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        Task { @MainActor in
            Storyteller.user.addFollowedCategories(categories)
            let result = CDVPluginResult(status: .ok, messageAs: "Categories added")
            self.commandDelegate.send(result, callbackId: command.callbackId)
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

    // MARK: - Show Stories Row View
    // JS usage: showStoriesRowView()
    @objc(showStoriesRowView:)
    func showStoriesRowView(_ command: CDVInvokedUrlCommand) {
        do {
            let options = command.argument(at: 0) as? [String: Any]
            let configuration = try StoriesRowConfigurationBuilder.makeConfiguration(from: options)

            DispatchQueue.main.async {
                let vc = StoriesRowViewController(configuration: configuration)
                vc.modalPresentationStyle = .fullScreen
                self.viewController.present(vc, animated: true, completion: nil)

                let pluginResult = CDVPluginResult(status: .ok, messageAs: "Stories row view presented.")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        } catch {
            let pluginResult = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }

    // Private UIViewController to host StorytellerStoriesRowView
    private class StoriesRowViewController: UIViewController {
        private let configuration: StorytellerStoriesListConfiguration?
        private let storiesRowView = StorytellerStoriesRowView()
        private let storytellerDelegate = StorytellerHandler()

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

    private enum StoriesRowConfigurationError: LocalizedError {
        case missingCategories

        var errorDescription: String? {
            switch self {
            case .missingCategories:
                return "At least one category or attribute identifier is required to filter the Stories Row."
            }
        }
    }

    private enum StoriesRowConfigurationBuilder {
        static func makeConfiguration(from options: [String: Any]?) throws -> StorytellerStoriesListConfiguration? {
            guard let options = sanitize(dictionary: options), !options.isEmpty else {
                return nil
            }

            let categories = extractCategories(from: options)
            guard !categories.isEmpty else {
                throw StoriesRowConfigurationError.missingCategories
            }

            let cellType = cellType(from: options["cellType"] ?? options["cell_type"])
            let displayLimit = intValue(from: options["displayLimit"] ?? options["display_limit"])
            let visibleTiles = doubleValue(from: options["visibleTiles"] ?? options["visible_tiles"])

            return StorytellerStoriesListConfiguration(
                categories: categories,
                cellType: cellType,
                theme: nil,
                uiStyle: nil,
                displayLimit: displayLimit,
                visibleTiles: visibleTiles
            )
        }

        private static func sanitize(dictionary: [String: Any]?) -> [String: Any]? {
            guard let dictionary = dictionary else { return nil }
            var sanitized: [String: Any] = [:]
            dictionary.forEach { key, value in
                if !(value is NSNull) {
                    sanitized[key] = value
                }
            }
            return sanitized
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

        private static func intValue(from value: Any?) -> Int? {
            switch value {
            case let number as NSNumber:
                return number.intValue
            case let string as String:
                return Int(string.trimmingCharacters(in: .whitespacesAndNewlines))
            default:
                return nil
            }
        }

        private static func doubleValue(from value: Any?) -> Double? {
            switch value {
            case let number as NSNumber:
                return number.doubleValue
            case let string as String:
                return Double(string.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines))
            default:
                return nil
            }
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
