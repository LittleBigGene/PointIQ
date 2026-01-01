//
//  ReceiveType.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Table tennis receive stroke types with fruit mnemonic tokens
enum ReceiveType: String, Codable, CaseIterable {
    case push = "push"
    case chopBlock = "chop_block"
    case forehandFlick = "forehand_flick"
    case backhandFlick = "backhand_flick"
    case reverseFlick = "reverse_flick"
    case attack = "attack"
    
    var displayName: String {
        switch self {        
        case .push: return "Push"
        case .chopBlock: return "Chop/Block"
        case .forehandFlick: return "Forehand Flick"
        case .backhandFlick: return "Backhand Flick"
        case .reverseFlick: return "Reverse Flick"
        case .attack: return "Attack"
        }
    }
    
    var displayNameJapanese: String {
        switch self {
        case .push: return "ストップ・ツッツキ"
        case .chopBlock: return "チョップ/ブロック"
        case .forehandFlick: return "フォア・フリック"
        case .backhandFlick: return "チキータ・フリック"
        case .reverseFlick: return "いちご・フリック"
        case .attack: return "打たれる"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .push: return "劈长/摆短"
        case .chopBlock: return "削/切/抹"
        case .forehandFlick: return "台内挑打"
        case .backhandFlick: return "霸王拧"
        case .reverseFlick: return "草莓拧"
        case .attack: return "上手抢攻"
        }
    }
    
    var emoji: String {
        switch self {
        case .push: return "🍎" // Apple - basic, controlled defensive stroke
        case .chopBlock: return "🍉" // Watermelon - big and defensive yet fast
        case .forehandFlick: return "🥝" // Kiwi - forehand flick variation
        case .backhandFlick: return "🍌" // Banana - curved, attacking short stroke
        case .reverseFlick: return "🍓" // Strawberry - deceptive, sweet twist
        case .attack: return "🐾" // Animal - aggressive attack received
        }
    }
    
    var fruitName: String {
        switch self {       
        case .push: return "Apple"
        case .chopBlock: return "Watermelon"
        case .forehandFlick: return "Kiwi"
        case .backhandFlick: return "Banana"
        case .reverseFlick: return "Strawberry"
        case .attack: return "Animal"
        }
    }
    
    var spinType: String {
        switch self {
        case .push: return "Underspin"
        case .chopBlock: return "Underspin / Sidespin / Absorb"
        case .forehandFlick: return "Topspin / Sidespin"
        case .backhandFlick: return "Topspin / Sidespin"
        case .reverseFlick: return "Topspin / Sidespin"
        case .attack: return "Aggressive Attack"
        }
    }
    
    var spinTypeJapanese: String {
        switch self {
        case .push: return "下回転"
        case .chopBlock: return "下回転・横回転・吸収"
        case .forehandFlick: return "上回転・ナックル"
        case .backhandFlick: return "上回転・横回転"
        case .reverseFlick: return "上回転・横回転"
        case .attack: return "積極的な攻撃"
        }
    }
    
    var spinTypeChinese: String {
        switch self {
        case .push: return "下旋"
        case .chopBlock: return "下旋 / 侧旋 / 减力"
        case .forehandFlick: return "上旋 / 不转"
        case .backhandFlick: return "上旋 / 侧旋"
        case .reverseFlick: return "上旋 / 侧旋"
        case .attack: return "积极进攻"
        }
    }
    
    var whyItWorks: String {
        switch self {
        case .push: return "Controlled defensive stroke with underspin — fundamental receive technique."
        case .chopBlock: return "Combines heavy underspin with defensive blocking action."
        case .forehandFlick: return "Forehand variation of the flick — attacking stroke with topspin and sidespin."
        case .backhandFlick: return "Backhand variation of the flick — attacking stroke with topspin and sidespin."
        case .reverseFlick: return "Deceptive stroke with reverse spin variation."
        case .attack: return "Received an aggressive, powerful attack from the opponent."
        }
    }
    
    var whyItWorksJapanese: String {
        switch self {
        case .push: return "下回転を伴う制御された守備的ストローク — 基本的なレシーブ技術。"
        case .chopBlock: return "下回転と横回転を組み合わせた守備的なブロック動作。"
        case .forehandFlick: return "フォア・フリック — 上回転またはナックルを伴う攻撃的ストローク。"
        case .backhandFlick: return "チキータ・フリック — 上回転と横回転を伴う攻撃的ストローク。"
        case .reverseFlick: return "逆チキータ・フリック — 逆回転のバリエーションを持つ欺瞞的なストローク。"
        case .attack: return "相手からの積極的で強力な攻撃を受けた。"
        }
    }
    
    var whyItWorksChinese: String {
        switch self {
        case .push: return "带下旋的控制性防守技术 — 基本接发球技术。"
        case .chopBlock: return "结合下旋和防守性挡球动作。"
        case .forehandFlick: return "台内挑打 — 带上旋或不转的进攻技术。"
        case .backhandFlick: return "霸王拧 — 带上旋和侧旋的进攻技术。"
        case .reverseFlick: return "草莓拧 — 带反向旋转变化的拧拉技术。"
        case .attack: return "积极上手、强力进攻。"
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

