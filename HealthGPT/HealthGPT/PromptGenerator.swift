//
// This source file is part of the Stanford HealthGPT project
//
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors
//
// SPDX-License-Identifier: MIT
//


import Foundation


class PromptGenerator {
    var healthData: [HealthData]

    init(with healthData: [HealthData]) {
        self.healthData = healthData
    }

    func buildMainPrompt() -> String {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .none)
        var mainPrompt = "You are HealthGPT, an expert in personal health. Provide concise answers based on the following health data from the past week. Today is \(today).\n\n"
        mainPrompt += buildFourteenDaysHealthDataPrompt()
        return mainPrompt
    }

    private func buildFourteenDaysHealthDataPrompt() -> String {
        var healthDataPrompt = ""
        for day in 0...6 {
            let dayData = healthData[day]
            let dayPrompt = buildOneDayHealthDataPrompt(with: dayData)
            healthDataPrompt += "\(dayData.date): \(dayPrompt) \n"
        }
        return healthDataPrompt
    }

    private func buildOneDayHealthDataPrompt(with dayData: HealthData) -> String {
        var dayPrompt = ""
        // Basisdaten nur hinzufügen, wenn sie vorhanden sind
        if let steps = dayData.steps, steps > 0 {
            dayPrompt += "\(Int(steps)) steps,"
        }
        if let sleepHours = dayData.sleepHours, sleepHours > 0 {
            dayPrompt += " \(Int(sleepHours))h sleep,"
        }
        // Blutzuckerwerte kompakter darstellen
        if let bloodGlucose = dayData.bloodGlucose, !bloodGlucose.isEmpty {
            dayPrompt += " BG:"
            dayPrompt += bloodGlucose.map { "\($0.value)@\($0.time)" }.joined(separator: ",")
            dayPrompt += ","
        }
        if let carbs = dayData.carbohydrates, !carbs.isEmpty {
            dayPrompt += " Carbs:"
            dayPrompt += carbs.map { "\($0.value)g@\($0.time)" }.joined(separator: ",")
            dayPrompt += ","
        }
        if let insulin = dayData.insulin, !insulin.isEmpty {
            dayPrompt += " Insulin:"
            dayPrompt += insulin.map { "\($0.value)U@\($0.time)" }.joined(separator: ",")
            dayPrompt += ","
        }
        return dayPrompt.isEmpty ? "no data" : String(dayPrompt.dropLast())
    }
}
