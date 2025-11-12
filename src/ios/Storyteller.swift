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
                let result = CDVPluginResult(status: .ok, messageAs: "SDK initialized for user: \(userId)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                print("SDK Init Error: \(error)")
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
}
