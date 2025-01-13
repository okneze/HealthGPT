//
// This source file is part of the Stanford HealthGPT project
//
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors
//
// SPDX-License-Identifier: MIT
//


import Foundation

struct GlucoseReading: Codable {
    let value: Int
    let time: String
}

struct CarbReading: Codable {
    let value: Int
    let time: String
}

struct InsulinReading: Codable {
    let value: Double
    let time: String
}

struct HealthData: Codable {
    var date: String
    var steps: Double?
    var activeEnergy: Double?
    var exerciseMinutes: Double?
    var bodyWeight: Double?
    var sleepHours: Double?
    var heartRate: Double?
    var bloodGlucose: [GlucoseReading]?    // Changed to use GlucoseReading
    var carbohydrates: [CarbReading]?   // Changed from Double? to [CarbReading]?
    var insulin: [InsulinReading]?         // Changed from Double? to [InsulinReading]?
    
    init(
        date: String,
        steps: Double? = nil,
        sleepHours: Double? = nil,
        activeEnergy: Double? = nil,
        exerciseMinutes: Double? = nil,
        bodyWeight: Double? = nil,
        heartRate: Double? = nil,
        bloodGlucose: [GlucoseReading]? = nil,     // Changed to use GlucoseReading
        carbohydrates: [CarbReading]? = nil,
        insulin: [InsulinReading]? = nil
    ) {
        self.date = date
        self.steps = steps
        self.sleepHours = sleepHours
        self.activeEnergy = activeEnergy
        self.exerciseMinutes = exerciseMinutes
        self.bodyWeight = bodyWeight
        self.heartRate = heartRate
        self.bloodGlucose = bloodGlucose
        self.carbohydrates = carbohydrates
        self.insulin = insulin
    }
}
