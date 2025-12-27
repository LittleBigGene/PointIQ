//
//  ButtonComponents.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import SwiftUI

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
            VStack(spacing: 6) {
                Text(rallyType.emoji)
                    .font(.system(size: 20))
                Text(rallyType.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
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

