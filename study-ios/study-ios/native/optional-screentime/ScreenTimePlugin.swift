import Foundation
import Capacitor
import FamilyControls
import ManagedSettings
import SwiftUI
import UIKit

/// Capacitor plugin "ScreenTime": blocks the apps / websites the user picked (e.g. YouTube)
/// while a focus timer is running. Requires iOS 16+ and the Family Controls capability.
@objc(ScreenTimePlugin)
public class ScreenTimePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ScreenTimePlugin"
    public let jsName = "ScreenTime"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestAuthorization", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pickApps", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startBlocking", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopBlocking", returnType: CAPPluginReturnPromise)
    ]

    private let store = ManagedSettingsStore()
    private var selection = FamilyActivitySelection()
    private let selKey = "st_family_selection"
    private let endKey = "st_block_end"

    override public func load() {
        if let d = UserDefaults.standard.data(forKey: selKey),
           let s = try? JSONDecoder().decode(FamilyActivitySelection.self, from: d) { selection = s }
        clearIfExpired()
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.clearIfExpired() }
    }

    /// Safety net: if the app was killed mid-session, lift the shield once the timer's end time has passed.
    private func clearIfExpired() {
        let end = UserDefaults.standard.double(forKey: endKey)
        if end > 0 && Date().timeIntervalSince1970 * 1000 > end + 2000 {
            store.clearAllSettings()
            UserDefaults.standard.removeObject(forKey: endKey)
        }
    }

    @objc func requestAuthorization(_ call: CAPPluginCall) {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                call.resolve(["authorized": true])
            } catch {
                call.reject("Screen Time permission denied: \(error.localizedDescription)")
            }
        }
    }

    @objc func getStatus(_ call: CAPPluginCall) {
        call.resolve([
            "authorized": AuthorizationCenter.shared.authorizationStatus == .approved,
            "apps": selection.applicationTokens.count,
            "sites": selection.webDomainTokens.count,
            "categories": selection.categoryTokens.count
        ])
    }

    @objc func pickApps(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let vc = self.bridge?.viewController else { return call.reject("No view controller") }
            var host: UIHostingController<PickerView>!
            let view = PickerView(selection: self.selection) { newSel in
                self.selection = newSel
                if let d = try? JSONEncoder().encode(newSel) { UserDefaults.standard.set(d, forKey: self.selKey) }
                host.dismiss(animated: true) { call.resolve() }
            }
            host = UIHostingController(rootView: view)
            vc.present(host, animated: true)
        }
    }

    @objc func startBlocking(_ call: CAPPluginCall) {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else { return call.reject("Not authorized") }
        let end = call.getDouble("endMs") ?? 0
        UserDefaults.standard.set(end, forKey: endKey)
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        call.resolve()
    }

    @objc func stopBlocking(_ call: CAPPluginCall) {
        store.clearAllSettings()
        UserDefaults.standard.removeObject(forKey: endKey)
        call.resolve()
    }
}

struct PickerView: View {
    @State var selection: FamilyActivitySelection
    let onDone: (FamilyActivitySelection) -> Void
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Pick distractions")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { onDone(selection) } }
                }
        }
    }
}
