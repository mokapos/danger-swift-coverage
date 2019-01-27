import XCTest
@testable import DangerSwiftCoverage

final class XcodeBuildCoverageParserTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockedXcCovJSONParser.receivedFile = nil
        FakeXcodeCoverageFileFinder.receivedDataFolder = nil
    }
    
    func testItParsesTheJSONCorrectly() {
        let files = ["/Users/franco/Projects/swift/Sources/Danger/BitBucketServerDSL.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/Danger.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/Files Import/ImportsFinder.swift",
                     "/Users/franco/Projects/swift/Sources/RunnerLib/HelpMessagePresenter.swift"]
        
        let result = try! XcodeBuildCoverageParser.coverage(derivedDataFolder: "derived", files: files, coverageFileFinder: FakeXcodeCoverageFileFinder.self, xcCovParser: MockedXcCovJSONParser.self)
        
        XCTAssertEqual("derived", FakeXcodeCoverageFileFinder.receivedDataFolder)
        XCTAssertEqual(FakeXcodeCoverageFileFinder.result, MockedXcCovJSONParser.receivedFile)
        
        XCTAssertEqual(result.messages, ["Project coverage: 50.09"])
        
        let firstSection = result.sections[0]
        XCTAssertEqual(firstSection.titleText, "Danger.framework: Coverage: 43.44")
        XCTAssertEqual(firstSection.items, [
            ReportFile(fileName: "BitBucketServerDSL.swift", coverage: 100),
            ReportFile(fileName: "Danger.swift", coverage: 0)
        ])
        
        let secondSection = result.sections[1]
        XCTAssertEqual(secondSection.titleText, "RunnerLib.framework: Coverage: 66.67")
        XCTAssertEqual(secondSection.items, [
            ReportFile(fileName: "ImportsFinder.swift", coverage: 100),
            ReportFile(fileName: "HelpMessagePresenter.swift", coverage: 100)
        ])
    }
    
    func testItFiltersTheEmptyTargets() {
        let files = ["/Users/franco/Projects/swift/Sources/Danger/BitBucketServerDSL.swift",
                     "/Users/franco/Projects/swift/Sources/Danger/Danger.swift"]
        
        let result = try! XcodeBuildCoverageParser.coverage(derivedDataFolder: "derived", files: files, coverageFileFinder: FakeXcodeCoverageFileFinder.self, xcCovParser: MockedXcCovJSONParser.self)
        
        let firstSection = result.sections[0]
        XCTAssertEqual(firstSection.titleText, "Danger.framework: Coverage: 43.44")
        XCTAssertEqual(firstSection.items, [
            ReportFile(fileName: "BitBucketServerDSL.swift", coverage: 100),
            ReportFile(fileName: "Danger.swift", coverage: 0)
        ])
        
        XCTAssertEqual(result.sections.count, 1)
    }
    
    func testItReturnsTheCoverageWhenThereAreNoTargets() {
        let files: [String] = []
        
        let result = try! XcodeBuildCoverageParser.coverage(derivedDataFolder: "derived", files: files, coverageFileFinder: FakeXcodeCoverageFileFinder.self, xcCovParser: MockedXcCovJSONParser.self)
        
        XCTAssertEqual(result.messages, ["Project coverage: 50.09"])
    }
}

private struct FakeXcodeCoverageFileFinder: XcodeCoverageFileFinding {
    static let result = "result.xccoverage"
    static var receivedDataFolder: String? = nil
    
    static func coverageFile(derivedDataFolder: String) throws -> String {
        receivedDataFolder = derivedDataFolder
        return result
    }
}

private struct MockedXcCovJSONParser: XcCovJSONParsing {
    static let result = XcCovJSONResponse.data(using: .utf8)
    static var receivedFile: String? = nil
    
    static func json(fromXCoverageFile file: String) throws -> Data {
        receivedFile = file
        return result!
    }
}

extension ReportFile: Equatable {
    public static func == (lhs: ReportFile, rhs: ReportFile) -> Bool {
        return lhs.fileName == rhs.fileName &&
            lhs.coverage == rhs.coverage
    }
}