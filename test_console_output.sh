#!/bin/bash

# Test script to verify console logging in VocabQuizView

echo "Building and running ABCPal in simulator..."
echo "========================================="

# Build the app
xcodebuild -project ABCPal.xcodeproj \
           -scheme ABCPal \
           -sdk iphonesimulator \
           -configuration Debug \
           -derivedDataPath /tmp/ABCPal-build \
           build

if [ $? -eq 0 ]; then
    echo ""
    echo "Build succeeded!"
    echo "To test the console logs:"
    echo "1. Open Xcode and run the app on your device or simulator"
    echo "2. Navigate to the Vocabulary quiz"
    echo "3. Watch the Xcode console for these log messages:"
    echo ""
    echo "Expected logs in VocabQuizView:"
    echo "  🎮 VocabQuizView initialized with language: ..."
    echo "  📱 VocabQuizView appeared"
    echo "  📚 VocabQuiz: Loaded X total words for language: ..."
    echo "  🎯 VocabQuiz: startQuizFlow called, wasInAutoPlay = false"
    echo "  🔊 VocabQuiz: Speaking text/word '...'"
    echo "  ⏰ VocabQuiz: Setting up 30 second inactivity timer"
    echo "  🎯 VocabQuiz AutoPlay: Starting for word '...'"
    echo "  🎯 VocabQuiz: Speaking word '...'"
    echo "  🎯 VocabQuiz: Will spell in 1.5 seconds..."
    echo "  🎯 VocabQuiz: 2-second timer FIRED! Moving to next word"
    echo ""
    echo "If you don't see these logs, there may be an issue with the console output."
else
    echo "Build failed! Please check the error messages above."
fi