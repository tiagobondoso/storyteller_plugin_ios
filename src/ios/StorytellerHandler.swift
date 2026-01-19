//  StorytellerHandler.swift
import UIKit
import StorytellerSDK

class StorytellerHandler: NSObject, StorytellerDelegate, StorytellerListViewDelegate {
    static let shared = StorytellerHandler()

    private override init() {
        super.init()
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
        // Forward ALL user activity events to JS, with minimal shaping so you
        // can inspect them on the OutSystems side.

    var payload: [String: Any] = [:]

    // Tag as a raw user-activity event coming from the SDK
    payload["type"] = "user_activity_raw"
    payload["sdkEventType"] = String(describing: type)

        // Basic story/page identifiers
        if let storyId = data.storyId { payload["storyId"] = storyId }
        if let pageId = data.pageId { payload["pageId"] = pageId }

        // Trivia-related fields (may be nil for non-trivia events)
        if let quizId = data.triviaQuizId { payload["quizId"] = quizId }
        if let quizTitle = data.triviaQuizTitle { payload["quizTitle"] = quizTitle }
        if let questionId = data.triviaQuizQuestionId { payload["questionId"] = questionId }
        if let answerId = data.triviaQuizAnswerId { payload["answerId"] = answerId }
        if let score = data.triviaQuizScore { payload["score"] = score }

        forwardEventToCordova(payload: payload)
    }

    private func forwardEventToCordova(payload: [String: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("StorytellerGenericEvent"),
            object: nil,
            userInfo: payload
        )
    }

}
