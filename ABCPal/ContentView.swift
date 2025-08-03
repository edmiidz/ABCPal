//
//  ContentView.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var showSplash = true
    @State private var selectedLanguage: String? = nil
    @State private var selectedCase: String? = nil
    @State private var selectedLearningType: String? = nil
    @State private var userName: String = ""
    @State private var showNameInput = false
    
    // Add a state variable to force refresh when username changes
    @State private var userNameRefreshToggle = false
    
    // UserDefaults key for storing the user's name
    private let userNameKey = "userNameKey"
    
    var body: some View {
        if showSplash {
            SplashView(isActive: $showSplash)
                .onDisappear {
                    // Check if userName is already stored
                    if let savedName = UserDefaults.standard.string(forKey: userNameKey), !savedName.isEmpty {
                        userName = savedName
                    } else {
                        showNameInput = true
                    }
                }
        } else if showNameInput {
            NameInputView(userName: $userName, onComplete: {
                // Save the name to UserDefaults
                UserDefaults.standard.set(userName, forKey: userNameKey)
                showNameInput = false
            })
        } else if let lang = selectedLanguage, selectedLearningType == "vocab" {
            VocabQuizView(language: lang, goBack: {
                selectedLearningType = nil
            })
        } else if let lang = selectedLanguage, let casing = selectedCase, selectedLearningType?.starts(with: "abc") == true {
            QuizView(language: lang, letterCase: casing, goBack: {
                selectedCase = nil
            })
        } else if let lang = selectedLanguage, selectedLearningType?.starts(with: "abc") == true {
            LetterCaseSelectionView(language: lang, onCaseSelected: { casing in
                selectedCase = casing
            }, onBack: {
                selectedLearningType = nil
            })
        } else if let lang = selectedLanguage {
            LearningTypeSelectionView(language: lang, onTypeSelected: { type in
                selectedLearningType = type
                if type == "abc_upper" {
                    selectedCase = "upper"
                } else if type == "abc_lower" {
                    selectedCase = "lower"
                }
            }, onBack: {
                selectedLanguage = nil
            })
        } else {
            LanguageSelectionView(onLanguageSelected: { lang in
                selectedLanguage = lang
            }, userName: getCurrentUserName())
            .id(userNameRefreshToggle) // Force view refresh when toggle changes
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserNameChanged"))) { _ in
                // Update username and toggle refresh when notification received
                userName = getCurrentUserName()
                userNameRefreshToggle.toggle()
            }
        }
    }
    
    // Helper function to get current user name from UserDefaults
    func getCurrentUserName() -> String {
        return UserDefaults.standard.string(forKey: userNameKey) ?? "Student"
    }
}
