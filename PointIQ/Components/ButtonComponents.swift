//
//  ButtonComponents.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

// MARK: - View Modifiers

extension View {
    func buttonStyle(isSelected: Bool, cornerRadius: CGFloat = 10) -> some View {
        self
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08)
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
    }
}

// MARK: - Double Tap Handler

struct DoubleTapHandler: ViewModifier {
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var tapTask: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded { _ in
                        tapTask?.cancel()
                        onDoubleTap()
                    }
            )
            .onTapGesture {
                tapTask?.cancel()
                let task = DispatchWorkItem {
                    onSingleTap()
                }
                tapTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
            }
    }
}

extension View {
    func onDoubleTap(singleTap: @escaping () -> Void, doubleTap: @escaping () -> Void) -> some View {
        modifier(DoubleTapHandler(onSingleTap: singleTap, onDoubleTap: doubleTap))
    }
}

// MARK: - Stroke Sequence View
struct StrokeSequenceView: View {
    let serveShortName: String?
    let serveEmoji: String?
    let receiveEmoji: String?
    let rallyEmojis: [String]
    
    private static func extractServeInfo(from serve: ServeType?) -> (shortName: String?, emoji: String?) {
        guard let serve = serve else { return (nil, nil) }
        let emoji = serve.emoji.isEmpty ? nil : serve.emoji
        return (serve.shortName, emoji)
    }
    
    init(serve: ServeType?, receive: ReceiveType?, rallies: [RallyType]) {
        let serveInfo = Self.extractServeInfo(from: serve)
        self.serveShortName = serveInfo.shortName
        self.serveEmoji = serveInfo.emoji
        self.receiveEmoji = receive?.emoji
        self.rallyEmojis = rallies.map { $0.emoji }
    }
    
    init(point: Point) {
        // Extract serve info
        if let serveTypeString = point.serveType,
           let serveType = ServeType(rawValue: serveTypeString) {
            let serveInfo = Self.extractServeInfo(from: serveType)
            self.serveShortName = serveInfo.shortName
            self.serveEmoji = serveInfo.emoji
        } else {
            self.serveShortName = nil
            self.serveEmoji = nil
        }
        
        // Extract receive info - use actual type if available, otherwise fall back to generic fruit emoji
        if let receiveTypeString = point.receiveType,
           let receiveType = ReceiveType(rawValue: receiveTypeString) {
            self.receiveEmoji = receiveType.emoji
        } else {
            // Fall back to generic fruit emoji for older points without receive type data
            self.receiveEmoji = point.strokeTokens.contains(.fruit) ? StrokeToken.fruit.emoji : nil
        }
        
        // Extract rally info - use actual types if available, otherwise fall back to generic animal emoji
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
    
    init(pointData: PointData) {
        // Extract serve info
        if let serveTypeString = pointData.serveType,
           let serveType = ServeType(rawValue: serveTypeString) {
            let serveInfo = Self.extractServeInfo(from: serveType)
            self.serveShortName = serveInfo.shortName
            self.serveEmoji = serveInfo.emoji
        } else {
            self.serveShortName = nil
            self.serveEmoji = nil
        }
        
        // Extract receive info - use actual type if available, otherwise fall back to generic fruit emoji
        if let receiveTypeString = pointData.receiveType,
           let receiveType = ReceiveType(rawValue: receiveTypeString) {
            self.receiveEmoji = receiveType.emoji
        } else {
            // Fall back to generic fruit emoji for older points without receive type data
            let strokeTokens = pointData.strokeTokenValues
            self.receiveEmoji = strokeTokens.contains(.fruit) ? StrokeToken.fruit.emoji : nil
        }
        
        // Extract rally info - use actual types if available, otherwise fall back to generic animal emoji
        if !pointData.rallyTypes.isEmpty {
            self.rallyEmojis = pointData.rallyTypes.compactMap { rallyTypeString in
                RallyType(rawValue: rallyTypeString)?.emoji
            }
        } else {
            // Fall back to generic animal emoji for older points without rally type data
            let strokeTokens = pointData.strokeTokenValues
            let animalTokens = strokeTokens.filter { $0 == .animal }
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
            
            // Receive: emoji
            if let receiveEmoji = receiveEmoji {
                Text(receiveEmoji)
                    .font(.system(size: 18))
            }
            
            // Arrow separator after receive if we have receive and rallies
            if receiveEmoji != nil && !rallyEmojis.isEmpty {
                Text("→")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 14))
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
        .buttonStyle(isSelected: isSelected)
        .onDoubleTap(singleTap: onTap, doubleTap: onDoubleTap)
    }
}

// MARK: - Receive Type Button
struct ReceiveTypeButton: View {
    let receiveType: ReceiveType
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
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
        .aspectRatio(1, contentMode: .fit)
        .buttonStyle(isSelected: isSelected)
        .onDoubleTap(singleTap: onTap, doubleTap: onDoubleTap)
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
            .buttonStyle(isSelected: isSelected)
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
            .buttonStyle(isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

