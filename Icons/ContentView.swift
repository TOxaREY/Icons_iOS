//
//  ContentView.swift
//  Icons
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = IconViewModel()
    @State private var selectedIcon: IconItem?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.searchText.isEmpty
                     ? "Всего икон в базе: \(viewModel.allIcons.count)"
                     : "Найдено: \(viewModel.filteredIcons.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)

                List(viewModel.filteredIcons) { item in
                    Button {
                        selectedIcon = item
                    } label: {
                        IconRowView(item: item, highlightQuery: viewModel.searchText)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.plain)
            }
            .navigationTitle("Иконы")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Поиск по названию, месту или №...")
            .sheet(item: $selectedIcon) { icon in
                IconDetailSheet(item: icon)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// Строка списка: бейдж + название (с подсветкой букв)
struct IconRowView: View {
    let item: IconItem
    let highlightQuery: String

    private var badgeColor: Color {
        if item.locationCode.hasPrefix("Шкаф") {
            return Color(red: 0.18, green: 0.49, blue: 0.20) // Зеленый (#2E7D32)
        } else if item.locationCode.hasPrefix("Полка") {
            return Color(red: 0.08, green: 0.40, blue: 0.75) // Синий (#1565C0)
        } else if item.locationCode.hasPrefix("Алтарь") || item.locationCode.hasPrefix("Храм") {
            return Color(red: 0.42, green: 0.11, blue: 0.60) // Фиолетовый/Бордовый (#6A1B9A)
        } else {
            return Color(red: 0.00, green: 0.41, blue: 0.36) // Бирюзовый (#00695C)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Плашка с местом и номером (если столбец № был)
            VStack(spacing: 2) {
                if !item.hasNoOriginalNumber && !item.displayNumber.isEmpty {
                    Text("№ \(item.displayNumber)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)

                    Text(item.locationCode)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                } else {
                    Text(item.locationCode)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }
            .frame(width: 76, height: 50)
            .background(badgeColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Только название иконы
            Text(highlightedTitle(item.title, query: highlightQuery))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    private func highlightedTitle(_ text: String, query: String) -> AttributedString {
        var attributed = AttributedString(text)
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return attributed }

        var searchRange = attributed.startIndex..<attributed.endIndex
        while let range = attributed[searchRange].range(of: cleanQuery, options: .caseInsensitive) {
            attributed[range].backgroundColor = Color.cyan.opacity(0.45)
            searchRange = range.upperBound..<attributed.endIndex
        }
        return attributed
    }
}

// Всплывающая карточка с подробной информацией при нажатии
struct IconDetailSheet: View {
    let item: IconItem
    @Environment(\.dismiss) private var dismiss

    private var isFloatingLocation: Bool {
        item.locationCode == "Коробка" || item.locationCode == "Киот1" || item.locationCode == "Киот2"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Основная информация") {
                    DetailRow(
                        icon: "mappin.and.ellipse",
                        title: "Место хранения",
                        value: "\(item.locationCode) — \(item.locationDescription)"
                    )

                    if !item.hasNoOriginalNumber && !item.displayNumber.isEmpty {
                        DetailRow(
                            icon: "number",
                            title: "Порядковый номер",
                            value: "№ \(item.displayNumber)"
                        )
                    }

                    DetailRow(
                        icon: "tag",
                        title: "Тип",
                        value: item.iconType.isEmpty ? "Не указан" : item.iconType
                    )

                    DetailRow(
                        icon: "ruler",
                        title: "Размер",
                        value: item.size.isEmpty ? "Не указан" : item.size
                    )

                    DetailRow(
                        icon: "text.bubble",
                        title: "Комментарий",
                        value: item.comment.isEmpty ? "Нет комментариев" : item.comment
                    )
                }

                if isFloatingLocation {
                    Section {
                        Label(
                            "Иконы из мест «Коробка», «Киот1» и «Киот2» на деле могут перемещаться между этими тремя местами.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }
}
