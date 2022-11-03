//
//  CGPoint+Extension.swift
//  OCRKTP
//
//  Created by M. Alfiansyah Nur Cahya Putra on 28/10/22.
//

import UIKit

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width,y: self.y * size.height)
    }
}
