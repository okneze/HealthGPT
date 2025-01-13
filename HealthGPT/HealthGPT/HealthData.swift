//
// This source file is part of the Stanford HealthGPT project
//
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors
//
// SPDX-License-Identifier: MIT
//


import Foundation


struct HealthData: Codable {
    var date: String
    var steps: Double?
    var activeEnergy: Double?
    var exerciseMinutes: Double?
    var bodyWeight: Double?
    var sleepHours: Double?
    var heartRate: Double?
    var bloodGlucose: Double?    // New property for blood glucose in mg/dL
    var carbohydrates: Double?   // New property for carbohydrates in grams
    var insulin: Double?         // New property for insulin in units
    
    init(
        date: String,
        steps: Double? = nil,
        sleepHours: Double? = nil,
        activeEnergy: Double? = nil,
        exerciseMinutes: Double? = nil,
        bodyWeight: Double? = nil,
        heartRate: Double? = nil,
        bloodGlucose: Double? = nil,
        carbohydrates: Double? = nil,
        insulin: Double? = nil
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
