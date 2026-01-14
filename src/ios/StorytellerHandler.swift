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
}
