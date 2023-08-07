//
//  File.swift
//  
//
//  Created by Developer on 06.08.2023.
//

import Foundation

extension String {
        func convertToDict(text: String) -> [String : String] {
            let lines = text.split(separator: "\n")
            var jsonDictionary: [String: String] = [:]
            for line in lines {
                let components = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if components.count == 2 {
                    let key = components[0]
                    let value = components[1]
                    jsonDictionary[key] = value
                }
            }
            return jsonDictionary
        }
}
