//
//  Extensions.swift
//  SHMIDIKit
//
//  Created by WangRex on 11/15/18.
//  Copyright © 2018 WangRex. All rights reserved.
//

import Foundation

extension FloatingPoint {
    func map(start1: Self, stop1: Self, start2: Self, stop2: Self) -> Self {
        return start2 + (stop2 - start2) * ((self - start1) / (stop1 - start1))
    }
}

extension BinaryInteger {
    func map(start1: Self, stop1: Self, start2: Self, stop2: Self) -> Self {
        let s1 = Double(start1)
        let e1 = Double(stop1)
        let s2 = Double(start2)
        let e2 = Double(stop2)
        return Self(s2 + (e2 - s2) * ((Double(self) - s1) / (e1 - s1)))
    }
}
