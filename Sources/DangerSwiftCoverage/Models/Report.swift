import Foundation

struct Report {
    let messages: [String]
    let sections: [ReportSection]
}

struct ReportSection {
    let targetProject: Target?
    let titleText: String?
    let items: [ReportFile]
}

extension ReportSection {
    init(fromTarget target: Target) {
        targetProject = target
        titleText = "\(target.name): Coverage: \(target.percentageCoverage)%"
        items = target.files
            .filter({ (file) -> Bool in
                return file.name.lowercased().hasSuffix(".swift")
            })
            .map { ReportFile(fileName: $0.name, coverage: $0.percentageCoverage) }
    }
}

extension ReportSection {
    init(fromSPM spm: SPMCoverage, fileManager: FileManager) {
        titleText = nil
        items = spm.data.flatMap { $0.files
            .filter({ (file) -> Bool in
                return file.filename.lowercased().hasSuffix(".swift")
            })
            .map { ReportFile(fileName: $0.filename.deletingPrefix(fileManager.currentDirectoryPath + "/"), coverage: $0.summary.percent) } }
        targetProject = nil
    }
}

extension ReportSection {
    func getProjectCodeCoverage() -> Float {
        return self.targetProject?.percentageCoverage ?? 0
    }
    
    func markdown(minimumCoverage: Float) -> String {
        var markdown = titleText != nil ? "## \(titleText!)\n" : ""

        markdown += """
        | File | Coverage ||
        | --- | --- | --- |\n
        """

        markdown += items.map {
            "\($0.fileName) | \($0.coverage)% | \($0.coverage > minimumCoverage ? "✅" : "⚠️")\n"
        }.joined()

        return markdown
    }
}

struct ReportFile {
    let fileName: String
    let coverage: Float
}

private extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}
