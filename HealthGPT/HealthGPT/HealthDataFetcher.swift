//
// This source file is part of the Stanford HealthGPT project
//
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi


@Observable
class HealthDataFetcher: DefaultInitializable, Module, EnvironmentAccessible {
    @ObservationIgnored private let healthStore = HKHealthStore()
    
    required init() { }
    

    /// Fetches the user's health data for the specified quantity type identifier for the last two weeks.
    ///
    /// - Parameters:
    ///   - identifier: The `HKQuantityTypeIdentifier` representing the type of health data to fetch.
    ///   - unit: The `HKUnit` to use for the fetched health data values.
    ///   - options: The `HKStatisticsOptions` to use when fetching the health data.
    /// - Returns: An array of `Double` values representing the daily health data for the specified identifier.
    /// - Throws: `HealthDataFetcherError` if the data cannot be fetched.
    func fetchLastTwoWeeksQuantityData(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        options: HKStatisticsOptions
    ) async throws -> [Double] {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            throw HealthDataFetcherError.invalidObjectType
        }

        let predicate = createLastTwoWeeksPredicate()

        let quantityLastTwoWeeks = HKSamplePredicate.quantitySample(
            type: quantityType,
            predicate: predicate
        )

        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: quantityLastTwoWeeks,
            options: options,
            anchorDate: Date.startOfDay(),
            intervalComponents: DateComponents(day: 1)
        )

        let quantityCounts = try await query.result(for: healthStore)

        var dailyData = [Double]()

        quantityCounts.enumerateStatistics(
            from: Date().twoWeeksAgoStartOfDay(),
            to: Date.startOfDay()
        ) { statistics, _ in
            if let quantity = statistics.sumQuantity() {
                dailyData.append(quantity.doubleValue(for: unit))
            } else {
                dailyData.append(0)
            }
        }

        return dailyData
    }

    /// Fetches the user's step count data for the last two weeks.
    ///
    /// - Returns: An array of `Double` values representing daily step counts.
    /// - Throws: `HealthDataFetcherError` if the data cannot be fetched.
    func fetchLastTwoWeeksStepCount() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .stepCount,
            unit: HKUnit.count(),
            options: [.cumulativeSum]
        )
    }

    /// Fetches the user's active energy burned data for the last two weeks.
    ///
    /// - Returns: An array of `Double` values representing daily active energy burned.
    /// - Throws: `HealthDataFetcherError` if the data cannot be fetched.
    func fetchLastTwoWeeksActiveEnergy() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .activeEnergyBurned,
            unit: HKUnit.largeCalorie(),
            options: [.cumulativeSum]
        )
    }

    /// Fetches the user's exercise time data for the last two weeks.
    ///
    /// - Returns: An array of `Double` values representing daily exercise times in minutes.
    /// - Throws: `HealthDataFetcherError` if the data cannot be fetched.
    func fetchLastTwoWeeksExerciseTime() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .appleExerciseTime,
            unit: .minute(),
            options: [.cumulativeSum]
        )
    }

    /// Fetches the user's body weight data for the last two weeks.
    ///
    /// - Returns: An array of `Double` values representing daily body weights in pounds.
    /// - Throws: `HealthDataFetcherError` if the data cannot be fetched.
    func fetchLastTwoWeeksBodyWeight() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .bodyMass,
            unit: .pound(),
            options: [.discreteAverage]
        )
    }

    /// Fetches the user's heart rate data for the last two weeks.
    ///
    /// - Returns: An array of `Double` values representing daily average heart rates.
    /// - Throws: `HealthDataFetcherError` if the data cannot be fetched.
    func fetchLastTwoWeeksHeartRate() async throws -> [Double] {
        try await fetchLastTwoWeeksQuantityData(
            for: .heartRate,
            unit: .count(),
            options: [.discreteAverage]
        )
    }

    /// Fetches the user's sleep data for the last two weeks.
    ///
    /// - Returns: An array of `Double` values representing daily sleep duration in hours.
    /// - Throws: `HealthDataFetcherError` if the data cannot be fetched.
    func fetchLastTwoWeeksSleep() async throws -> [Double] {
        var dailySleepData: [Double] = []
        
        for day in -7..<0 { // Changed from -14 to -7
            // We start the calculation at 3 PM the previous day to 3 PM on the day in question.
            guard let startOfSleepDay = Calendar.current.date(byAdding: DateComponents(day: day - 1), to: Date.startOfDay()),
                  let startOfSleep = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: startOfSleepDay),
                  let endOfSleepDay = Calendar.current.date(byAdding: DateComponents(day: day), to: Date.startOfDay()),
                  let endOfSleep = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: endOfSleepDay) else {
                dailySleepData.append(0)
                continue
            }
            
            
            let sleepType = HKCategoryType(.sleepAnalysis)

            let dateRangePredicate = HKQuery.predicateForSamples(withStart: startOfSleep, end: endOfSleep, options: .strictEndDate)
            let allAsleepValuesPredicate = HKCategoryValueSleepAnalysis.predicateForSamples(equalTo: HKCategoryValueSleepAnalysis.allAsleepValues)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dateRangePredicate, allAsleepValuesPredicate])

            let descriptor = HKSampleQueryDescriptor(
                predicates: [.categorySample(type: sleepType, predicate: compoundPredicate)],
                sortDescriptors: []
            )
            
            let results = try await descriptor.result(for: healthStore)

            var secondsAsleep = 0.0
            for result in results {
                secondsAsleep += result.endDate.timeIntervalSince(result.startDate)
            }
            
            // Append the hours of sleep for that date
            dailySleepData.append(secondsAsleep / (60 * 60))
        }
        
        return dailySleepData
    }

    /// Fetches the user's blood glucose data for the last two weeks.
    ///
    /// - Returns: An array of `Int` values representing daily average blood glucose in mg/dL.
    /// - Throws: `HealthDataFetcherError` if the data cannot be fetched.
    func fetchLastTwoWeeksBloodGlucose() async throws -> [[GlucoseReading]] {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            throw HealthDataFetcherError.invalidObjectType
        }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: DateComponents(day: -7), to: now) ?? Date() // Changed from -14 to -7
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        
        let samples = try await descriptor.result(for: healthStore)
        var dailyGlucoseValues = Array(repeating: [GlucoseReading](), count: 7) // Changed from 14 to 7
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for sample in samples {
            if let sample = sample as? HKQuantitySample {
                let daysAgo = Calendar.current.dateComponents([.day], from: sample.startDate, to: now).day ?? 0
                if daysAgo < 7 { // Changed from 14 to 7
                    let index = 6 - daysAgo // Changed from 13 to 6
                    let valueInMgDl = Int(round(sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))))
                    let timeString = timeFormatter.string(from: sample.startDate)
                    let reading = GlucoseReading(value: valueInMgDl, time: timeString)
                    dailyGlucoseValues[index].append(reading)
                }
            }
        }
        
        return dailyGlucoseValues
    }

    /// Fetches the user's carbohydrates intake data for the last two weeks.
    ///
    /// - Returns: An array of `Double` values representing daily carbohydrates in grams.
    /// - Throws: `HealthDataFetcherError` if the data cannot be fetched.
    func fetchLastTwoWeeksCarbohydrates() async throws -> [[CarbReading]] {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) else {
            throw HealthDataFetcherError.invalidObjectType
        }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: DateComponents(day: -7), to: now) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        
        let samples = try await descriptor.result(for: healthStore)
        var dailyCarbValues = Array(repeating: [CarbReading](), count: 7)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for sample in samples {
            if let sample = sample as? HKQuantitySample {
                let daysAgo = Calendar.current.dateComponents([.day], from: sample.startDate, to: now).day ?? 0
                if daysAgo < 7 {
                    let index = 6 - daysAgo
                    let valueInGrams = Int(round(sample.quantity.doubleValue(for: .gram())))
                    let timeString = timeFormatter.string(from: sample.startDate)
                    let reading = CarbReading(value: valueInGrams, time: timeString)
                    dailyCarbValues[index].append(reading)
                }
            }
        }
        
        return dailyCarbValues
    }

    func fetchLastTwoWeeksInsulin() async throws -> [[InsulinReading]] {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .insulinDelivery) else {
            throw HealthDataFetcherError.invalidObjectType
        }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: DateComponents(day: -7), to: now) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: quantityType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        
        let samples = try await descriptor.result(for: healthStore)
        var dailyInsulinValues = Array(repeating: [InsulinReading](), count: 7)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for sample in samples {
            if let sample = sample as? HKQuantitySample {
                let daysAgo = Calendar.current.dateComponents([.day], from: sample.startDate, to: now).day ?? 0
                if daysAgo < 7 {
                    let index = 6 - daysAgo
                    let valueInUnits = sample.quantity.doubleValue(for: .internationalUnit())
                    let timeString = timeFormatter.string(from: sample.startDate)
                    let reading = InsulinReading(value: valueInUnits, time: timeString)
                    dailyInsulinValues[index].append(reading)
                }
            }
        }
        
        return dailyInsulinValues
    }

    private func createLastTwoWeeksPredicate() -> NSPredicate {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: DateComponents(day: -7), to: now) ?? Date() // Changed from -14 to -7
        return HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
    }
}
