import Foundation
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?
    private var currentBGMName: String?

    func playBGM(named fileName: String, withExtension ext: String = "mp3") {
        if currentBGMName == fileName && player?.isPlaying == true {
            // 同じ曲が再生中なら何もしない
            print("🔁 BGM already playing: \(fileName)")
            return
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
            currentBGMName = fileName
            print("🎵 BGM started: \(fileName)")
        } catch {
            print("❌ Failed to play BGM: \(error)")
        }
    }

    func stopBGM() {
        player?.stop()
        currentBGMName = nil
        print("🛑 BGM stopped")
    }
    
    func playSE(named fileName: String, withExtension ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("❌ SE file not found: \(fileName).\(ext)")
            return
        }

        do {
            let sePlayer = try AVAudioPlayer(contentsOf: url)
            sePlayer.volume = 1.0
            sePlayer.play()

            // SEプレイヤーを一時保持（スコープ外で解放されないよう）
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // 明示的に参照を解放（SEの長さに応じて調整）
            }

        } catch {
            print("❌ Failed to play SE: \(error)")
        }
    }

}

