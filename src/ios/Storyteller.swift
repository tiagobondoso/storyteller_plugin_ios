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

        // MARK: - Show Custom Storyteller List View
    // JS usage: showCustomStorytellerListView(options)
    @objc(showCustomStorytellerListView:)
    func showCustomStorytellerListView(_ command: CDVInvokedUrlCommand) {
        guard let options = command.argument(at: 0) as? [String: Any] else {
            let result = CDVPluginResult(status: .error, messageAs: "Options dictionary is required.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        let categories = options["categories"] as? [String] ?? []
        let cellTypeStr = options["cellType"] as? String ?? "default"
        let themeStr = options["theme"] as? String ?? "default"
        let uiStyleStr = options["uiStyle"] as? String ?? "horizontal"
        let displayLimit = options["displayLimit"] as? Int ?? 10
        let offset = options["offset"] as? Int ?? 0
        let visibleTitles = options["visibleTitles"] as? Bool ?? true
        let context = options["context"] as? String ?? ""

        // Map string to enum case, fallback to .default/.horizontal
        let cellType: StorytellerListViewCellType
        switch cellTypeStr.lowercased() {
        case "compact": cellType = .compact
        case "large": cellType = .large
        default: cellType = .default
        }

        let theme: StorytellerListViewTheme
        switch themeStr.lowercased() {
        case "light": theme = .light
        case "dark": theme = .dark
        default: theme = .default
        }

        let uiStyle: StorytellerListViewUIStyle
        switch uiStyleStr.lowercased() {
        case "vertical": uiStyle = .vertical
        default: uiStyle = .horizontal
        }

        let config = StorytellerListViewConfig(
            categories: categories,
            cellType: cellType,
            theme: theme,
            uiStyle: uiStyle,
            displayLimit: displayLimit,
            offset: offset,
            visibleTitles: visibleTitles,
            context: context
        )

        DispatchQueue.main.async {
            let listVC = StorytellerListViewController(config: config)
            listVC.modalPresentationStyle = .fullScreen
            self.viewController.present(listVC, animated: true, completion: nil)

            let result = CDVPluginResult(status: .ok, messageAs: "Custom Storyteller list view presented.")
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }
}
