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
        case .dragon: return "龍"
        case .tiger: return "虎"
        case .crane: return "鶴"
        case .tortoise: return "亀"
        case .panda: return "パンダ"
        case .snake: return "蛇"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .dragon: return "青龙"
        case .tiger: return "白虎"
        case .crane: return "朱雀"
        case .tortoise: return "玄武"
        case .panda: return "熊猫"
        case .snake: return "蟒蛇"
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
        case .dragon: return "フォアハンドドライブ"
        case .tiger: return "回り込み"
        case .crane: return "スロートップスピンリフト"
        case .tortoise: return "止める"
        case .panda: return "バックハンドドライブ"
        case .snake: return "変化球"
        }
    }
    
    var spinTypeChinese: String {
        switch self {
        case .dragon: return "正手输出"
        case .tiger: return "移动输出"
        case .crane: return "球速慢，高旋轉"
        case .tortoise: return "擋球，控制"
        case .panda: return "反手输出"
        case .snake: return "側拐高球"
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
        case .dragon: return "攻拉撇拐，龍之正手 — 馬龍的正手強力拉球，主導、強力、標誌性技術。"
        case .tiger: return "側身搶拉，饿虎撲食 — 積極、基於位置的進攻。"
        case .crane: return "加转弧圈，朱雀展翅 — 高吊弧圈球，優雅、控制、高旋轉弧線。"
        case .tortoise: return "推擋貼防，穩如泰山 — 冷靜、穩定，精確控制下改變對手力量方向。"
        case .panda: return "快帶快撕，暴力熊貓 — 樊振東的反手強力拉球，強力、爆發、標誌性技術。"
        case .snake: return "側拐高球，大蟒地帶 — 側旋技術，弧線、欺騙性，產生不可預測的彈跳。"
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

