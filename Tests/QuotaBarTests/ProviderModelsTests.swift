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
