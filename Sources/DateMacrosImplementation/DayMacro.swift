//
//  DayMacro.swift
//  DateMacrosImplementation
//
//  Created by Sven Herzberg on 2024-05-01.
//

import Foundation

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

/// Implementation of the `day` macro, which takes a string literal and produces an instance of `Day` representing the
/// RFC-3339 day of that literal. For example
///
/// ```
/// #day("2024-01-23")
/// ```
///
/// will expand to
///
/// ```
/// Date(timeIntervalSince: )
/// ```
public struct DayMacro: ExpressionMacro {
    private static let argumentTemplate = StringLiteralExprSyntax(content: "<\u{23}YYYY#>-<\u{23}MM#>-<\u{23}DD#>")
    
    private static let formatter: ISO8601DateFormatter = {
        let result = ISO8601DateFormatter()
        result.formatOptions = [
            .withFullDate,
            .withDashSeparatorInDate,
        ]
        return result
    }()
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            throw try DiagnosticsError(diagnostics: [missingArgument(node: node)])
        }
        guard let stringLiteral = argument.as(StringLiteralExprSyntax.self) else {
            throw DiagnosticsError(diagnostics: unsupportedArgumentType(argument))
        }
        guard let first = stringLiteral.segments.first?.as(StringSegmentSyntax.self),
              stringLiteral.segments.first == stringLiteral.segments.last
        else {
            // Maybe it's smarter to check for having `StringSegmentSyntax` only (not `ExpressionSegmentSyntax`).
            // We could still concatenate multiple `StringSegmentSyntax`es and continue with the result.
            throw DiagnosticsError(diagnostics: unsupportedStringInterpolation(argument, in: node))
        }
        guard !first.content.text.isEmpty else {
            throw self.stringLiteral(isEmpty: first.content)
        }
        guard let day = formatter.date(from: first.description) else {
            throw invalidDayError(first)
        }
        let canonical = formatter.string(from: day)
        if canonical != first.description {
            try context.diagnose(invalidDayWarning(first, replacement: canonical))
        }
        return "Date(timeIntervalSinceReferenceDate: \(raw: day.timeIntervalSinceReferenceDate))"
    }
    
    private static func missingArgument (
        node: some FreestandingMacroExpansionSyntax,
        argumentTemplate: StringLiteralExprSyntax? = nil
    ) throws -> Diagnostic {
        try Diagnostic(
            node: node,
            message: MacroExpansionErrorMessage("Missing argument for parameter in macro expansion"),
            fixIt: FixIt(
                message: MacroExpansionFixItMessage("Insert “\(argumentTemplate ?? self.argumentTemplate)”"),
                changes: [
                    .replace(
                        oldNode: Syntax(node),
                        newNode: Syntax(
                            ExprSyntax(validating: """
                            #\(node.macroName)(\(argumentTemplate ?? self.argumentTemplate))
                            """)
                        )
                    )
                ]
            )
        )
    }
    
    private static func stringLiteral (isEmpty stringLiteral: TokenSyntax) -> DiagnosticsError {
        DiagnosticsError(diagnostics: [
            Diagnostic(
                node: Syntax(stringLiteral),
                message: MacroExpansionErrorMessage("String Literal is empty"),
                fixIt: FixIt(
                    message: MacroExpansionFixItMessage("Insert “\(argumentTemplate.segments)”"),
                    changes: [
                        .replace(oldNode: Syntax(stringLiteral), newNode: Syntax(argumentTemplate.segments))
                    ]
                )
            )
        ])
    }
    
    private static func unsupportedArgumentType (_ node: ExprSyntax) -> [Diagnostic] {
        let fallbackType = "\(node.kind.syntaxNodeType)"
        let line = #line
        let typeName = switch node.kind {
        case .integerLiteralExpr:
            "Integer"
        default:
            fallbackType
        }
        return [
            Diagnostic(
                node: node,
                message: MacroExpansionErrorMessage("Invalid type of argument: \(typeName)"),
                notes: typeName != fallbackType ? [] : [
                    Note(
                        node: Syntax(node),
                        message: MacroExpansionNoteMessage("""
                        \(#fileID):\(line + 1): Update type mapping for \(typeName)
                        """)
                    ),
                ]
            )
        ]
    }
    
    private static func unsupportedStringInterpolation (
        _ interpolation: ExprSyntax, in node: some FreestandingMacroExpansionSyntax
    ) -> [Diagnostic] {
        return [
            Diagnostic(
                node: node,
                message: MacroExpansionErrorMessage(
                    "#\(node.macroName)() does not support string interpolation, use a `StaticString` instead."
                )
            )
        ]
    }
    
    private static func invalidDayError (_ node: StringSegmentSyntax) -> DiagnosticsError {
        DiagnosticsError(diagnostics: [
            Diagnostic(
                node: node,
                message: MacroExpansionErrorMessage(warning(invalidDayExpression: node.description))
            )
        ])
    }
    
    private static func warning(invalidDayExpression: String) -> String {
        "Invalid day expression: \(invalidDayExpression)"
    }
    
    private static func invalidDayWarning (_ string: StringSegmentSyntax, replacement: String) throws -> Diagnostic {
        Diagnostic(
            node: string,
            message: MacroExpansionWarningMessage(warning(invalidDayExpression: string.description)),
            fixIt: FixIt(
                message: MacroExpansionFixItMessage("Replace “\(string.description)” with “\(replacement)”"),
                changes: [
                    .replace(
                        oldNode: Syntax(string.content),
                        newNode: Syntax(TokenSyntax.stringSegment(replacement))
                    )
                ]
            )
        )
    }
}

#if swift(>=5.11) || !canImport(SwiftSyntax509)
// 2024-01-27: SwiftSyntax 509.1.1 doesn't have [it](https://github.com/apple/swift-syntax/pull/2330)
// 2024-05-01: SwiftSyntax 510.0.1 doesn't have it; should be available in Swift 6.
#warning("Check if we can remove the workaround below.")
#endif
fileprivate struct MacroExpansionNoteMessage: NoteMessage {
  public var message: String
  public var noteID: SwiftDiagnostics.MessageID {
    .init(domain: "NotSwiftSyntaxMacros", id: "\(Self.self)")
  }

  public init(_ message: String) {
    self.message = message
  }
}
