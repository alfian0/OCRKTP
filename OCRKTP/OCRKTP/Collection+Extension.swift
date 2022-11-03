//
//  Collection+Extension.swift
//  OCRKTP
//
//  Created by M. Alfiansyah Nur Cahya Putra on 30/10/22.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
