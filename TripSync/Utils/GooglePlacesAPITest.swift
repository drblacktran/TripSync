//
//  GooglePlacesAPITest.swift
//  TripSync
//
//  Simple console test for Google Places API
//

import Foundation

class GooglePlacesAPITest {
    
    /// Test the Google Places API with a simple autocomplete request (NEW API v1)
    static func testAutocomplete(query: String = "Hanoi") {
        guard let apiKey = Constants.googlePlacesAPIKey, !apiKey.isEmpty else {
            print("❌ [TEST] No API key found")
            return
        }
        
        print("🧪 [TEST] Testing Google Places API (NEW v1)...")
        print("🔑 [TEST] API Key: \(apiKey.prefix(10))...") // Show first 10 chars only
        print("🔍 [TEST] Query: \(query)")
        
        // NEW API v1: POST to /places:autocomplete
        guard let url = URL(string: "https://places.googleapis.com/v1/places:autocomplete") else {
            print("❌ [TEST] Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        
        // Build JSON body
        let body: [String: Any] = [
            "input": query,
            "locationRestriction": [
                "rectangle": [
                    "low": ["latitude": 8.0, "longitude": 102.0],
                    "high": ["latitude": 24.0, "longitude": 110.0]
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ [TEST] Failed to create request body: \(error)")
            return
        }
        
        print("🌐 [TEST] URL: \(url.absoluteString)")
        print("🔑 [TEST] Using X-Goog-Api-Key header")
        
        // Make the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [TEST] Network error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [TEST] HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ [TEST] No data received")
                return
            }
            
            // Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 [TEST] Raw Response:")
                print(jsonString)
            }
            
            // Try to decode NEW API response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // NEW API v1 uses "suggestions" array instead of "status" + "predictions"
                    if let suggestions = json["suggestions"] as? [[String: Any]] {
                        print("✅ [TEST] Success! Found \(suggestions.count) suggestions")
                        for (index, suggestion) in suggestions.prefix(3).enumerated() {
                            if let placePrediction = suggestion["placePrediction"] as? [String: Any],
                               let text = placePrediction["text"] as? [String: Any],
                               let textValue = text["text"] as? String {
                                print("   \(index + 1). \(textValue)")
                            }
                        }
                    } else if let error = json["error"] as? [String: Any] {
                        // NEW API error format
                        let code = error["code"] as? Int ?? 0
                        let message = error["message"] as? String ?? "Unknown error"
                        print("❌ [TEST] API Error (code \(code)): \(message)")
                    } else {
                        print("⚠️ [TEST] Unexpected response format")
                        print("   Response keys: \(json.keys.joined(separator: ", "))")
                    }
                }
            } catch {
                print("❌ [TEST] JSON parse error: \(error)")
            }
        }
        
        task.resume()
        print("⏳ [TEST] Request sent, waiting for response...")
    }
}
