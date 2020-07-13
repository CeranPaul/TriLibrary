//
//  NegativeAccuracyError.swift
//  ArcHammer
//
//  Created by Paul Hollingshead on 5/22/20.
//  Copyright © 2020 Paul Hollingshead. All rights reserved.
//

import Foundation

public class NegativeAccuracyError: Error {
    
    var acc: Double
    
    var description: String {
        return "Accuracy must be a positive number: " + String(describing: self.acc) }
    
    public init(acc: Double)   {
        self.acc = acc
    }
        
}
