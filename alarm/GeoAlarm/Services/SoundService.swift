import Foundation
import Combine
import AVFoundation
import AudioToolbox

/// アラームサウンドの再生を担当
final class SoundService: ObservableObject {
    private var player: AVAudioPlayer?

    func startLoop() {
        configureSession()
        if player == nil {
            loadPlayer()
        }
        player?.numberOfLoops = -1
        player?.play()

        // バンドルに音源がない場合の簡易フォールバック
        if player == nil {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }

    func stop() {
        player?.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // バックグラウンド再生のため、.playbackカテゴリを使用
        // .mixWithOthersオプションを追加して、他のオーディオと混在可能にする
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func loadPlayer() {
        // 音源ファイルを順に検索
        guard let url = Bundle.main.url(forResource: "Clock-Alarm04-01_Mid_", withExtension: "caf") ??
                Bundle.main.url(forResource: "alarm", withExtension: "caf") ??
                Bundle.main.url(forResource: "alarm", withExtension: "wav") else {
            print("アラーム音源が見つかりません。Resourcesに音源ファイルを追加してください。")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        } catch {
            print("アラーム音の読み込みに失敗: \(error.localizedDescription)")
            player = nil
        }
    }
}
