//
// This source file is part of the Stanford HealthGPT project
//
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziChat
import SpeziLLM
import SpeziLLMLocal
import SpeziLLMOpenAI
import SpeziSpeechSynthesizer
import OSLog

@Observable
class HealthDataInterpreter: DefaultInitializable, Module, EnvironmentAccessible {
    @ObservationIgnored @Dependency(LLMRunner.self) private var llmRunner
    @ObservationIgnored @Dependency(HealthDataFetcher.self) private var healthDataFetcher
    
    private let logger = Logger(subsystem: "HealthGPT", category: "HealthDataInterpreter")
    
    var llm: (any LLMSession)?
    @ObservationIgnored private var systemPrompt = ""
    
    required init() { }
    
    
    /// Creates an `LLMRunner`, from an `LLMSchema` and injects the system prompt
    /// into the context, and assigns the resulting `LLMSession` to the `llm` property. For more
    /// information, please refer to the [`SpeziLLM`](https://swiftpackageindex.com/StanfordSpezi/SpeziLLM/documentation/spezillm) documentation.
    ///
    /// - Parameter schema: the LLMSchema to use
    @MainActor
    func prepareLLM(with schema: any LLMSchema) async throws {
        let llm = llmRunner(with: schema)
        systemPrompt = await generateSystemPrompt()
        llm.context.append(systemMessage: systemPrompt)
        if let localLLM = llm as? LLMLocalSession {
            try await localLLM.setup()
        }
        self.llm = llm
    }
    
    /// Queries the LLM using the current session in the `llm` property and adds the output to the context.
    @MainActor
    func queryLLM() async throws {
        guard let llm,
              llm.context.last?.role == .user || !(llm.context.contains(where: { $0.role == .assistant() }) ) else {
            return
        }
        
        let stream = try await llm.generate()
        
        for try await token in stream {
            llm.context.append(assistantOutput: token)
        }
    }
    
    /// Resets the LLM context and re-injects the system prompt.
    @MainActor
    func resetChat() async {
        systemPrompt = await generateSystemPrompt()
        llm?.context.reset()
        llm?.context.append(systemMessage: systemPrompt)
    }
    
    /// Fetches updated health data using the `HealthDataFetcher`
    /// and passes it to the `PromptGenerator` to create the system prompt.
    private func generateSystemPrompt() async -> String {
        let healthData = await fetchAndProcessHealthData()
        return PromptGenerator(with: healthData).buildMainPrompt()
    }

    func fetchAndProcessHealthData() async -> [HealthData] {
        var healthData: [HealthData] = []
        
        do {
            let stepCounts = try await healthDataFetcher.fetchLastTwoWeeksStepCount()
            let sleepHours = try await healthDataFetcher.fetchLastTwoWeeksSleep()
            let activeEnergy = try await healthDataFetcher.fetchLastTwoWeeksActiveEnergy()
            let exerciseMinutes = try await healthDataFetcher.fetchLastTwoWeeksExerciseTime()
            let bodyWeight = try await healthDataFetcher.fetchLastTwoWeeksBodyWeight()
            let heartRate = try await healthDataFetcher.fetchLastTwoWeeksHeartRate()
            let bloodGlucose = try await healthDataFetcher.fetchLastTwoWeeksBloodGlucose()
            let carbohydrates = try await healthDataFetcher.fetchLastTwoWeeksCarbohydrates()
            let insulin = try await healthDataFetcher.fetchLastTwoWeeksInsulin()
            
            // Get dates for the last 14 days
            for day in 0...13 {
                guard let date = Calendar.current.date(byAdding: .day, value: -(13 - day), to: Date()) else {
                    continue
                }
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: date)
                
                let healthDataItem = HealthData(
                    date: dateString,
                    steps: stepCounts[day],
                    sleepHours: sleepHours[day],
                    activeEnergy: activeEnergy[day],
                    exerciseMinutes: exerciseMinutes[day],
                    bodyWeight: bodyWeight[day],
                    heartRate: heartRate[day],
                    bloodGlucose: bloodGlucose[day],
                    carbohydrates: carbohydrates[day],
                    insulin: insulin[day]
                )
                
                healthData.append(healthDataItem)
            }
        } catch {
            logger.error("Error fetching health data: \(error.localizedDescription)")
        }
        
        return healthData
    }
}
