//
//  RallyType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table tennis rally stroke types with animal mnemonic tokens
enum RallyType: String, Codable, CaseIterable {
    case dragon = "dragon"
    case tiger = "tiger"
    case crane = "crane"
    case tortoise = "tortoise"
    case panda = "panda"
    case snake = "snake"
    
    var displayName: String {
        switch self {
        case .dragon: return "Dragon"
        case .tiger: return "Tiger"
        case .crane: return "Crane"
        case .tortoise: return "Tortoise"
        case .panda: return "Panda"
        case .snake: return "Snake"
        }
    }
    
    var displayNameJapanese: String {
        switch self {
        case .dragon: return "ドラゴン"
        case .tiger: return "タイガー"
        case .crane: return "クレーン"
        case .tortoise: return "カメ"
        case .panda: return "パンダ"
        case .snake: return "ヘビ"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .dragon: return "攻拉撇拐，龙之正手"
        case .tiger: return "侧身抢拉，飞虎扑食"
        case .crane: return "高调弧圈，白鹤亮翅"
        case .tortoise: return "推挡贴防，防守如龟"
        case .panda: return "快带快撕，暴力熊猫"
        case .snake: return "侧拐高球，大蟒地带"
        }
    }
    
    var emoji: String {
        switch self {
        case .dragon: return "🐉" // Dragon - powerful, dominant, Ma Long's signature
        case .tiger: return "🐅" // Tiger - aggressive, step around forehand
        case .crane: return "🦅" // Crane - graceful, slow spinny loop
        case .tortoise: return "🐢" // Tortoise - calm, stable redirection of opponent’s power with precise control
        case .panda: return "🐼" // Panda - powerful, Fan Zhendong's backhand power drive
        case .snake: return "🐍" // Snake - curving, sidespin stroke
        }
    }
    
    var animalName: String {
        switch self {
        case .dragon: return "Dragon"
        case .tiger: return "Tiger"
        case .crane: return "Crane"
        case .tortoise: return "Tortoise"
        case .panda: return "Panda"
        case .snake: return "Snake"
        }
    }
    
    var spinType: String {
        switch self {
        case .dragon: return "Power Drive"
        case .tiger: return "Step Around"
        case .crane: return "Slow Spinny Loop"
        case .tortoise: return "Block / Control"
        case .panda: return "Power Drive"
        case .snake: return "Sidespin"
        }
    }
    
    var spinTypeJapanese: String {
        switch self {
        case .dragon: return "パワードライブ"
        case .tiger: return "ステップアラウンド"
        case .crane: return "スロー回転ループ"
        case .tortoise: return "ブロック / コントロール"
        case .panda: return "パワードライブ"
        case .snake: return "横回転"
        }
    }
    
    var spinTypeChinese: String {
        switch self {
        case .dragon: return "强力拉球"
        case .tiger: return "侧身抢拉"
        case .crane: return "慢速旋转弧圈"
        case .tortoise: return "挡球 / 控制"
        case .panda: return "强力拉球"
        case .snake: return "侧旋"
        }
    }
    
    var whyItWorks: String {
        switch self {
        case .dragon: return "Ma Long's forehand power drive — dominant, powerful, signature stroke."
        case .tiger: return "Step around forehand — aggressive, positioning-based attack."
        case .crane: return "Slow high-arc spinny loop — graceful, controlled, high-spin arc."
        case .tortoise: return "Block — calm, stable redirection of opponent's power with precise control."
        case .panda: return "Fan Zhendong's backhand power drive — powerful, explosive, signature stroke."
        case .snake: return "Sidespin stroke — curving, deceptive, creates unpredictable bounce."
        }
    }
    
    var whyItWorksJapanese: String {
        switch self {
        case .dragon: return "馬龍のフォアハンドパワードライブ — 支配的で強力な、特徴的なストローク。"
        case .tiger: return "ステップアラウンドフォアハンド — 積極的で、ポジショニングベースの攻撃。"
        case .crane: return "スロー高アーク回転ループ — 優雅で制御された、高回転のアーク。"
        case .tortoise: return "ブロック — 冷静で安定した、正確なコントロールによる相手のパワーの方向転換。"
        case .panda: return "樊振東のバックハンドパワードライブ — 強力で爆発的な、特徴的なストローク。"
        case .snake: return "横回転ストローク — 曲がり、欺瞞的で、予測不可能なバウンスを作る。"
        }
    }
    
    var whyItWorksChinese: String {
        switch self {
        case .dragon: return "马龙的正手强力拉球 — 主导、强力、标志性技术。"
        case .tiger: return "侧身正手抢拉 — 积极、基于位置的进攻。"
        case .crane: return "慢速高弧旋转弧圈 — 优雅、控制、高旋转弧线。"
        case .tortoise: return "挡球 — 冷静、稳定，精确控制下改变对手力量方向。"
        case .panda: return "樊振东的反手强力拉球 — 强力、爆发、标志性技术。"
        case .snake: return "侧旋技术 — 弧线、欺骗性，产生不可预测的弹跳。"
        }
    }
    
    func displayName(for language: Language) -> String {
        switch language {
        case .english: return displayName
        case .japanese: return displayNameJapanese
        case .chinese: return displayNameChinese
        }
    }
    
    func spinType(for language: Language) -> String {
        switch language {
        case .english: return spinType
        case .japanese: return spinTypeJapanese
        case .chinese: return spinTypeChinese
        }
    }
    
    func whyItWorks(for language: Language) -> String {
        switch language {
        case .english: return whyItWorks
        case .japanese: return whyItWorksJapanese
        case .chinese: return whyItWorksChinese
        }
    }
}

