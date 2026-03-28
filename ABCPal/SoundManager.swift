//
//  SoundManager.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import AVFoundation

var audioPlayer: AVAudioPlayer?

/// Get a TTS voice for the given language code, with fallbacks
func voiceForLanguage(_ language: String) -> AVSpeechSynthesisVoice? {
    // Try exact match first (e.g. "ja-JP", "en-US", "fr-CA")
    if let voice = AVSpeechSynthesisVoice(language: language) {
        return voice
    }
    // Try base language code (e.g. "ja", "en", "fr")
    let base = String(language.prefix(2))
    if let voice = AVSpeechSynthesisVoice(language: base) {
        return voice
    }
    // Last resort: find any installed voice for this language
    let allVoices = AVSpeechSynthesisVoice.speechVoices()
    if let voice = allVoices.first(where: { $0.language.hasPrefix(base) }) {
        return voice
    }
    return nil
}

func playWhooshSound() {
    print("Attempting to play whoosh sound...")  // DEBUG LINE

    guard let url = Bundle.main.url(forResource: "whoosh", withExtension: "wav") else {
        print("❌ Whoosh sound file not found in bundle.")
        return
    }

    do {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        print("✅ Whoosh sound should be playing.")
    } catch {
        print("❌ Error playing whoosh: \(error.localizedDescription)")
    }
}
