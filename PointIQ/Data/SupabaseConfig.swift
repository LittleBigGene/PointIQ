//
//  SupabaseConfig.swift
//  PointIQ
//
//  Created by Jin Cai on 12/24/25.
//

import Foundation

/// Configuration for Supabase connection
struct SupabaseConfig {
    /// Your Supabase project URL
    /// Get this from your Supabase project settings: https://app.supabase.com
    static let supabaseURL = "https://vzbbwraruhzowivytgvl.supabase.co"
    
    /// Your Supabase anon/public API key
    /// Get this from your Supabase project settings: https://app.supabase.com
    static let supabaseKey = "sb_publishable_e3USmheIIydxEs4QHNS33Q_F-jkyRBz"
    
    /// Check if Supabase is configured
    static var isConfigured: Bool {
        return !supabaseURL.isEmpty &&
               !supabaseKey.isEmpty &&
               supabaseURL.contains("supabase.co") &&
               supabaseKey.starts(with: "sb_")
    }
}

