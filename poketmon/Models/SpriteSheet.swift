//
//  SpriteSheet.swift
//  poketmon
//
//  스프라이트 시트에서 개별 프레임 추출 + 8방향 Direction enum
//  시트 구조: 열(Columns) = 프레임, 행(Rows) = 8방향
//

import AppKit

// MARK: - 8방향

/// PMDCollab 8방향 인덱스 (Row 0~7)
enum Direction: Int, CaseIterable {
    case down      = 0  // ↓
    case downRight = 1  // ↘
    case right     = 2  // →
    case upRight   = 3  // ↗
    case up        = 4  // ↑
    case upLeft    = 5  // ↖
    case left      = 6  // ←
    case downLeft  = 7  // ↙

    /// 이동 벡터(dx, dy)에서 가장 가까운 방향 계산
    /// macOS 좌표계: dy > 0 = 위, dy < 0 = 아래
    /// 스프라이트 좌표계: Row 0 = Down (화면상 아래)
    static func from(dx: CGFloat, dy: CGFloat) -> Direction {
        let absDx = abs(dx)
        let absDy = abs(dy)

        let isDiagonal = min(absDx, absDy) > max(absDx, absDy) * 0.4

        if isDiagonal {
            // macOS: dy > 0 = 위 → Up, dy < 0 = 아래 → Down
            if dx > 0 && dy < 0 { return .downRight }
            if dx > 0 && dy > 0 { return .upRight }
            if dx < 0 && dy > 0 { return .upLeft }
            if dx < 0 && dy < 0 { return .downLeft }
        }

        if absDx > absDy {
            return dx > 0 ? .right : .left
        } else {
            return dy < 0 ? .down : .up
        }
    }
}

// MARK: - 스프라이트 시트

/// 하나의 애니메이션 스프라이트 시트에서 추출한 프레임들
struct SpriteSheet {

    /// [방향][프레임인덱스] = CGImage
    let frames: [[CGImage]]
    let frameWidth: Int
    let frameHeight: Int

    /// 특정 방향 + 프레임 인덱스의 이미지
    func frame(direction: Direction, index: Int) -> CGImage? {
        let dir = direction.rawValue
        guard dir < frames.count else { return nil }
        let dirFrames = frames[dir]
        guard !dirFrames.isEmpty else { return nil }
        return dirFrames[index % dirFrames.count]
    }

    // MARK: - 프레임 추출

    /// 스프라이트 시트 이미지에서 개별 프레임 추출
    static func extract(from image: CGImage, animData: AnimationData) -> SpriteSheet? {
        let fw = animData.frameWidth
        let fh = animData.frameHeight
        let frameCount = animData.frameCount
        guard fw > 0, fh > 0, frameCount > 0 else { return nil }

        // 시트에 포함된 방향 수 계산 (보통 8)
        let directionCount = min(image.height / fh, 8)
        guard directionCount > 0 else { return nil }

        var allFrames: [[CGImage]] = []

        for dirIndex in 0..<directionCount {
            var dirFrames: [CGImage] = []
            for frameIndex in 0..<frameCount {
                let rect = CGRect(
                    x: frameIndex * fw,
                    y: dirIndex * fh,
                    width: fw,
                    height: fh
                )
                guard let cropped = image.cropping(to: rect) else { return nil }
                dirFrames.append(cropped)
            }
            allFrames.append(dirFrames)
        }

        // 8방향 미만이면 첫 번째 방향의 프레임으로 채움
        while allFrames.count < 8 {
            allFrames.append(allFrames[0])
        }

        return SpriteSheet(frames: allFrames, frameWidth: fw, frameHeight: fh)
    }

    // MARK: - 이미지 로드

    /// 번들에서 스프라이트 시트 PNG 로드
    static func loadImage(pokemonID: Int, fileName: String) -> CGImage? {
        guard let url = spriteFileURL(pokemonID: pokemonID, fileName: fileName) else {
            return nil
        }
        return loadImage(url: url)
    }

    /// 포켓몬 스프라이트 파일 URL 찾기 (여러 경로 시도)
    static func spriteFileURL(pokemonID: Int, fileName: String) -> URL? {
        let idString = String(format: "%04d", pokemonID)

        // 1순위: subdirectory를 사용한 번들 검색 (folder reference로 설정된 경우)
        if let url = Bundle.main.url(
            forResource: fileName,
            withExtension: nil,
            subdirectory: "Sprites/\(idString)"
        ) {
            return url
        }

        // 2순위: Resources 하위 경로 (folder reference)
        if let url = Bundle.main.url(
            forResource: fileName,
            withExtension: nil,
            subdirectory: "Resources/Sprites/\(idString)"
        ) {
            return url
        }

        // 3순위: 번들 resourceURL에서 직접 경로 탐색
        if let resourceURL = Bundle.main.resourceURL {
            let candidates = [
                resourceURL.appendingPathComponent("Sprites/\(idString)/\(fileName)"),
                resourceURL.appendingPathComponent("Resources/Sprites/\(idString)/\(fileName)"),
            ]
            for url in candidates {
                if FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
            }
        }

        return nil
    }

    /// URL에서 PNG 로드 (nearest-neighbor 보간 비활성화)
    static func loadImage(url: URL) -> CGImage? {
        guard let dataProvider = CGDataProvider(url: url as CFURL) else { return nil }
        return CGImage(
            pngDataProviderSource: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
