// Storyteller+User.swift
// CDVStoryteller extension for user/profile related operations (locale, attributes, categories)

import Foundation
import StorytellerSDK

// MARK: - CDVStoryteller + User / Profile configuration
// This extension groups all user-related operations: locale, custom attributes,
// and followed categories. Public JS API remains the same.

extension CDVStoryteller {

    // MARK: - User locale
    // JS usage: setLocale(localeString)
    @objc(setLocale:)
    func setLocale(_ command: CDVInvokedUrlCommand) {
        // locale may be nil to clear
        let localeArg = command.argument(at: 0) as? String

        Task { @MainActor in
            do {
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

}
