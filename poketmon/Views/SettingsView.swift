//
//  SettingsView.swift
//  poketmon
//
//  설정 패널 — NSPanel + SwiftUI 구현
//  표시(크기/투명도/표시위치), 행동(속도/빈도/수면), 시스템(자동실행)
//  변경 즉시 반영, UserDefaults 저장
//

import SwiftUI
import AppKit

// MARK: - 설정 윈도우 컨트롤러

final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var panel: NSPanel?

    /// 설정 윈도우 열기 (이미 열려있으면 앞으로 가져오기)
    func open() {
        if let existing = panel, existing.isVisible {
            existing.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKey()
            return
        }

        panel = nil

        let newPanel = NSPanel(
            contentRect: CGRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        newPanel.title = "설정"
        newPanel.hidesOnDeactivate = false
        newPanel.collectionBehavior = [.canJoinAllSpaces]
        newPanel.isMovableByWindowBackground = true
        newPanel.animationBehavior = .utilityWindow
        newPanel.isReleasedWhenClosed = false
        newPanel.delegate = self

        // 포켓몬 현재 위치의 모니터 중앙에 배치
        let petPos = PetManager.shared.stateMachine.position
        let screen = NSScreen.screens.first { $0.frame.contains(petPos) }
            ?? NSScreen.main
            ?? NSScreen.screens.first

        if let screen {
            let visible = screen.visibleFrame
            let size = newPanel.frame.size
            newPanel.setFrameOrigin(CGPoint(
                x: visible.midX - size.width / 2,
                y: visible.midY - size.height / 2
            ))
        }

        newPanel.contentView = NSHostingView(rootView: SettingsView())

        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.panel = newPanel
    }

    /// 설정 윈도우 닫기
    func close() {
        panel?.close()
        panel = nil
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        panel = nil
    }
}

// MARK: - 설정 메인 뷰

struct SettingsView: View {

    var body: some View {
        let settings = PetManager.shared.settingsManager

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    displaySection(settings)
                    behaviorSection(settings)
                    systemSection(settings)
                }
                .padding(20)
            }

            Divider()
            footerButtons(settings)
        }
    }

    // MARK: - 표시 섹션

    @ViewBuilder
    private func displaySection(_ settings: SettingsManager) -> some View {
        SettingsSectionHeader(title: "표시")

        // 크기
        SettingsSliderRow(
            label: "크기",
            value: Binding(
                get: { settings.spriteScale },
                set: { settings.spriteScale = $0 }
            ),
            range: 50...200,
            step: 1,
            minLabel: "50%",
            maxLabel: "200%",
            valueLabel: "\(Int(settings.spriteScale))%"
        )

        // 투명도
        SettingsSliderRow(
            label: "투명도",
            value: Binding(
                get: { settings.opacity },
                set: { settings.opacity = $0 }
            ),
            range: 30...100,
            step: 1,
            minLabel: "투명",
            maxLabel: "불투명",
            valueLabel: "\(Int(settings.opacity))%"
        )

        // 표시 위치
        HStack {
            Text("표시 위치")
                .font(.system(size: 13))
                .frame(width: 70, alignment: .leading)

            Picker("", selection: Binding(
                get: { settings.windowLevelOption },
                set: { settings.windowLevelOption = $0 }
            )) {
                ForEach(WindowLevelOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }

        // 이동 범위
        HStack {
            Text("이동 범위")
                .font(.system(size: 13))
                .frame(width: 70, alignment: .leading)

            Picker("", selection: Binding(
                get: { settings.restrictedMonitorName ?? "" },
                set: { settings.restrictedMonitorName = $0.isEmpty ? nil : $0 }
            )) {
                Text("모든 모니터").tag("")
                ForEach(settings.availableMonitors, id: \.name) { monitor in
                    Text(monitorLabel(monitor)).tag(monitor.name)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
    }

    // MARK: - 행동 섹션

    @ViewBuilder
    private func behaviorSection(_ settings: SettingsManager) -> some View {
        SettingsSectionHeader(title: "행동")

        // 이동 속도
        SettingsStepSliderRow(
            label: "이동 속도",
            value: Binding(
                get: { settings.movementSpeed },
                set: { settings.movementSpeed = $0 }
            ),
            range: 1...5,
            minLabel: "느림",
            maxLabel: "빠름",
            valueLabel: settings.movementSpeedLabel
        )

        // 활동 빈도
        SettingsStepSliderRow(
            label: "활동 빈도",
            value: Binding(
                get: { settings.activityFrequency },
                set: { settings.activityFrequency = $0 }
            ),
            range: 1...5,
            minLabel: "조용함",
            maxLabel: "활발함",
            valueLabel: settings.activityFrequencyLabel
        )

        // 수면까지
        SettingsStepSliderRow(
            label: "수면까지",
            value: Binding(
                get: { settings.sleepTimeout },
                set: { settings.sleepTimeout = $0 }
            ),
            range: 1...10,
            minLabel: "1분",
            maxLabel: "10분",
            valueLabel: "\(settings.sleepTimeout)분"
        )
    }

    // MARK: - 시스템 섹션

    @ViewBuilder
    private func systemSection(_ settings: SettingsManager) -> some View {
        SettingsSectionHeader(title: "시스템")

        Toggle("로그인 시 자동 실행", isOn: Binding(
            get: { settings.autoLaunch },
            set: { settings.autoLaunch = $0 }
        ))
        .font(.system(size: 13))
        .toggleStyle(.checkbox)
    }

    // MARK: - 모니터 레이블

    private func monitorLabel(_ monitor: (name: String, frame: CGRect)) -> String {
        let geo = ScreenGeometry.shared
        guard let primaryFrame = geo.screenFrames.first else { return monitor.name }

        if monitor.frame == primaryFrame {
            return "\(monitor.name) (주 모니터)"
        }
        if monitor.frame.midX < primaryFrame.minX {
            return "\(monitor.name) (왼쪽)"
        } else if monitor.frame.midX > primaryFrame.maxX {
            return "\(monitor.name) (오른쪽)"
        } else if monitor.frame.midY > primaryFrame.maxY {
            return "\(monitor.name) (위)"
        } else {
            return "\(monitor.name) (아래)"
        }
    }

    // MARK: - 하단 버튼

    private func footerButtons(_ settings: SettingsManager) -> some View {
        HStack {
            Button("기본값 복원") {
                settings.resetToDefaults()
            }

            Spacer()

            Button("닫기") {
                SettingsWindowController.shared.close()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - 섹션 헤더

private struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Divider()
        }
    }
}

// MARK: - 슬라이더 행 (연속 값)

private struct SettingsSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let minLabel: String
    let maxLabel: String
    let valueLabel: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13))
                .frame(width: 70, alignment: .leading)

            VStack(spacing: 2) {
                Slider(value: $value, in: range)
                HStack {
                    Text(minLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text(maxLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            Text(valueLabel)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - 스텝 슬라이더 행 (정수 값)

private struct SettingsStepSliderRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let minLabel: String
    let maxLabel: String
    let valueLabel: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13))
                .frame(width: 70, alignment: .leading)

            VStack(spacing: 2) {
                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { value = Int($0.rounded()) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: 1
                )
                HStack {
                    Text(minLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text(maxLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            Text(valueLabel)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 60, alignment: .trailing)
        }
    }
}
