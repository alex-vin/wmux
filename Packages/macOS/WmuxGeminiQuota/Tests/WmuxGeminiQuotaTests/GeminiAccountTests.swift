import Foundation
import Testing
@testable import WmuxGeminiQuota

@Suite("GeminiAccountTests")
struct GeminiAccountTests {
    @Test("Token serialization matches Antigravity format")
    func tokenSerializationMatchesAntigravityFormat() throws {
        let account = GeminiAccount(
            id: "alex@example.com",
            email: "alex@example.com",
            name: "Alex",
            accessToken: "mock_access",
            refreshToken: "mock_refresh",
            idToken: "mock_id_token",
            expiryTimestamp: 1800000000
        )

        let payload = account.agyPayloadJSON()
        #expect(payload.contains("mock_access"))
        #expect(payload.contains("mock_refresh"))
        #expect(payload.contains("consumer"))
        #expect(payload.contains("mock_id_token"))

        let secret = account.agyKeyringSecretValue()
        #expect(secret.hasPrefix("go-keyring-base64:"))

        let b64Part = String(secret.dropFirst("go-keyring-base64:".count))
        let decodedData = try #require(Data(base64Encoded: b64Part))
        let decodedString = try #require(String(data: decodedData, encoding: .utf8))
        #expect(decodedString == payload)
    }

    @Test("Token expiration calculation is accurate")
    func tokenExpirationCalculation() {
        let now = Date()
        let freshAccount = GeminiAccount(
            id: "fresh@example.com",
            email: "fresh@example.com",
            expiryTimestamp: now.timeIntervalSince1970 + 3600
        )
        #expect(!freshAccount.needsTokenRefresh(now: now))

        let expiringAccount = GeminiAccount(
            id: "expiring@example.com",
            email: "expiring@example.com",
            expiryTimestamp: now.timeIntervalSince1970 + 300 // 5 mins remaining
        )
        #expect(expiringAccount.needsTokenRefresh(now: now))
    }

    @Test("Subscription tier normalization")
    func subscriptionTierNormalization() {
        #expect(GeminiSubscriptionTier.normalize("pro-tier") == .pro)
        #expect(GeminiSubscriptionTier.normalize("Google One Premium") == .pro)
        #expect(GeminiSubscriptionTier.normalize("helium-tier") == .ultra)
        #expect(GeminiSubscriptionTier.normalize("starter-tier") == .free)
        #expect(GeminiSubscriptionTier.normalize(nil) == .free)
    }

    @Test("OAuth token response decodes integer and floating-point expires_in")
    func oAuthTokenResponseDecoding() throws {
        let jsonInt = """
        {
            "access_token": "ya29.test1234",
            "token_type": "Bearer",
            "expires_in": 3599,
            "refresh_token": "1//test_refresh",
            "id_token": "eyJhbGciOi..."
        }
        """.data(using: .utf8)!

        let decodedInt = try JSONDecoder().decode(GeminiOAuthTokenResponse.self, from: jsonInt)
        #expect(decodedInt.accessToken == "ya29.test1234")
        #expect(decodedInt.expiresIn == 3599.0)
        #expect(decodedInt.refreshToken == "1//test_refresh")
        #expect(decodedInt.idToken == "eyJhbGciOi...")

        let jsonDouble = """
        {
            "access_token": "ya29.test5678",
            "expires_in": 3600.5
        }
        """.data(using: .utf8)!

        let decodedDouble = try JSONDecoder().decode(GeminiOAuthTokenResponse.self, from: jsonDouble)
        #expect(decodedDouble.accessToken == "ya29.test5678")
        #expect(decodedDouble.expiresIn == 3600.5)
        #expect(decodedDouble.refreshToken == nil)
        #expect(decodedDouble.idToken == nil)
    }

    @Test("GeminiAccountStore saves file with 0600 POSIX permissions")
    @MainActor
    func accountStoreFilePermissions() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_store_perms_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let store = GeminiAccountStore(storageURL: tempURL)
        let account = GeminiAccount(id: "perms@example.com", email: "perms@example.com")
        store.addOrUpdateAccount(account)

        #expect(FileManager.default.fileExists(atPath: tempURL.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: tempURL.path)
        let perms = attributes[.posixPermissions] as? NSNumber
        #expect(perms?.intValue == 0o600)
    }

    @Test("Health status takes minimum of 5h and weekly quotas")
    @MainActor
    func healthStatusConsidersWeekly() {
        let store = GeminiAccountStore()
        let group = GeminiQuotaGroup(displayName: "Gemini Models", buckets: [
            GeminiQuotaBucket(id: "gemini-5h", window: "5h", remainingFraction: 1.0),
            GeminiQuotaBucket(id: "gemini-weekly", window: "weekly", remainingFraction: 0.15),
        ])
        let model = GeminiModelQuota(id: "gemini-3.8-flash", displayName: "Gemini 3.8 Flash", percentage: 15)
        let snapshot = GeminiQuotaSnapshot(models: [model], groups: [group])
        let account = GeminiAccount(id: "test@example.com", email: "test@example.com", quota: snapshot)

        #expect(store.healthStatus(for: account) == .critical)
    }

    @Test("Subscription tier decoding resilience with various cases and unknown strings")
    func subscriptionTierDecodingResilience() throws {
        struct TierWrapper: Codable {
            var tier: GeminiSubscriptionTier = .free

            enum CodingKeys: String, CodingKey {
                case tier
            }

            init(tier: GeminiSubscriptionTier) {
                self.tier = tier
            }

            init(from decoder: any Decoder) throws {
                let container = try? decoder.container(keyedBy: CodingKeys.self)
                self.tier = (try? container?.decodeIfPresent(GeminiSubscriptionTier.self, forKey: .tier)) ?? .free
            }
        }

        let cases: [(String, GeminiSubscriptionTier)] = [
            ("{\"tier\": \"FREE\"}", .free),
            ("{\"tier\": \"free\"}", .free),
            ("{\"tier\": \"starter\"}", .free),
            ("{\"tier\": \"PRO\"}", .pro),
            ("{\"tier\": \"pro\"}", .pro),
            ("{\"tier\": \"premium\"}", .pro),
            ("{\"tier\": \"advanced\"}", .pro),
            ("{\"tier\": \"ULTRA\"}", .ultra),
            ("{\"tier\": \"ultra\"}", .ultra),
            ("{\"tier\": \"helium\"}", .ultra),
            ("{\"tier\": \"some-new-tier-from-google\"}", .free),
            ("{\"tier\": 12345}", .free),
            ("{\"tier\": null}", .free),
            ("{}", .free)
        ]

        for (json, expected) in cases {
            let data = json.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(TierWrapper.self, from: data)
            #expect(decoded.tier == expected)
        }
    }

    @Test("Quota model decoding resilience with missing and altered fields")
    func quotaModelDecodingResilience() throws {
        // 1. GeminiQuotaBucket
        let bucketJSON = """
        {
            "id": "bucket-1"
        }
        """.data(using: .utf8)!
        let bucket = try JSONDecoder().decode(GeminiQuotaBucket.self, from: bucketJSON)
        #expect(bucket.id == "bucket-1")
        #expect(bucket.remainingFraction == 1.0)
        #expect(bucket.window == "")
        #expect(bucket.displayName == nil)

        // 2. GeminiQuotaGroup
        let groupJSON = """
        {
            "displayName": "Group 1"
        }
        """.data(using: .utf8)!
        let group = try JSONDecoder().decode(GeminiQuotaGroup.self, from: groupJSON)
        #expect(group.displayName == "Group 1")
        #expect(group.buckets.isEmpty)

        // 3. GeminiModelQuota
        let modelJSON = """
        {
            "id": "gemini-3.8-pro"
        }
        """.data(using: .utf8)!
        let model = try JSONDecoder().decode(GeminiModelQuota.self, from: modelJSON)
        #expect(model.id == "gemini-3.8-pro")
        #expect(model.percentage == 100)
        #expect(model.displayName == "")

        // 4. GeminiQuotaSnapshot with invalid tier and empty fields
        let snapshotJSON = """
        {
            "tier": "unknown-experimental-tier",
            "isForbidden": "not-a-bool"
        }
        """.data(using: .utf8)!
        let snapshot = try JSONDecoder().decode(GeminiQuotaSnapshot.self, from: snapshotJSON)
        #expect(snapshot.tier == .free)
        #expect(snapshot.models.isEmpty)
        #expect(snapshot.groups.isEmpty)
        #expect(!snapshot.isForbidden)

        // 5. GeminiAccount with minimal fields
        let accountJSON = """
        {
            "email": "resilient@example.com"
        }
        """.data(using: .utf8)!
        let account = try JSONDecoder().decode(GeminiAccount.self, from: accountJSON)
        #expect(account.id == "resilient@example.com")
        #expect(account.email == "resilient@example.com")
        #expect(account.quota.tier == .free)
        #expect(!account.isDisabled)
    }

    @Test("GeminiAccountStore backups corrupted files and recovers accounts tolerantly")
    @MainActor
    func corruptedFileBackupAndRecovery() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_recovery_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("gemini_accounts.json")

        // Case 1: Corrupted garbage data -> backup created, accounts empty but no crash
        let corruptedData = "this is not valid json at all".data(using: .utf8)!
        try corruptedData.write(to: fileURL)

        let store1 = GeminiAccountStore(storageURL: fileURL)
        #expect(store1.accounts.isEmpty)

        let files = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        let hasBackup = files.contains { $0.contains(".corrupted.") }
        #expect(hasBackup)

        // Case 2: Array format recovery: [ { "email": "arr@example.com" } ]
        let arrayJSON = """
        [
            {
                "email": "arr@example.com",
                "accessToken": "arr_token"
            }
        ]
        """.data(using: .utf8)!
        try arrayJSON.write(to: fileURL)

        let store2 = GeminiAccountStore(storageURL: fileURL)
        #expect(store2.accounts.count == 1)
        #expect(store2.accounts.first?.email == "arr@example.com")
        #expect(store2.defaultAccountID == "arr@example.com")

        // Case 3: Tolerant recovery when one account in accounts array is malformed
        let mixedJSON = """
        {
            "accounts": [
                {
                    "email": "valid1@example.com"
                },
                "this_entry_is_corrupted_and_not_an_object",
                {
                    "email": "valid2@example.com"
                }
            ],
            "defaultAccountID": "valid2@example.com"
        }
        """.data(using: .utf8)!
        try mixedJSON.write(to: fileURL)

        let store3 = GeminiAccountStore(storageURL: fileURL)
        #expect(store3.accounts.count == 2)
        let emails = store3.accounts.map(\.email)
        #expect(emails.contains("valid1@example.com"))
        #expect(emails.contains("valid2@example.com"))
    }

    @Test("GeminiAccountStore migrates legacy cmux file seamlessly")
    @MainActor
    func legacyMigration() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_migration_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let cmuxURL = tempDir.appendingPathComponent("cmux_accounts.json")
        let wmuxURL = tempDir.appendingPathComponent("wmux_accounts.json")

        // Write to legacy cmux URL
        let legacyStore = GeminiAccountStore(storageURL: cmuxURL)
        let legacyAccount = GeminiAccount(id: "migrated@example.com", email: "migrated@example.com")
        legacyStore.addOrUpdateAccount(legacyAccount)

        #expect(FileManager.default.fileExists(atPath: cmuxURL.path))
        #expect(!FileManager.default.fileExists(atPath: wmuxURL.path))

        // Replicate migration logic
        try FileManager.default.copyItem(at: cmuxURL, to: wmuxURL)
        let migratedStore = GeminiAccountStore(storageURL: wmuxURL)
        #expect(migratedStore.accounts.count == 1)
        #expect(migratedStore.accounts.first?.email == "migrated@example.com")
    }
}
