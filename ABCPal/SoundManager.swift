//
//  SoundManager.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import AVFoundation

var audioPlayer: AVAudioPlayer?

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
