//
//  ProcessRunner.swift
//  Tellal
//

import Foundation
import AppKit

@MainActor
final class ProcessRunner {
    static let shared = ProcessRunner()

    private var activeProcess: Process?

    func isRunning() -> Bool {
        return activeProcess?.isRunning ?? false
    }

    func stop() {
        if let process = activeProcess, process.isRunning {
            process.terminate()
            activeProcess = nil
        }
    }

    func runPythonScript(
        arguments: [String],
        workingDirectory: URL,
        onOutput: @escaping (String, LogEntry.LogType) -> Void,
        onCompletion: @escaping (Bool) -> Void
    ) {
        stop()

        let process = Process()
        let pipe = Pipe()

        // python3 arama
        let pythonPath = findPythonExecutable()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory
        process.standardOutput = pipe
        process.standardError = pipe

        var environment = ProcessInfo.processInfo.environment
        environment["PYTHONUNBUFFERED"] = "1"
        process.environment = environment

        let fileHandle = pipe.fileHandleForReading

        fileHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }

            let lines = text.components(separatedBy: .newlines)
            Task { @MainActor in
                for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    let logType = self.categorizeLine(line)
                    onOutput(line, logType)
                }
            }
        }

        process.terminationHandler = { proc in
            Task { @MainActor in
                fileHandle.readabilityHandler = nil
                let success = proc.terminationStatus == 0
                if success {
                    self.playSuccessSound()
                }
                onCompletion(success)
                self.activeProcess = nil
            }
        }

        self.activeProcess = process

        do {
            try process.run()
        } catch {
            onOutput("İşlem başlatılamadı: \(error.localizedDescription)", .error)
            onCompletion(false)
            self.activeProcess = nil
        }
    }

    func runAfterEffectsRender(
        projectPath: String,
        composition: String,
        outputTemplate: String = "ygiido",
        outputPath: String,
        onOutput: @escaping (String, LogEntry.LogType) -> Void,
        onCompletion: @escaping (Bool) -> Void
    ) {
        stop()

        let aerender = TellalConfig.shared.aerenderPath
        guard FileManager.default.fileExists(atPath: aerender) else {
            onOutput("aerender motoru bulunamadı! Yol: \(aerender)", .error)
            onCompletion(false)
            return
        }

        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: aerender)
        process.arguments = [
            "-project", projectPath,
            "-comp", composition,
            "-OMtemplate", outputTemplate,
            "-output", outputPath
        ]
        process.standardOutput = pipe
        process.standardError = pipe

        let fileHandle = pipe.fileHandleForReading
        fileHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }

            let lines = text.components(separatedBy: .newlines)
            Task { @MainActor in
                for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    let logType = self.categorizeLine(line)
                    onOutput(line, logType)
                }
            }
        }

        process.terminationHandler = { proc in
            Task { @MainActor in
                fileHandle.readabilityHandler = nil
                let success = proc.terminationStatus == 0 && FileManager.default.fileExists(atPath: outputPath)
                if success {
                    self.playSuccessSound()
                }
                onCompletion(success)
                self.activeProcess = nil
            }
        }

        self.activeProcess = process

        do {
            try process.run()
        } catch {
            onOutput("After Effects başlatılamadı: \(error.localizedDescription)", .error)
            onCompletion(false)
            self.activeProcess = nil
        }
    }

    private func categorizeLine(_ line: String) -> LogEntry.LogType {
        let lower = line.lowercased()
        if lower.contains("progress:") || lower.contains("ilerleme:") {
            return .progress
        } else if lower.contains("error") || lower.contains("hata") || lower.contains("critical") {
            return .error
        } else if lower.contains("warning") || lower.contains("uyarı") {
            return .warning
        } else if lower.contains("başarılı") || lower.contains("success") || lower.contains("tamamlandı") {
            return .success
        }
        return .standard
    }

    private func findPythonExecutable() -> String {
        let paths = ["/usr/local/bin/python3", "/opt/homebrew/bin/python3", "/usr/bin/python3"]
        for p in paths {
            if FileManager.default.fileExists(atPath: p) {
                return p
            }
        }
        return "/usr/bin/python3"
    }

    private func playSuccessSound() {
        let soundUrl = TellalConfig.shared.soundDoneURL
        if FileManager.default.fileExists(atPath: soundUrl.path) {
            let sound = NSSound(contentsOf: soundUrl, byReference: true)
            sound?.play()
        } else {
            NSSound.beep()
        }
    }
}
