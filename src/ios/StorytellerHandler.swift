//  StorytellerHandler.swift
import UIKit
import StorytellerSDK

class StorytellerHandler: NSObject, StorytellerDelegate, StorytellerListViewDelegate {
    static let shared = StorytellerHandler()

    /// Weak reference back to the Cordova plugin so we can stream trivia events to JS.
    weak var triviaEventsSink: CDVStoryteller?

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

    // MARK: - User Activity Analytics (Trivia Quizzes POC)

    func onUserActivityOccurred(type: StorytellerSDK.UserActivity.EventType,
                                data: StorytellerSDK.UserActivityData) {
        switch type {
        case .TriviaQuizQuestionAnswered:
            logTriviaQuestionAnswered(data: data)
        case .TriviaQuizCompleted:
            logTriviaQuizCompleted(data: data)
        default:
            break
        }
    }

    private func logTriviaQuestionAnswered(data: StorytellerSDK.UserActivityData) {
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

        triviaEventsSink?.sendTriviaEventToJS(payload)
    }

    private func logTriviaQuizCompleted(data: StorytellerSDK.UserActivityData) {
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

        triviaEventsSink?.sendTriviaEventToJS(payload)
    }
}
