//
//  GameLoop.swift
//  poketmon
//
//  DispatchSourceTimer 기반 게임 루프 (30fps)
//  매 프레임: 상태 머신 업데이트 + 위치 갱신
//

import AppKit

final class GameLoop {

    /// 프레임 업데이트 콜백
    var onUpdate: (() -> Void)?

    private var timer: DispatchSourceTimer?
    private var isPaused = false

    /// 30fps 게임 루프 시작
    func start() {
        guard timer == nil else { return }
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(deadline: .now(), repeating: 1.0 / 30.0)
        source.setEventHandler { [weak self] in
            guard let self, !self.isPaused else { return }
            self.onUpdate?()
        }
        timer = source
        source.resume()
    }

    /// 루프 정지
    func stop() {
        timer?.cancel()
        timer = nil
    }

    /// 일시정지
    func pause() {
        isPaused = true
    }

    /// 재개
    func resume() {
        isPaused = false
    }

    deinit {
        stop()
    }
}
