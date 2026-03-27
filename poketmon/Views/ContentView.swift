//
//  ContentView.swift
//  poketmon
//
//  Phase 1 테스트 뷰 — 스프라이트 시스템 동작 확인용
//

import SwiftUI

struct ContentView: View {
    @State private var animator = SpriteAnimator()
    @State private var dataManager = PokemonDataManager()
    @State private var logMessages: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Phase 1 스프라이트 테스트")
                .font(.title2.bold())

            // 포켓몬 데이터 매니저 상태
            GroupBox("PokemonDataManager") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("전체 포켓몬: \(dataManager.allPokemon.count)종")
                    Text("사용 가능 (스프라이트 보유): \(dataManager.availableIDs.count)종")
                    if let pikachu = dataManager.pokemon(id: 25) {
                        Text("피카츄: \(pikachu.name) \(pikachu.displayNumber) — 타입: \(pikachu.types.joined(separator: ", "))")
                    }
                }
                .font(.system(size: 12, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 스프라이트 애니메이션 표시
            GroupBox("SpriteAnimator") {
                VStack(spacing: 12) {
                    // 현재 프레임 표시
                    HStack(spacing: 20) {
                        VStack {
                            Text("Shadow").font(.caption).foregroundStyle(.secondary)
                            if let shadow = animator.currentShadowFrame {
                                Image(decorative: shadow, scale: 1.0)
                                    .interpolation(.none)
                                    .resizable()
                                    .frame(width: 96, height: 96)
                                    .background(Color.black.opacity(0.1))
                                    .border(Color.gray.opacity(0.3))
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 96, height: 96)
                                    .overlay(Text("없음").font(.caption).foregroundStyle(.secondary))
                            }
                        }

                        VStack {
                            Text("Anim").font(.caption).foregroundStyle(.secondary)
                            if let frame = animator.currentFrame {
                                Image(decorative: frame, scale: 1.0)
                                    .interpolation(.none)
                                    .resizable()
                                    .frame(width: 96, height: 96)
                                    .background(Color.black.opacity(0.1))
                                    .border(Color.gray.opacity(0.3))
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 96, height: 96)
                                    .overlay(Text("미로드").font(.caption).foregroundStyle(.secondary))
                            }
                        }

                        // 합성 미리보기
                        VStack {
                            Text("합성").font(.caption).foregroundStyle(.secondary)
                            ZStack {
                                if let shadow = animator.currentShadowFrame {
                                    Image(decorative: shadow, scale: 1.0)
                                        .interpolation(.none)
                                        .resizable()
                                        .frame(width: 96, height: 96)
                                }
                                if let frame = animator.currentFrame {
                                    Image(decorative: frame, scale: 1.0)
                                        .interpolation(.none)
                                        .resizable()
                                        .frame(width: 96, height: 96)
                                }
                            }
                            .frame(width: 96, height: 96)
                            .background(Color.black.opacity(0.1))
                            .border(Color.gray.opacity(0.3))
                        }
                    }

                    // 상태 정보
                    HStack(spacing: 16) {
                        Text("포켓몬: \(animator.loadedPokemonID)")
                        Text("애니메이션: \(animator.currentAnimation.rawValue)")
                        Text("방향: \(directionLabel(animator.currentDirection))")
                        Text("프레임: \(Int(animator.currentFrameSize.width))x\(Int(animator.currentFrameSize.height))")
                    }
                    .font(.system(size: 11, design: .monospaced))

                    // 애니메이션 전환 버튼
                    HStack(spacing: 8) {
                        Text("애니메이션:").font(.caption)
                        ForEach([AnimationType.idle, .walk, .sleep], id: \.rawValue) { type in
                            Button(type.rawValue) {
                                animator.switchAnimation(to: type)
                                log("\(type.rawValue) 전환")
                            }
                            .buttonStyle(.bordered)
                            .tint(animator.currentAnimation == type ? .blue : nil)
                        }
                        if !animator.availableReactions.isEmpty {
                            Divider().frame(height: 20)
                            Text("Reaction:").font(.caption)
                            ForEach(animator.availableReactions, id: \.rawValue) { type in
                                Button(type.rawValue) {
                                    animator.playOnce(type) {
                                        log("\(type.rawValue) 1회 재생 완료 → Idle")
                                        animator.switchAnimation(to: .idle)
                                    }
                                    log("\(type.rawValue) 1회 재생 시작")
                                }
                                .buttonStyle(.bordered)
                                .tint(.pink)
                            }
                        }
                    }

                    // 방향 전환
                    VStack(spacing: 4) {
                        Text("방향:").font(.caption)
                        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                            GridRow {
                                dirButton(.upLeft, "↖")
                                dirButton(.up, "↑")
                                dirButton(.upRight, "↗")
                            }
                            GridRow {
                                dirButton(.left, "←")
                                Text("●").frame(width: 32, height: 32)
                                    .foregroundStyle(.secondary)
                                dirButton(.right, "→")
                            }
                            GridRow {
                                dirButton(.downLeft, "↙")
                                dirButton(.down, "↓")
                                dirButton(.downRight, "↘")
                            }
                        }
                    }

                    // 속도 배율
                    HStack {
                        Text("속도 배율:").font(.caption)
                        ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { speed in
                            Button("\(speed, specifier: "%.1f")x") {
                                animator.speedMultiplier = speed
                                log("속도 배율: \(speed)x")
                            }
                            .buttonStyle(.bordered)
                            .tint(animator.speedMultiplier == speed ? .orange : nil)
                        }
                    }
                }
            }

            // 로그
            GroupBox("로그") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(logMessages.enumerated()), id: \.offset) { _, msg in
                            Text(msg)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 80)
            }
        }
        .padding(20)
        .frame(width: 600, height: 700)
        .onAppear {
            log("앱 시작")

            // 번들 경로 진단
            if let resourcePath = Bundle.main.resourcePath {
                log("번들 리소스 경로: \(resourcePath)")
            }

            // 번들 내 Sprites 폴더 존재 여부
            if let resourceURL = Bundle.main.resourceURL {
                let spritesDir = resourceURL.appendingPathComponent("Sprites/0025")
                let resSpritesDir = resourceURL.appendingPathComponent("Resources/Sprites/0025")
                let fm = FileManager.default
                log("Sprites/0025 존재: \(fm.fileExists(atPath: spritesDir.path))")
                log("Resources/Sprites/0025 존재: \(fm.fileExists(atPath: resSpritesDir.path))")

                // 번들 루트 파일 목록 (리소스 확인용)
                if let items = try? fm.contentsOfDirectory(atPath: resourceURL.path) {
                    let relevant = items.filter { $0.contains("Sprite") || $0.contains("pokemon") || $0.contains("AnimData") || $0.contains("Resources") || $0.contains("Walk") || $0.contains("Idle") }
                    log("번들 내 관련 항목: \(relevant.isEmpty ? "(없음)" : relevant.joined(separator: ", "))")
                }
            }

            log("포켓몬 데이터: \(dataManager.allPokemon.count)종 로드")
            log("사용 가능: \(dataManager.availableIDs.count)종")

            // AnimData.xml 직접 탐색 테스트
            if let url = SpriteSheet.spriteFileURL(pokemonID: 25, fileName: "AnimData.xml") {
                log("AnimData.xml 발견: \(url.lastPathComponent) at \(url.deletingLastPathComponent().lastPathComponent)")
            } else {
                log("AnimData.xml 찾기 실패!")
            }

            // 피카츄 로드
            animator.load(pokemonID: 25)
            if animator.loadedPokemonID == 25 {
                log("피카츄(#025) 로드 성공!")
                log("프레임 크기: \(Int(animator.currentFrameSize.width))x\(Int(animator.currentFrameSize.height))")
                log("Reaction 가능: \(animator.availableReactions.map(\.rawValue).joined(separator: ", "))")
            } else {
                log("피카츄 로드 실패 — 번들 리소스 구조 확인 필요")
            }
        }
    }

    private func dirButton(_ dir: Direction, _ label: String) -> some View {
        Button(label) {
            animator.setDirection(dir)
        }
        .frame(width: 32, height: 32)
        .buttonStyle(.bordered)
        .tint(animator.currentDirection == dir ? .green : nil)
    }

    private func directionLabel(_ dir: Direction) -> String {
        switch dir {
        case .down: "↓"
        case .downRight: "↘"
        case .right: "→"
        case .upRight: "↗"
        case .up: "↑"
        case .upLeft: "↖"
        case .left: "←"
        case .downLeft: "↙"
        }
    }

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let entry = "[\(formatter.string(from: Date()))] \(message)"
        print("[PokePet] \(message)")  // Xcode 콘솔 출력
        logMessages.append(entry)
        if logMessages.count > 50 {
            logMessages.removeFirst()
        }
    }
}

#Preview {
    ContentView()
}
