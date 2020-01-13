import Foundation

protocol XcodeBuildCoverageParsing {
    static func coverage(xcresultBundlePath: String, files: [String], excludedTargets: [String], hideProjectCoverage: Bool) throws -> Report
}

enum XcodeBuildCoverageParser: XcodeBuildCoverageParsing {
    static func coverage(xcresultBundlePath: String, files: [String], excludedTargets: [String], hideProjectCoverage: Bool) throws -> Report {
        var attemptCount: Int = 1
        var lastError: Error?
        
        while attemptCount <= 3 {
            do {
                return try coverage(xcresultBundlePath: xcresultBundlePath, files: files, excludedTargets: excludedTargets, hideProjectCoverage: hideProjectCoverage, xcCovParser: XcCovJSONParser.self)
            } catch let error {
                lastError = error
                attemptCount += 1
            }
        }
        
        if let error = lastError {
            throw error
        }
        return Report(messages: [], sections: [])
    }

    static func coverage(xcresultBundlePath: String, files: [String], excludedTargets: [String], hideProjectCoverage: Bool = false, xcCovParser: XcCovJSONParsing.Type) throws -> Report {
        let data = try xcCovParser.json(fromXcresultFile: xcresultBundlePath)
        return try report(fromJson: data, files: files, excludedTargets: excludedTargets, hideProjectCoverage: hideProjectCoverage)
    }

    private static func report(fromJson data: Data, files: [String], excludedTargets: [String], hideProjectCoverage: Bool) throws -> Report {
        var coverage = try JSONDecoder().decode(XcodeBuildCoverage.self, from: data)
        coverage = coverage.filteringTargets(notOn: files, excludedTargets: excludedTargets)

        let targets = coverage.targets.map { ReportSection(fromTarget: $0) }
        let messages = !targets.isEmpty && !hideProjectCoverage ? ["Project coverage: \(coverage.percentageCoverage.description)%"] : []

        return Report(messages: messages, sections: targets)
    }
}
