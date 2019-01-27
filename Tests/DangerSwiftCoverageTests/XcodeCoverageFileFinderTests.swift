import XCTest
@testable import DangerSwiftCoverage

final class XcodeCoverageFileFinderTests: XCTestCase {
    private var fileManager: StubbedFileManager!
    
    override func setUp() {
        super.setUp()
        fileManager = StubbedFileManager()
    }

    override func tearDown() {
        super.tearDown()
        fileManager = nil
    }
    
    func testItFailsIfTheDirectoryDoesntContainAnXCResultFile() {
        XCTAssertThrowsError(try XcodeCoverageFileFinder.coverageFile(derivedDataFolder: "derived", fileManager: fileManager)) { error in
            XCTAssertEqual(error.localizedDescription, "Could not find the xcresult file")
        }
    }
    
    func testItFailsIfTheDirectoryDoesntContainAnXCovFile() {
        fileManager.contentResult = { fileName in
            return fileName == "derived/Logs/Test/" ? ["test.xcresult"] : []
        }
        
        XCTAssertThrowsError(try XcodeCoverageFileFinder.coverageFile(derivedDataFolder: "derived", fileManager: fileManager)) { error in
             XCTAssertEqual(error.localizedDescription, "Could not find the xcodecov file")
        }
    }
    
    func testItReturnsTheCorrectCoverageFile() throws {
        fileManager.contentResult = { fileName in
            return fileName == "derived/Logs/Test/" ? ["test.xcresult"] : (fileName == "test.xcresult" ? ["1_test"] : ["1_test/action.xcodecov"])
        }
        
        XCTAssertEqual(try XcodeCoverageFileFinder.coverageFile(derivedDataFolder: "derived", fileManager: fileManager), "1_test/action.xcodecov")
    }
}

private final class StubbedFileManager: FileManager {
    fileprivate var contentResult: ((String) -> [String])?
    
    override func contentsOfDirectory(atPath path: String) throws -> [String] {
        return contentResult?(path) ?? []
    }
}