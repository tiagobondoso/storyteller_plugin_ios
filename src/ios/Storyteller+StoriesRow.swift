import Foundation
import UIKit
import StorytellerSDK

// MARK: - CDVStoryteller + Stories Row / Inline UI
// This extension groups everything related to the Stories Row views:
// - Modal Stories Row (showStoriesRowView)
// - Inline Stories Row attached to the WebView (show/update/remove)
// Public JS API remains exactly the same.

extension CDVStoryteller {

    // MARK: - Show Stories Row View
    // JS usage: showStoriesRowView(options)
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

    // MARK: - Inline Stories Row

    // JS usage: showStoriesRowInline({ categories: [], layout: { top: 200, height: 220 } })
    @objc(showStoriesRowInline:)
    func showStoriesRowInline(_ command: CDVInvokedUrlCommand) {
        do {
            guard let sanitizedOptions = PluginOptionsSanitizer.sanitize(dictionary: command.argument(at: 0) as? [String: Any]),
                  !sanitizedOptions.isEmpty else {
                throw StoriesRowConfigurationError.missingCategories
            }

            guard let configuration = try StoriesRowConfigurationBuilder.makeConfiguration(from: sanitizedOptions) else {
                throw StoriesRowConfigurationError.missingCategories
            }

            let layoutOptions = sanitizedOptions["layout"] as? [String: Any]
            let layout = InlineLayoutBuilder.makeLayout(from: layoutOptions ?? sanitizedOptions)

            DispatchQueue.main.async {
                do {
                    try self.mountInlineStoriesRow(configuration: configuration, layout: layout)
                    let pluginResult = CDVPluginResult(status: .ok, messageAs: "Inline stories row rendered.")
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                } catch {
                    let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            }
        } catch {
            let pluginResult = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }

    // JS usage: updateStoriesRowInlineLayout({ top: 320, height: 200 })
    @objc(updateStoriesRowInlineLayout:)
    func updateStoriesRowInlineLayout(_ command: CDVInvokedUrlCommand) {
        guard inlineStoriesRowContainer != nil else {
            let pluginResult = CDVPluginResult(status: .error, messageAs: "Inline stories row is not mounted.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        let layoutDictionary = command.argument(at: 0) as? [String: Any]
        let layout = InlineLayoutBuilder.makeLayout(from: layoutDictionary)

        DispatchQueue.main.async {
            self.applyInlineLayout(layout)
            let pluginResult = CDVPluginResult(status: .ok, messageAs: "Inline stories row layout updated.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }

    // JS usage: removeStoriesRowInline()
    @objc(removeStoriesRowInline:)
    func removeStoriesRowInline(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async {
            self.teardownInlineStoriesRow()
            let pluginResult = CDVPluginResult(status: .ok, messageAs: "Inline stories row removed.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }

}
