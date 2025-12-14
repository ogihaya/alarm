import Foundation//userdefaultsを使うために使用
import Combine//ObservableObjectを使うために使用。変更を検知して更新してくれる。

final class AlarmStore: ObservableObject {//ObservableObjectを継承している。これにより、変更を検知して更新してくれる。finalは継承できないすなわちこれ単体で使うことを明記している。
    @Published private(set) var alarms: [Alarm] = []//アラームのリスト。@Publishedは変更を検知して画面を更新してくれる。private(set)は外部からの変更を禁止している。

    private let storageKey = "stored_alarms"//userdefaultsに保存するためのキー。
    private let queue = DispatchQueue(label: "AlarmStoreQueue")//これのおかげで非同期で処理ができ、保存中なども画面がフリーズしない。

    init() {
        load()
        if alarms.isEmpty {
            alarms = [Alarm.sample()]
        }
    }

    func add(_ alarm: Alarm) {
        alarms.append(alarm)
        persist()
    }

    func update(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index] = alarm
        persist()
    }

    func remove(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        persist()
    }

    func toggleEnabled(for alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].enabled.toggle()
        persist()
    }

    private func persist() {
        queue.async {
            do {
                let data = try JSONEncoder().encode(self.alarms)
                UserDefaults.standard.set(data, forKey: self.storageKey)
            } catch {
                print("failed to save alarms: \(error)")
            }
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            alarms = []
            return
        }
        do {
            alarms = try JSONDecoder().decode([Alarm].self, from: data)
        } catch {
            print("failed to load alarms: \(error)")
            alarms = []
        }
    }
}
