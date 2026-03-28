//
//  poketmonApp.swift
//  poketmon
//
//  SwiftUI + AppKit 하이브리드 앱 진입점
//  MenuBarExtra (메뉴바 전용) + AppDelegate (투명 윈도우 관리)
//

import SwiftUI

@main
struct poketmonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 메뉴바 아이콘 + 드롭다운 (Phase 5에서 완성)
        MenuBarExtra("PokePet", systemImage: "circle.fill") {
            Text("피카츄 (Pikachu) #025")
                .font(.headline)
            Divider()
            Button("종료") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
