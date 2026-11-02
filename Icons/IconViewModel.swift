//
//  IconViewModel.swift
//  Icons
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class IconViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var allIcons: [IconItem] = []
    @Published private(set) var lastModifiedDate: String = ""

    init() {
        let parseResult = CsvParser.loadIcons()
        self.allIcons = parseResult.items
        self.lastModifiedDate = parseResult.lastModifiedDate
    }

    var filteredIcons: [IconItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return allIcons.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        } else {
            return allIcons
                .filter { $0.searchTarget.contains(query) }
                .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }
}
