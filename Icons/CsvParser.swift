//
//  CsvParser.swift
//  Icons
//

import Foundation

enum CsvParser {

    private static let locationCodes = [
        "Шкаф1", "Шкаф2", "Полка1", "Полка2", "Полка3", "Полка4",
        "Коробка", "Алтарь1", "Храм1", "Алтарь2", "Храм2", "Киот1", "Киот2"
    ]

    private static let defaultDescriptions: [String: String] = [
        "Шкаф1": "Верхняя полка шкафа",
        "Шкаф2": "Нижняя полка шкафа",
        "Полка1": "Верхняя полка стеллажа",
        "Полка2": "Нижняя полка стеллажа",
        "Полка3": "Нижняя полка стеллажа (у облачений)",
        "Полка4": "Верхняя полка стеллажа (у облачений)",
        "Коробка": "Коробка с иконами для киотов",
        "Алтарь1": "Алтарь нижнего храма",
        "Храм1": "Нижний храм",
        "Алтарь2": "Алтарь верхнего храма",
        "Храм2": "Верхний храм",
        "Киот1": "Коричневый киот для икон из коробки",
        "Киот2": "Черный киот для икон из коробки"
    ]

    static func loadIcons() -> [IconItem] {
        guard let url = Bundle.main.url(forResource: "icons", withExtension: "csv"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ Ошибка: не удалось найти или прочитать icons.csv")
            return []
        }

        let rows = parseCsvContent(content)
        var result: [IconItem] = []
        var descriptions = defaultDescriptions

        var sectionIndex = -1
        var hasNumberColumn = true
        var dualTableStartIndex: Int? = nil

        for row in rows {
            guard !row.isEmpty else { continue }

            let c0 = cell(row, 0)
            let c1 = cell(row, 1)
            let c3 = cell(row, 3)

            // Чтение расшифровок из шапки документа
            if sectionIndex == -1, descriptions.keys.contains(c0), !c3.isEmpty {
                descriptions[c0] = c3
                continue
            }

            // 1. Заголовок секции С колонкой "№"
            if c0.caseInsensitiveCompare("№") == .orderedSame && c1.lowercased().hasPrefix("название") {
                sectionIndex += 1
                hasNumberColumn = true
                dualTableStartIndex = nil
                continue
            }

            // 2. Заголовок секции БЕЗ колонки "№"
            if c0.lowercased().hasPrefix("название") && c1.lowercased().hasPrefix("размер") {
                sectionIndex += 1
                hasNumberColumn = false
                // Ищем правую часть сдвоенной таблицы (Киот2 на индексе 10 или 11)
                if let rightIdx = (4..<row.count).first(where: { cell(row, $0).lowercased().hasPrefix("название") }) {
                    dualTableStartIndex = rightIdx
                } else {
                    dualTableStartIndex = nil
                }
                continue
            }

            guard sectionIndex >= 0 else { continue }

            let locCode = sectionIndex < locationCodes.count ? locationCodes[sectionIndex] : "Место \(sectionIndex + 1)"
            let locDesc = descriptions[locCode] ?? locCode

            if hasNumberColumn {
                let title = c1
                guard !title.isEmpty else { continue }

                // Очищаем ".0" после конвертации pandas
                let cleanNum = cleanNumberString(c0)
                let noNum = cleanNum.isEmpty

                let size = cell(row, 2)
                let comment = cell(row, 3)
                let iconType = cell(row, 4)

                result.append(
                    IconItem(
                        displayNumber: cleanNum,
                        hasNoOriginalNumber: noNum,
                        title: title,
                        size: size,
                        comment: comment,
                        iconType: iconType,
                        locationCode: locCode,
                        locationDescription: locDesc
                    )
                )
            } else {
                let title = c0
                if !title.isEmpty {
                    let size = c1
                    let comment = cell(row, 2)
                    let iconType = cell(row, 3)

                    result.append(
                        IconItem(
                            displayNumber: "",
                            hasNoOriginalNumber: true,
                            title: title,
                            size: size,
                            comment: comment,
                            iconType: iconType,
                            locationCode: locCode,
                            locationDescription: locDesc
                        )
                    )
                }

                // Правая сторона сдвоенной таблицы (Киот2)
                if let rIdx = dualTableStartIndex {
                    let rightTitle = cell(row, rIdx)
                    if !rightTitle.isEmpty {
                        let rightSize = cell(row, rIdx + 1)
                        let rightComment = cell(row, rIdx + 2)
                        let rightType = cell(row, rIdx + 3)

                        let rightLocCode = (sectionIndex + 1) < locationCodes.count ? locationCodes[sectionIndex + 1] : "Киот2"
                        let rightLocDesc = descriptions[rightLocCode] ?? rightLocCode

                        result.append(
                            IconItem(
                                displayNumber: "",
                                hasNoOriginalNumber: true,
                                title: rightTitle,
                                size: rightSize,
                                comment: rightComment,
                                iconType: rightType,
                                locationCode: rightLocCode,
                                locationDescription: rightLocDesc
                            )
                        )
                    }
                }
            }
        }

        print("✅ Успешно загружено икон: \(result.count)")
        return result
    }

    private static func cell(_ row: [String], _ index: Int) -> String {
        guard index >= 0 && index < row.count else { return "" }
        return row[index]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanNumberString(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasSuffix(".0") { s = String(s.dropLast(2)) }
        if s.hasSuffix(",0") { s = String(s.dropLast(2)) }
        return s
    }

    private static func parseCsvContent(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false

        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
                                 .replacingOccurrences(of: "\r", with: "\n")

        for char in normalizedText {
            if char == "\"" {
                inQuotes.toggle()
            } else if (char == ";" || char == ",") && !inQuotes {
                currentRow.append(currentField)
                currentField = ""
            } else if char == "\n" && !inQuotes {
                currentRow.append(currentField)
                currentField = ""
                if currentRow.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    rows.append(currentRow)
                }
                currentRow = []
            } else {
                currentField.append(char)
            }
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if currentRow.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                rows.append(currentRow)
            }
        }

        return rows
    }
}
