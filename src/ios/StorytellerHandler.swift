//  StorytellerHandler.swift
import UIKit
import StorytellerSDK

class StorytellerHandler: NSObject, StorytellerDelegate, StorytellerListViewDelegate {
    // Singleton used across the plugin to register Storyteller delegates once
    static let shared = StorytellerHandler()

    private override init() {
    super.init()

    // Register this handler as the global Storyteller delegate so we receive
    // player events and user activity callbacks from the native SDK.
    Storyteller.delegate = self

    // Emit a debug event so JS can confirm handler initialization and delegate registration
        NotificationCenter.default.post(
            name: Notification.Name("StorytellerGenericEvent"),
            object: nil,
            userInfo: [
                "type": "native_debug",
                "message": "StorytellerHandler initialized and delegate set"
            ]
        )
    }
    
    func onPlayerPresented() {
        print("🎥 Storyteller Player Presented")
    }
    
    func onPlayerDismissed() {
        print("📴 Storyteller Player Dismissed")
    }
    
    func userNavigatedToApp(url: String) {
        print("🔗 User navigated to: \(url)")
    }
    
    func onDataLoadStarted() {
        print("⏳ Storyteller data loading started...")
    }
    
    func onDataLoadComplete(success: Bool, error: Error?, dataCount: Int) {
        if success {
            print("✅ Data loaded successfully! \(dataCount) stories available.")
            if dataCount == 0 {
                print("⚠️ No stories available. Check API content.")
            }
        } else if let error = error {
            print("❌ Error loading stories: \(error.localizedDescription)")
        }
    }

    // MARK: - User Activity Analytics (forward everything)

    func onUserActivityOccurred(type: StorytellerSDK.UserActivity.EventType,
                                data: StorytellerSDK.UserActivityData) {
        // Called by Storyteller SDK whenever a user-activity event occurs
        // (e.g. story opened, trivia quiz answered, poll answered, share, etc.).
        // We translate the strongly-typed Swift object into a flat JSON-friendly
        // dictionary and forward it to the Cordova layer so JS / OutSystems
        // can process or persist the analytics on the client.
        var payload: [String: Any] = [:]

    // Required base fields shared across all events
        payload["type"] = "user_activity_raw"
        payload["sdkEventType"] = String(describing: type)

    // Story / page identifiers – minimal core identifiers used for joins
        if let storyId = data.storyId { payload["storyId"] = storyId }
        if let pageId = data.pageId { payload["pageId"] = pageId }

    // Trivia-related (documentation-style names from official Storyteller docs)
        if let triviaQuizId = data.triviaQuizId { payload["triviaQuizId"] = triviaQuizId }
        if let triviaQuizTitle = data.triviaQuizTitle { payload["triviaQuizTitle"] = triviaQuizTitle }
        if let triviaQuizQuestionId = data.triviaQuizQuestionId { payload["triviaQuizQuestionId"] = triviaQuizQuestionId }
        if let triviaQuizAnswerId = data.triviaQuizAnswerId { payload["triviaQuizAnswerId"] = triviaQuizAnswerId }
        if let triviaQuizScore = data.triviaQuizScore { payload["triviaQuizScore"] = triviaQuizScore }

    // Categories / categoryDetails - best-effort mapping from SDK data
        // "categories" can be a simple identifier or array, depending on what SDK exposes
        if let categoryId = data.categoryId {
            // Expose a single category id both as a scalar and inside an array
            payload["categories"] = [categoryId]
        }

        // If SDK exposes richer category information, map it to "categoryDetails"
        // (placeholder: only id/name if available on this version of the SDK)
        var categoryDetails: [String: Any] = [:]
        if let categoryId = data.categoryId { categoryDetails["id"] = categoryId }
        if let categoryName = data.categoryName { categoryDetails["name"] = categoryName }
        if !categoryDetails.isEmpty {
            payload["categoryDetails"] = categoryDetails
        }

    // storyIndex (position within a list/row) if SDK provides it
        if let storyIndex = data.storyIndex {
            payload["storyIndex"] = storyIndex
        } else if let pageIndex = data.pageIndex {
            // Fallback: expose pageIndex as storyIndex if nothing better exists
            payload["storyIndex"] = pageIndex
        }

    // openedReason / actionText / shareMethod / pollAnswerId
    // Additional context for why/how the story was opened or interacted with.
        if let openedReason = data.openedReason {
            payload["openedReason"] = openedReason
        }
        if let actionText = data.actionText {
            payload["actionText"] = actionText
        }
        if let shareMethod = data.shareMethod {
            payload["shareMethod"] = shareMethod
        }
        if let pollAnswerId = data.pollAnswerId {
            payload["pollAnswerId"] = pollAnswerId
        }

        forwardEventToCordova(payload: payload)
    }

    private func forwardEventToCordova(payload: [String: Any]) {
        // Bridge from native (delegate) to Cordova plugin using NotificationCenter.
        // CDVStoryteller listens for the "StorytellerGenericEvent" notification,
        // picks up the payload and pushes it to the long-lived JS callback.
        NotificationCenter.default.post(
            name: Notification.Name("StorytellerGenericEvent"),
            object: nil,
            userInfo: payload
        )
    }

}
