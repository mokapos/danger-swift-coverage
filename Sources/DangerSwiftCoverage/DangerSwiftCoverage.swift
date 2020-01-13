import Danger
import Foundation

public enum Coverage {
    public enum CoveragePathType {
        case xcresultBundle(String)
        case derivedDataFolder(String)

        fileprivate func xcresultBundlePath(xcresultFinder: XcresultBundleFinding.Type, fileManager: FileManager) throws -> String {
            switch self {
            case let .derivedDataFolder(folderPath):
                return try xcresultFinder.findXcresultFile(derivedDataFolder: folderPath, fileManager: fileManager)
            case let .xcresultBundle(path):
                return path
            }
        }
    }

    public static func xcodeBuildCoverage(_ coveragePathType: CoveragePathType, minimumCoverage: Float, minimumProjectCoverage: Float, excludedTargets: [String] = [], hideProjectCoverage: Bool = false) {
        xcodeBuildCoverage(coveragePathType, minimumCoverage: minimumCoverage, minimumProjectCoverage: minimumProjectCoverage, excludedTargets: excludedTargets, hideProjectCoverage: hideProjectCoverage, fileManager: .default, xcodeBuildCoverageParser: XcodeBuildCoverageParser.self, xcresultFinder: XcresultBundleFinder.self, danger: Danger())
    }

    static func xcodeBuildCoverage(_ coveragePathType: CoveragePathType, minimumCoverage: Float, minimumProjectCoverage: Float, excludedTargets: [String], hideProjectCoverage: Bool = false, fileManager: FileManager, xcodeBuildCoverageParser: XcodeBuildCoverageParsing.Type, xcresultFinder: XcresultBundleFinding.Type, danger: DangerDSL) {
        let paths = modifiedFilesAbsolutePaths(fileManager: fileManager, danger: danger)

        do {
            let xcresultBundlePath = try coveragePathType.xcresultBundlePath(xcresultFinder: xcresultFinder, fileManager: fileManager)
            let report = try xcodeBuildCoverageParser.coverage(xcresultBundlePath: xcresultBundlePath, files: paths, excludedTargets: excludedTargets, hideProjectCoverage: hideProjectCoverage)
            sendReport(report, minumumCoverage: minimumCoverage, minimumProjectCoverage: minimumProjectCoverage, danger: danger)
        } catch {
            danger.fail("Failed to get the coverage - Error: \(error.localizedDescription)")
            return
        }
    }

    public static func spmCoverage(spmCoverageFolder: String = ".build/debug/codecov", minimumCoverage: Float, minimumProjectCoverage: Float) {
        spmCoverage(spmCoverageFolder: spmCoverageFolder, minimumCoverage: minimumCoverage, minimumProjectCoverage: minimumProjectCoverage, spmCoverageParser: SPMCoverageParser.self, fileManager: .default, danger: Danger())
    }

    static func spmCoverage(spmCoverageFolder: String, minimumCoverage: Float, minimumProjectCoverage: Float, spmCoverageParser: SPMCoverageParsing.Type, fileManager: FileManager, danger: DangerDSL) {
        do {
            let report = try spmCoverageParser.coverage(spmCoverageFolder: spmCoverageFolder, files: modifiedFilesAbsolutePaths(fileManager: fileManager, danger: danger))
            sendReport(report, minumumCoverage: minimumCoverage, minimumProjectCoverage: minimumProjectCoverage, danger: danger)
        } catch {
            danger.fail("Failed to get the coverage - Error: \(error.localizedDescription)")
        }
    }

    private static func modifiedFilesAbsolutePaths(fileManager: FileManager, danger: DangerDSL) -> [String] {
        (danger.git.createdFiles + danger.git.modifiedFiles).map { fileManager.currentDirectoryPath + "/" + $0 }
    }

    private static func sendReport(_ report: Report, minumumCoverage: Float, minimumProjectCoverage: Float, danger: DangerDSL) {
        report.messages.forEach { danger.message($0) }
        
        report.sections.forEach {
            let projectCoverage = $0.getProjectCodeCoverage()
            if projectCoverage < minimumProjectCoverage {
                danger.fail("Current project code coverage \(projectCoverage)% is lower than minimum threshold of \(minimumProjectCoverage)%")
            }
            
            danger.markdown($0.markdown(minimumCoverage: minumumCoverage))
        }
    }
}
