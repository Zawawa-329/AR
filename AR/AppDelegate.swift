// AppDelegate.swift
// AR
//
// Created by owner on 2025/07/29.
//

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // State管理用のObservableObjectを作成 (既存のAppStateをそのまま利用)
        let appState = AppState.shared // シングルトンインスタンスを利用

        // RootViewにappStateを環境オブジェクトとして渡す
        let rootView = RootView()
            .environmentObject(appState)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: rootView)
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}
// AppStateクラスは上記で修正済み
