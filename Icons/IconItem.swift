//
//  IconItem.swift
//  Icons
//

import Foundation

struct IconItem: Identifiable, Hashable {
    let id = UUID()
    let displayNumber: String       // Номер из колонки "№" (если есть)
    let hasNoOriginalNumber: Bool   // true — если колонки "№" не было или ячейка пуста
    let title: String               // Название иконы
    let size: String                // Размер
    let comment: String             // Комментарий
    let iconType: String            // Тип
    let locationCode: String        // Код места (Шкаф1, Полка2, Храм1...)
    let locationDescription: String // Полное описание места
    let searchTarget: String        // Поле для регистронезависимого поиска

    init(
        displayNumber: String,
        hasNoOriginalNumber: Bool,
        title: String,
        size: String,
        comment: String,
        iconType: String,
        locationCode: String,
        locationDescription: String
    ) {
        self.displayNumber = displayNumber
        self.hasNoOriginalNumber = hasNoOriginalNumber
        self.title = title
        self.size = size
        self.comment = comment
        self.iconType = iconType
        self.locationCode = locationCode
        self.locationDescription = locationDescription
        self.searchTarget = "\(displayNumber) \(title) \(locationCode) \(locationDescription) \(iconType) \(comment) \(size)".lowercased()
    }
}
