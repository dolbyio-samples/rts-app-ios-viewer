//
//  File.swift
//  
//
//  Created by Raveendran, Aravind on 12/5/2023.
//

import Foundation

public enum StreamError: Error, Equatable {
    case subscribeFailed(reason: String)
    case connectFailed(reason: String)
    case signalling(reason: String)
}
