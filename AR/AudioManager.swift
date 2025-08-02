import Foundation
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?

    func playBGM(named fileName: String, withExtension ext: String = "mp3") {
        if player?.isPlaying == true {
            player?.stop()
        }
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("❌ BGM file not found: \(fileName).\(ext)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.5
            player?.play()
            print("🎵 BGM started: \(fileName)")
        } catch {
            print("❌ Failed to play BGM: \(error)")
        }
    }

    func stopBGM() {
        player?.stop()
        print("🛑 BGM stopped")
    }
}

