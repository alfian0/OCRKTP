//
//  String+Extension.swift
//  OCRKTP
//
//  Created by M. Alfiansyah Nur Cahya Putra on 28/10/22.
//

import Foundation

extension String {
    func regex(with pattern: String) -> Bool {
        let range = NSRange(location: 0, length: self.utf16.count)
        let regex = try! NSRegularExpression(pattern: pattern)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
    
    // MARK: Convert String date from backend (UTC) to Local
    func toDate(dateFormat format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ID")
        return formatter.date(from: self)
    }
}
