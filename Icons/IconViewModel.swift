//
//  IconViewModel.swift
//  Icons
//
//  Created by Alexey Golovanov on 06.10.2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class IconViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var allIcons: [IconItem] = []

    init() {
        self.allIcons = CsvParser.loadIcons()
    }

    var filteredIcons: [IconItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            // По умолчанию сортировка по алфавиту
            return allIcons.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        } else {
            return allIcons
                .filter { $0.searchTarget.contains(query) }
                .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }
}
