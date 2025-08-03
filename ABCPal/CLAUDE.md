# ABCPal Development Guide

## Overview
ABCPal is an educational iOS app that helps children learn the alphabet and vocabulary in English and French through interactive quizzes.

## App Architecture

### Main Components
- **ContentView.swift** - Main navigation controller
- **LanguageSelectionView.swift** - Language selection screen (English/French)
- **LearningTypeSelectionView.swift** - Choose between ABC or Vocabulary learning
- **LetterCaseSelectionView.swift** - Choose uppercase or lowercase letters
- **QuizView.swift** - ABC quiz interface
- **VocabQuizView.swift** - Vocabulary quiz interface
- **SoundManager.swift** - Audio playback utilities

### User Flow
1. Splash screen → Name input (first time only)
2. Language selection (English or French)
3. Learning type selection (ABC uppercase, ABC lowercase, or Vocabulary)
4. Quiz screen with audio feedback
5. Completion celebration when all items are mastered

## Version Management

### IMPORTANT: Updating App Version
When releasing updates to the App Store, you MUST increment the version numbers:

1. **In Xcode Project Settings:**
   - Select the ABCPal project in navigator
   - Select the ABCPal target
   - Go to "General" tab
   - Update **Version** (e.g., 1.0 → 1.1 → 1.2)
   - Update **Build** number (increment by 1)

2. **Version History:**
   - 1.0 - Initial release with ABC learning
   - 1.1 - Added vocabulary learning feature

3. **Common Version Update Errors:**
   - "The train version 'X.X' is closed for new build submissions"
   - "CFBundleShortVersionString must contain a higher version"
   - Solution: Always increment version number before archiving

## App Store Submission Process

1. **Pre-submission Checklist:**
   - [ ] Increment version and build numbers
   - [ ] Test on multiple device sizes
   - [ ] Verify all audio files work
   - [ ] Check text-to-speech in both languages
   - [ ] Run `npm run lint` if applicable
   - [ ] Run `npm run typecheck` if applicable

2. **Build and Archive:**
   ```
   Product → Clean Build Folder
   Product → Archive
   ```

3. **Distribution:**
   - In Organizer: Distribute App → App Store Connect
   - Upload with symbols for crash reports

4. **App Store Connect:**
   - Create new version
   - Add release notes
   - Submit for review

## Vocabulary Files

### File Locations
- **English:** `english_vocab.txt` (73 words)
- **French:** `french_vocab.txt` (105 words)

### Adding New Words
- One word per line
- Keep words age-appropriate (3-6 years)
- Test pronunciation with text-to-speech
- Maintain alphabetical order for easier management

## Testing Commands

### Build Testing
```bash
xcodebuild -project ABCPal.xcodeproj -scheme ABCPal -configuration Debug build
```

### Swift Type Checking
```bash
swiftc -typecheck -sdk $(xcrun --sdk iphoneos --show-sdk-path) -target arm64-apple-ios13.0 *.swift
```

## Key Features

### Mastery System
- Each letter/word must be correctly identified twice
- Progress tracked in memory (not persisted)
- Celebration screen when all items mastered

### Audio Features
- Text-to-speech for all prompts and feedback
- Language-specific voices (en-US, fr-CA)
- Adjustable speech rates for clarity
- Whoosh sound effects for transitions

### Layout Support
- Landscape and portrait orientations
- Adaptive layouts for phones and tablets
- Minimum iOS version: 16.6

## Common Issues & Solutions

### Provisioning Profile Errors
- Ensure Apple Developer account is active
- Accept latest Program License Agreement
- Use "Automatically manage signing" in Xcode

### Build Failures
- Clean build folder before archiving
- Verify all resource files are included in bundle
- Check vocabulary .txt files are in Copy Bundle Resources

### Audio Issues
- Verify AVSpeechSynthesizer has proper language voices
- Check whoosh.wav is included in bundle
- Test on real devices (simulator audio can differ)

## Future Enhancement Ideas
- Persist progress between sessions
- Add more vocabulary categories
- Include simple sentences
- Parent dashboard for progress tracking
- Offline mode improvements
- Additional languages