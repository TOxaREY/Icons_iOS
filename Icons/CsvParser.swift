//
//  CsvParser.swift
//  Icons
//

import Foundation

enum CsvParser {

    private static let locationCodes = [
        "Шкаф1", "Шкаф2", "Стеллаж1", "Стеллаж2", "Стеллаж3", "Стеллаж4",
        "Коробка", "Алтарь1", "Храм1", "Алтарь2", "Храм2", "Киот1", "Киот2"
    ]

    private static let defaultDescriptions: [String: String] = [
        "Алтарь1": "Алтарь нижнего храма",
        "Алтарь2": "Алтарь верхнего храма",
        "Киот1": "Коричневый киот для икон из коробки",
        "Киот2": "Черный киот для икон из коробки",
        "Коробка": "Коробка с иконами для киотов",
        "Стеллаж3": "Нижняя полка стеллажа (у облачений)",
        "Стеллаж1": "Верхняя полка стеллажа (у облачений)",
        "Стеллаж2": "Верхняя полка стеллажа",
        "Стеллаж4": "Нижняя полка стеллажа",
        "Храм1": "Нижний храм",
        "Храм2": "Верхний храм",
        "Шкаф1": "Верхняя полка шкафа",
        "Шкаф2": "Нижняя полка шкафа"
    ]

    // Возвращаем кортеж: список элементов и дату изменения
    static func loadIcons() -> (items: [IconItem], lastModifiedDate: String) {
        guard let url = Bundle.main.url(forResource: "icons", withExtension: "csv"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ Ошибка: не удалось найти или прочитать icons.csv")
            return ([], "")
        }

        let rows = parseCsvContent(content)
        var result: [IconItem] = []
        var descriptions = defaultDescriptions
        var currentSheet = ""
        var hasNumberColumn = false
        var lastModifiedDate = ""
        var nextRowIsDate = false

        for row in rows {
            guard !row.isEmpty else { continue }

            let c0 = cell(row, 0)
            let c1 = cell(row, 1)
            let c3 = cell(row, 3)

            // Считывание даты изменения
            if c0.localizedCaseInsensitiveContains("Дата последнего изменения") {
                nextRowIsDate = true
                continue
            }
            if nextRowIsDate {
                if !c0.isEmpty {
                    lastModifiedDate = c0
                }
                nextRowIsDate = false
                continue
            }

            // Маркер вкладки: ### SHEET:Стеллаж1
            if c0.hasPrefix("### SHEET:") {
                currentSheet = c0.replacingOccurrences(of: "### SHEET:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                continue
            }

            // Чтение описаний из шапки
            if currentSheet.isEmpty, descriptions.keys.contains(c0), !c3.isEmpty {
                descriptions[c0] = c3
                continue
            }

            // Заголовок С номером
            if c0.caseInsensitiveCompare("№") == .orderedSame && c1.lowercased().hasPrefix("название") {
                hasNumberColumn = true
                continue
            }

            // Заголовок БЕЗ номера
            if c0.lowercased().hasPrefix("название") && c1.lowercased().hasPrefix("размер") {
                hasNumberColumn = false
                continue
            }

            guard !currentSheet.isEmpty else { continue }

            let locDesc = descriptions[currentSheet] ?? currentSheet

            if hasNumberColumn {
                let title = c1
                guard !title.isEmpty else { continue }

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
                        locationCode: currentSheet,
                        locationDescription: locDesc
                    )
                )
            } else {
                let title = c0
                if !title.isEmpty {
                    let size = cell(row, 1)
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
                            locationCode: currentSheet,
                            locationDescription: locDesc
                        )
                    )
                }
            }
        }

        print("✅ Успешно загружено икон: \(result.count), дата базы: \(lastModifiedDate)")
        return (result, lastModifiedDate)
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
