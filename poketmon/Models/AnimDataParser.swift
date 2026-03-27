//
//  AnimDataParser.swift
//  poketmon
//
//  AnimData.xml 파서 — Foundation XMLParser 기반
//  ShadowSize + 각 애니메이션의 프레임 크기, 프레임 수, Duration 배열 추출
//

import Foundation

// MARK: - 데이터 구조

/// 개별 애니메이션 정보 (Walk, Idle, Sleep 등)
struct AnimationData {
    let name: String
    let index: Int
    let frameWidth: Int
    let frameHeight: Int
    /// 1/60초 단위 Duration 배열 (프레임마다 다를 수 있음)
    let durations: [Int]

    var frameCount: Int { durations.count }

    /// Duration을 초 단위로 변환
    var durationsInSeconds: [TimeInterval] {
        durations.map { TimeInterval($0) / 60.0 }
    }

    /// 총 애니메이션 재생 시간 (초)
    var totalDuration: TimeInterval {
        durationsInSeconds.reduce(0, +)
    }
}

/// AnimData.xml 전체 파싱 결과
struct AnimData {
    let shadowSize: Int
    let animations: [String: AnimationData]

    func animation(named name: String) -> AnimationData? {
        animations[name]
    }
}

// MARK: - 파서

final class AnimDataParser: NSObject, XMLParserDelegate {

    private var shadowSize: Int = 0
    private var animations: [String: AnimationData] = [:]

    // 파싱 상태
    private var currentElement = ""
    private var currentText = ""
    private var isInAnim = false
    private var isInDurations = false

    // 현재 파싱 중인 Anim 임시 저장
    private var animName = ""
    private var animIndex = 0
    private var animFrameWidth = 0
    private var animFrameHeight = 0
    private var animDurations: [Int] = []

    // MARK: - Public API

    /// 번들 리소스에서 포켓몬 ID로 AnimData.xml 파싱
    static func parse(pokemonID: Int) -> AnimData? {
        guard let url = SpriteSheet.spriteFileURL(pokemonID: pokemonID, fileName: "AnimData.xml") else {
            return nil
        }
        return parse(url: url)
    }

    /// URL에서 AnimData.xml 파싱
    static func parse(url: URL) -> AnimData? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let parser = XMLParser(data: data)
        let delegate = AnimDataParser()
        parser.delegate = delegate
        guard parser.parse() else { return nil }
        return AnimData(shadowSize: delegate.shadowSize, animations: delegate.animations)
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        currentElement = elementName
        currentText = ""

        if elementName == "Anim" {
            isInAnim = true
            animName = ""
            animIndex = 0
            animFrameWidth = 0
            animFrameHeight = 0
            animDurations = []
        } else if elementName == "Durations" {
            isInDurations = true
            animDurations = []
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if elementName == "ShadowSize" && !isInAnim {
            shadowSize = Int(trimmed) ?? 0
        } else if isInAnim {
            switch elementName {
            case "Name":
                animName = trimmed
            case "Index":
                animIndex = Int(trimmed) ?? 0
            case "FrameWidth":
                animFrameWidth = Int(trimmed) ?? 0
            case "FrameHeight":
                animFrameHeight = Int(trimmed) ?? 0
            case "Duration":
                if isInDurations, let val = Int(trimmed) {
                    animDurations.append(val)
                }
            case "Durations":
                isInDurations = false
            case "Anim":
                let data = AnimationData(
                    name: animName,
                    index: animIndex,
                    frameWidth: animFrameWidth,
                    frameHeight: animFrameHeight,
                    durations: animDurations
                )
                animations[animName] = data
                isInAnim = false
            default:
                break
            }
        }

        currentText = ""
    }
}
