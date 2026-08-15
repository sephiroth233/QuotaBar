import Foundation
import Testing
@testable import QuotaBar

@Test("Progress values are clamped for display")
func progressValuesAreClamped() {
    let belowZero = ProgressMetric(label: "Weekly", remainingFraction: -0.25, resetAt: nil)
    let aboveOne = ProgressMetric(label: "Weekly", remainingFraction: 1.25, resetAt: nil)

    #expect(belowZero.clampedRemainingFraction == 0)
    #expect(aboveOne.clampedRemainingFraction == 1)
}

@Test("Provider order remains stable")
func providerOrderIsStable() {
    #expect(ProviderID.allCases == [.codex, .openRouter, .deepSeek])
}

@Test("Health thresholds reflect remaining capacity")
func healthThresholds() {
    #expect(MetricFormatting.health(forRemainingFraction: 0.75) == .healthy)
    #expect(MetricFormatting.health(forRemainingFraction: 0.30) == .warning)
    #expect(MetricFormatting.health(forRemainingFraction: 0.10) == .critical)
}

@Test("Local credentials persist with private file permissions")
func localCredentialsPersistWithPrivatePermissions() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("QuotaBarTests-\(UUID().uuidString)", isDirectory: true)
    let fileURL = directory.appendingPathComponent("credentials.json")
    defer { try? FileManager.default.removeItem(at: directory) }

    let writer = LocalCredentialStore(fileURL: fileURL)
    try writer.save("  test-deepseek-key  ", for: .deepSeekAPIKey)
    try writer.save("test-openrouter-key", for: .openRouterAPIKey)

    let reader = LocalCredentialStore(fileURL: fileURL)
    #expect(try reader.read(.deepSeekAPIKey) == "test-deepseek-key")
    #expect(try reader.read(.openRouterAPIKey) == "test-openrouter-key")
    #expect(reader.contains(.deepSeekAPIKey))

    let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
    let permissions = try #require(attributes[.posixPermissions] as? NSNumber)
    #expect(permissions.intValue == 0o600)

    try reader.delete(.deepSeekAPIKey)
    #expect(try reader.read(.deepSeekAPIKey) == nil)
    #expect(try reader.read(.openRouterAPIKey) == "test-openrouter-key")

    try reader.delete(.openRouterAPIKey)
    #expect(!FileManager.default.fileExists(atPath: fileURL.path))
}
