//
//  ButtonComponents.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

// MARK: - Stroke Sequence View
struct StrokeSequenceView: View {
    let serveShortName: String?
    let serveEmoji: String?
    let receiveEmoji: String?
    let rallyEmojis: [String]
    
    init(serve: ServeType?, receive: ReceiveType?, rallies: [RallyType]) {
        self.serveShortName = serve?.shortName
        let emoji = serve?.emoji ?? ""
        self.serveEmoji = emoji.isEmpty ? nil : emoji
        self.receiveEmoji = receive?.emoji
        self.rallyEmojis = rallies.map { $0.emoji }
    }
    
    init(point: Point) {
        if let serveTypeString = point.serveType,
           let serveType = ServeType(rawValue: serveTypeString) {
            self.serveShortName = serveType.shortName
            let emoji = serveType.emoji
            self.serveEmoji = emoji.isEmpty ? nil : emoji
        } else {
            self.serveShortName = nil
            self.serveEmoji = nil
        }
        
        self.receiveEmoji = point.strokeTokens.contains(.fruit) ? StrokeToken.fruit.emoji : nil
        
        // Use actual rally types if available, otherwise fall back to generic animal emoji
        if !point.rallyTypes.isEmpty {
            self.rallyEmojis = point.rallyTypes.compactMap { rallyTypeString in
                RallyType(rawValue: rallyTypeString)?.emoji
            }
        } else {
            // Fall back to generic animal emoji for older points without rally type data
            let animalTokens = point.strokeTokens.filter { $0 == .animal }
            self.rallyEmojis = Array(repeating: StrokeToken.animal.emoji, count: animalTokens.count)
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Serve: shortName + emoji
            if let serveShortName = serveShortName {
                Text(serveShortName)
                    .font(.system(size: 14, weight: .bold))
                if let serveEmoji = serveEmoji {
                    Text(serveEmoji)
                        .font(.system(size: 18))
                }
            }
            
            // Arrow separator if we have serve and receive
            if serveShortName != nil && receiveEmoji != nil {
                Text("→")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 14))
            }
            
            // Receive: emoji
            if let receiveEmoji = receiveEmoji {
                Text(receiveEmoji)
                    .font(.system(size: 18))
            }
            
            // Rally: emojis
            if !rallyEmojis.isEmpty {
                HStack(spacing: 4) {
                    ForEach(rallyEmojis.indices, id: \.self) { index in
                        Text(rallyEmojis[index])
                            .font(.system(size: 18))
                    }
                }
            }
        }
    }
}

// MARK: - Serve Type Button
struct ServeTypeButton: View {
    let serveType: ServeType
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var tapTask: DispatchWorkItem?
    
    var body: some View {
        VStack(spacing: 6) {
            Text(serveType.shortName)
                .font(.system(size: 20, weight: .bold))
            Text(serveType.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .aspectRatio(1, contentMode: .fit)
        .background(
            isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    // Double tap - ace serve
                    tapTask?.cancel()
                    onDoubleTap()
                }
        )
        .onTapGesture {
            // Single tap - select serve (with delay to detect double tap)
            tapTask?.cancel()
            let task = DispatchWorkItem {
                onTap()
            }
            tapTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
        }
    }
}

// MARK: - Receive Type Button
struct ReceiveTypeButton: View {
    let receiveType: ReceiveType
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var tapTask: DispatchWorkItem?
    
    var body: some View {
        VStack(spacing: 6) {
            Text(receiveType.emoji)
                .font(.system(size: 20))
            Text(receiveType.displayName)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(
            isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    // Double tap - good receive scoring point
                    tapTask?.cancel()
                    onDoubleTap()
                }
        )
        .onTapGesture {
            // Single tap - select receive (with delay to detect double tap)
            tapTask?.cancel()
            let task = DispatchWorkItem {
                onTap()
            }
            tapTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
        }
    }
}

// MARK: - Rally Type Button
struct RallyTypeButton: View {
    let rallyType: RallyType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(rallyType.emoji)
                    .font(.system(size: 28))
                Text(rallyType.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(16)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Outcome Button
struct OutcomeButton: View {
    let outcome: Outcome
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(outcome.emoji)
                    .font(.system(size: 20))
                Text(outcome.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.85, contentMode: .fit)
            .padding(12)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

