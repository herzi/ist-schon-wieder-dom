//
//  ist_schon_wieder_dom.swift
//  ist-schon-wieder-dom
//
//  Created by Sven Herzberg on 2024-05-01.
//

import Foundation

import ArgumentParser
import DateMacros

@main
struct ist_schon_wieder_dom: ParsableCommand {
    typealias Period = (firstDay: Date, firstDayAfter: Date)
    
    static let schedule = [
        // Spring Dom 2024
        Period(firstDay: #day("2024-03-21"), firstDayAfter: #day("2024-04-22")),
        // Summer Dom 2024
        Period(firstDay: #day("2024-07-26"), firstDayAfter: #day("2024-08-26")),
        // Winter Dom 2024
        Period(firstDay: #day("2024-11-08"), firstDayAfter: #day("2024-12-09")),
    ]
    
    func currentPeriod (now: Date = .init()) throws -> Period? {
        guard let next = Self.schedule.first(where: { $1 > now }) else {
            print("Could not find any period in the future.  Code seems to be outdated.")
            throw ExitCode(ENOTSUP)
        }
        return next.firstDay < now ? next : nil
    }
    
    mutating func run() throws {
        if try currentPeriod() != nil {
            print("Yes.  Enjoy Dom! 🎠")
        } else {
            print("No.  You'll have to wait for it.")
        }
    }
}
