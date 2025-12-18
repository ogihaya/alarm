import Foundation
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
        try? session.setCategory(.playback, options: [.duckOthers])
        try? session.setActive(true)
    }

    private func loadPlayer() {
        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "caf") ??
                Bundle.main.url(forResource: "alarm", withExtension: "wav") else {
            print("アラーム音源が見つかりません。Resourcesにalarm.caf等を追加してください。")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch {
            print("アラーム音の読み込みに失敗: \(error.localizedDescription)")
            player = nil
        }
    }
}
