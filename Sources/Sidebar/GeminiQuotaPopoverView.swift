import AppKit
import CmuxAppKitSupportUI
import CmuxGeminiQuota
import SwiftUI

/// Compact popover card for inspecting Gemini quotas and switching/binding accounts per terminal surface.
struct GeminiQuotaPopoverView: View {
    @Bindable var store: GeminiAccountStore
    @Bindable var coordinator: GeminiTerminalAccountCoordinator
    let currentSurfaceID: UUID?
    var onClose: (() -> Void)? = nil

    @State private var isAddingAccount = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            if store.accounts.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let currentSurfaceID {
                            surfaceBindingSection(for: currentSurfaceID)
                        }

                        accountListSection
                    }
                    .padding(12)
                }
            }

            if let errorMessage {
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11))
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    Spacer()
                    Button("关闭") {
                        self.errorMessage = nil
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.04))
            }
        }
        .frame(width: 320, height: 380)
        .accessibilityIdentifier("GeminiQuotaPopoverView")
    }

    private var header: some View {
        HStack {
            Text("Gemini 额度与账号")
                .cmuxFont(size: 13, weight: .semibold)

            Spacer()

            if store.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 16, height: 16)
            } else {
                Button {
                    Task {
                        await store.refreshAllAccounts()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("立即刷新配额 (⌘R)")
            }

            Button {
                startAddAccount()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("添加 Google 账号")
            .disabled(isAddingAccount)

            if let onClose {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("关闭面板")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            Text("暂未绑定 Google 账号")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            Text("添加 Google 账号后，即可在每个终端独立监控和使用 Gemini 额度。")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                startAddAccount()
            } label: {
                if isAddingAccount {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("登录并添加账号")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(isAddingAccount)
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func surfaceBindingSection(for surfaceID: UUID) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("当前终端绑定")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Menu {
                    Button("跟随全局默认") {
                        coordinator.unbind(surfaceID: surfaceID)
                    }
                    Divider()
                    ForEach(store.accounts) { acc in
                        Button(acc.email) {
                            coordinator.bind(surfaceID: surfaceID, to: acc.id)
                        }
                    }
                } label: {
                    let assigned = coordinator.surfaceBindings[surfaceID]
                    let title = assigned.flatMap { store.account(for: $0)?.emailLocalPart } ?? "全局默认"
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.03)))
    }

    private var accountListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(store.accounts) { account in
                accountCard(account)
            }
        }
    }

    private func accountCard(_ account: GeminiAccount) -> some View {
        let isDefault = account.id == store.defaultAccountID
        let status = store.healthStatus(for: account)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusDotColor(for: status))
                    .frame(width: 7, height: 7)

                Text(account.emailLocalPart)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(account.isDisabled ? .secondary : .primary)

                if isDefault {
                    Text("默认")
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.15)))
                        .foregroundColor(.blue)
                }

                Text(account.quota.tier.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)))
                    .foregroundColor(.secondary)

                Spacer()

                Menu {
                    if !isDefault {
                        Button("设为全局默认") {
                            store.defaultAccountID = account.id
                        }
                    }
                    Button("立即刷新该账号") {
                        Task {
                            await store.refreshAccount(id: account.id)
                        }
                    }
                    Divider()
                    Button("移除账号", role: .destructive) {
                        store.removeAccount(id: account.id)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }

            if account.isDisabled {
                Text(account.disabledReason ?? "账号已失效")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
            } else if let flagship = account.quota.flagshipModel {
                let b5h = account.quota.bucket5h(for: flagship)
                let bWeek = account.quota.bucketWeekly(for: flagship)

                VStack(spacing: 6) {
                    if let b5h {
                        quotaRow(
                            label: "5h 窗口",
                            percentage: b5h.remainingPercentage,
                            countdown: GeminiQuotaSnapshot.countdownText(fromRFC3339: b5h.resetTime, wording: "后刷新")
                        )
                    }

                    if let bWeek {
                        quotaRow(
                            label: "每周窗口",
                            percentage: bWeek.remainingPercentage,
                            countdown: GeminiQuotaSnapshot.countdownText(fromRFC3339: bWeek.resetTime, wording: "后重置")
                        )
                    }
                }
            } else if account.quota.isForbidden {
                Text("403 Forbidden - 账号受限或无访问权限")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isDefault ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }

    private func quotaRow(label: String, percentage: Int, countdown: String) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(percentage)%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(quotaTextColor(percentage: percentage))
                if !countdown.isEmpty {
                    Text("[\(countdown)]")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(quotaBarColor(percentage: percentage))
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(percentage) / 100.0)), height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    private func statusDotColor(for status: GeminiQuotaHealthStatus) -> Color {
        switch status {
        case .healthy: .green
        case .warning: .orange
        case .critical: .red
        case .disabled: .secondary
        }
    }

    private func quotaBarColor(percentage: Int) -> Color {
        if percentage <= 20 { return .red }
        if percentage <= 50 { return .orange }
        return .green
    }

    private func quotaTextColor(percentage: Int) -> Color {
        if percentage <= 20 { return .red }
        if percentage <= 50 { return .orange }
        return .primary
    }

    private func startAddAccount() {
        guard !isAddingAccount else { return }
        isAddingAccount = true
        errorMessage = nil
        Task {
            do {
                _ = try await store.startOAuthLogin()
            } catch {
                self.errorMessage = "添加账号失败: \(error.localizedDescription)"
            }
            isAddingAccount = false
        }
    }
}
