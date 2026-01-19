//  StorytellerHandler.swift
import UIKit
import StorytellerSDK

class StorytellerHandler: NSObject, StorytellerDelegate, StorytellerListViewDelegate {
    static let shared = StorytellerHandler()

    private override init() {
        super.init()
        Storyteller.delegate = self
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

    // MARK: - User Activity Analytics (Trivia Quizzes)

    func onUserActivityOccurred(type: StorytellerSDK.UserActivity.EventType,
                                data: StorytellerSDK.UserActivityData) {
        // For debugging and inspection from JS/OutSystems, forward ALL
        // user activity events through the generic event channel.

        let basePayload: [String: Any] = [
            "sdkEventType": String(describing: type),
            "storyId": data.storyId ?? "",
            "pageId": data.pageId ?? "",
            "quizId": data.triviaQuizId ?? "",
            "quizTitle": data.triviaQuizTitle ?? "",
            "questionId": data.triviaQuizQuestionId ?? "",
            "answerId": data.triviaQuizAnswerId ?? "",
            "score": data.triviaQuizScore ?? 0
        ]

        forwardEventToCordova(payload: basePayload)

        // Additionally, keep the more semantic trivia-specific events for convenience.
        switch type {
        case .TriviaQuizQuestionAnswered:
            handleTriviaQuestionAnswered(data: data)
        case .TriviaQuizCompleted:
            handleTriviaQuizCompleted(data: data)
        default:
            break
        }
    }

    private func handleTriviaQuestionAnswered(data: StorytellerSDK.UserActivityData) {
        let userId = Storyteller.currentUserId ?? ""

        let payload: [String: Any] = [
            "eventType": "TriviaQuizQuestionAnswered",
            "userId": userId,
            "quizId": data.triviaQuizId ?? "",
            "quizTitle": data.triviaQuizTitle ?? "",
            "questionId": data.triviaQuizQuestionId ?? "",
            "answerId": data.triviaQuizAnswerId ?? "",
            "storyId": data.storyId ?? "",
            "pageId": data.pageId ?? ""
        ]

        forwardEventToCordova(payload: payload)
    }

    private func handleTriviaQuizCompleted(data: StorytellerSDK.UserActivityData) {
        let userId = Storyteller.currentUserId ?? ""

        let payload: [String: Any] = [
            "eventType": "TriviaQuizCompleted",
            "userId": userId,
            "quizId": data.triviaQuizId ?? "",
            "quizTitle": data.triviaQuizTitle ?? "",
            "score": data.triviaQuizScore ?? 0,
            "storyId": data.storyId ?? "",
            "pageId": data.pageId ?? ""
        ]

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
