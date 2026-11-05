public import Foundation

/// Fetches quota information, project IDs, and model availability from Google Cloud Code endpoints.
public actor GeminiQuotaService {
    private let session: URLSession

    /// Creates a quota service instance.
    ///
    /// - Parameter session: URLSession to use for network operations.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Refreshes quota for an account, fetching project metadata, model quotas, and quota buckets.
    ///
    /// - Parameter account: Account to refresh.
    /// - Returns: Updated account with fresh quota snapshot.
    public func refreshQuota(for account: GeminiAccount) async throws -> GeminiAccount {
        guard let token = account.accessToken, !token.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        var updated = account

        // 1. loadCodeAssist -> project ID and subscription tier
        let metaBody = ["metadata": ["ideType": "ANTIGRAVITY"]]
        let (projectJSON, _) = await postJSONSequential(endpoints: GeminiEndpoints.loadCodeAssist, body: metaBody, token: token)

        var projectID: String? = nil
        var detectedTier: GeminiSubscriptionTier = .free

        if let projectJSON {
            if let pid = projectJSON["cloudaicompanionProject"] as? String, !pid.isEmpty {
                projectID = pid
            }
            detectedTier = extractTier(from: projectJSON)
        }

        // 2. fetchAvailableModels -> primary model quotas
        var modelsBody: [String: Any] = [:]
        if let projectID, !projectID.isEmpty {
            modelsBody["project"] = projectID
        }

        let (modelsJSON, modelsResp) = await postJSONSequential(endpoints: GeminiEndpoints.fetchAvailableModels, body: modelsBody, token: token)

        if let http = modelsResp as? HTTPURLResponse, http.statusCode == 403 {
            var snap = GeminiQuotaSnapshot()
            snap.isForbidden = true
            snap.forbiddenReason = "403 Forbidden"
            snap.tier = detectedTier
            snap.lastUpdatedTimestamp = Date().timeIntervalSince1970
            updated.quota = snap
            return updated
        }

        guard let modelsJSON else {
            throw URLError(.cannotParseResponse)
        }

        var snapshot = parseModelsResponse(modelsJSON, tier: detectedTier)

        // 3. retrieveUserQuotaSummary -> weekly & 5h buckets
        let (summaryJSON, _) = await postJSONSequential(endpoints: GeminiEndpoints.retrieveUserQuotaSummary, body: modelsBody, token: token)
        if let summaryJSON, let rawGroups = summaryJSON["groups"] as? [[String: Any]] {
            fuseSummaryGroups(rawGroups, into: &snapshot)
        }

        updated.quota = snapshot
        return updated
    }

    private func extractTier(from json: [String: Any]) -> GeminiSubscriptionTier {
        if let paid = json["paidTier"] as? [String: Any] {
            let raw = (paid["id"] as? String) ?? (paid["name"] as? String)
            let tier = GeminiSubscriptionTier.normalize(raw)
            if tier != .free { return tier }
        }
        if let cur = json["currentTier"] as? [String: Any] {
            let raw = (cur["id"] as? String) ?? (cur["name"] as? String)
            let tier = GeminiSubscriptionTier.normalize(raw)
            if tier != .free { return tier }
        }
        if let allowed = json["allowedTiers"] as? [[String: Any]] {
            for t in allowed {
                let raw = (t["id"] as? String) ?? (t["name"] as? String)
                let tier = GeminiSubscriptionTier.normalize(raw)
                if tier != .free { return tier }
            }
        }
        return .free
    }

    private func parseModelsResponse(_ json: [String: Any], tier: GeminiSubscriptionTier) -> GeminiQuotaSnapshot {
        var models: [GeminiModelQuota] = []
        if let modelsDict = json["models"] as? [String: Any] {
            for (key, val) in modelsDict {
                guard let dict = val as? [String: Any] else { continue }
                let displayName = (dict["displayName"] as? String) ?? key
                var pct = 100
                var resetTime: String? = nil
                if let quotaInfo = dict["quotaInfo"] as? [String: Any] {
                    if let p = quotaInfo["remainingPercentage"] as? NSNumber {
                        pct = p.intValue
                    }
                    resetTime = quotaInfo["resetTime"] as? String
                }
                models.append(GeminiModelQuota(id: key, displayName: displayName, percentage: pct, resetTime: resetTime))
            }
        }

        return GeminiQuotaSnapshot(
            models: models,
            groups: [],
            tier: tier,
            isForbidden: false,
            forbiddenReason: nil,
            lastUpdatedTimestamp: Date().timeIntervalSince1970
        )
    }

    private func fuseSummaryGroups(_ groupsJSON: [[String: Any]], into snapshot: inout GeminiQuotaSnapshot) {
        var groups: [GeminiQuotaGroup] = []

        for groupDict in groupsJSON {
            let gName = (groupDict["displayName"] as? String) ?? ""
            var buckets: [GeminiQuotaBucket] = []

            if let rawBuckets = groupDict["buckets"] as? [[String: Any]] {
                for bDict in rawBuckets {
                    let bId = (bDict["bucketId"] as? String) ?? ""
                    let win = (bDict["window"] as? String) ?? ""
                    let fraction = (bDict["remainingFraction"] as? NSNumber)?.doubleValue ?? 0.0
                    let reset = bDict["resetTime"] as? String
                    let dName = bDict["displayName"] as? String

                    buckets.append(GeminiQuotaBucket(
                        id: bId,
                        window: win,
                        remainingFraction: fraction,
                        resetTime: reset,
                        displayName: dName
                    ))
                }
            }
            groups.append(GeminiQuotaGroup(displayName: gName, buckets: buckets))
        }

        snapshot.groups = groups

        // Fuse with individual models
        for i in 0..<snapshot.models.count {
            let model = snapshot.models[i]
            let nameLower = model.id.lowercased()
            let is3P = nameLower.hasPrefix("claude") || nameLower.hasPrefix("gpt")
            let isGemini = nameLower.hasPrefix("gemini")

            for group in groups {
                let gn = group.displayName.lowercased()
                let matches: Bool
                if is3P {
                    matches = gn.contains("claude") || gn.contains("gpt") || gn.contains("3p")
                } else if isGemini {
                    matches = gn.contains("gemini") || (!gn.contains("claude") && !gn.contains("gpt") && !gn.contains("3p"))
                } else {
                    matches = false
                }
                guard matches else { continue }

                var b5h: GeminiQuotaBucket? = nil
                var bWeek: GeminiQuotaBucket? = nil

                for b in group.buckets {
                    let win = b.window.lowercased()
                    let bid = b.id.lowercased()
                    if win.contains("5h") || bid.contains("5h") || win.contains("hour") || bid.contains("hour") {
                        b5h = b
                    }
                    if win.contains("week") || bid.contains("week") || win.contains("7d") || bid.contains("7d") {
                        bWeek = b
                    }
                }

                let chosen: GeminiQuotaBucket?
                if let b5h, let bWeek {
                    if bWeek.remainingFraction <= 0.001 {
                        chosen = bWeek
                    } else if b5h.remainingFraction <= bWeek.remainingFraction {
                        chosen = b5h
                    } else {
                        chosen = bWeek
                    }
                } else {
                    chosen = b5h ?? bWeek ?? group.buckets.first
                }

                if let chosen {
                    snapshot.models[i].percentage = chosen.remainingPercentage
                    if let r = chosen.resetTime, !r.isEmpty {
                        snapshot.models[i].resetTime = r
                    }
                }
                break
            }
        }
    }

    private func postJSONSequential(
        endpoints: [URL],
        body: [String: Any],
        token: String
    ) async -> ([String: Any]?, URLResponse?) {
        for url in endpoints {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue(GeminiEndpoints.userAgent, forHTTPHeaderField: "User-Agent")
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)

            do {
                let (data, response) = try await session.data(for: req)
                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 403 {
                        return (nil, http)
                    }
                    if (200...299).contains(http.statusCode) {
                        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                        return (json, http)
                    }
                }
            } catch {
                continue
            }
        }
        return (nil, nil)
    }
}
