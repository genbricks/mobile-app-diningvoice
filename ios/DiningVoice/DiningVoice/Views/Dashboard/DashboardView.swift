import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    filterSection

                    if viewModel.isLoading && viewModel.analytics == nil {
                        LoadingView()
                            .frame(height: 300)
                    } else if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                            .padding(.horizontal)
                    } else if let data = viewModel.analytics {
                        statsGrid(data: data)
                        sentimentChart(data: data)
                        trendChart(data: data)
                        departmentBreakdown(data: data)
                    } else {
                        EmptyStateView(
                            icon: "chart.bar.xaxis",
                            title: "No Data Yet",
                            message: "Start recording feedback to see analytics here."
                        )
                        .frame(height: 300)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboard()
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
    }

    private var filterSection: some View {
        VStack(spacing: 12) {
            if !viewModel.departments.isEmpty {
                Menu {
                    Button("All Departments") {
                        viewModel.selectedDepartment = nil
                        Task { await viewModel.loadDashboard() }
                    }
                    ForEach(viewModel.departments, id: \.self) { dept in
                        Button(dept) {
                            viewModel.selectedDepartment = dept
                            Task { await viewModel.loadDashboard() }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(viewModel.selectedDepartment ?? "All Departments")
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .foregroundStyle(.primary)
            }
        }
    }

    private func statsGrid(data: AnalyticsData) -> some View {
        let stats = data.sentimentStats
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 12) {
            StatCard(
                title: "Total",
                value: "\(stats.total)",
                icon: "doc.text.fill",
                iconColor: AppColors.primary
            )
            StatCard(
                title: "Positive",
                value: "\(stats.positive)",
                icon: "face.smiling.fill",
                iconColor: AppColors.positive
            )
            StatCard(
                title: "Negative",
                value: "\(stats.negative)",
                icon: "exclamationmark.triangle.fill",
                iconColor: AppColors.negative
            )
            StatCard(
                title: "Neutral",
                value: "\(stats.neutral)",
                icon: "face.dashed",
                iconColor: AppColors.neutral
            )

            if let incidents = viewModel.incidentStats {
                StatCard(
                    title: "Open Incidents",
                    value: "\(incidents.openCount)",
                    icon: "bell.badge.fill",
                    iconColor: .orange
                )
                StatCard(
                    title: "Closed Incidents",
                    value: "\(incidents.closedCount)",
                    icon: "checkmark.circle.fill",
                    iconColor: AppColors.positive
                )
            }
        }
    }

    @ViewBuilder
    private func sentimentChart(data: AnalyticsData) -> some View {
        let stats = data.sentimentStats
        if stats.total > 0 {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sentiment Distribution")
                    .font(.headline)

                Chart {
                    SectorMark(
                        angle: .value("Count", stats.positive),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(AppColors.positive)
                    .annotation(position: .overlay) {
                        if stats.positive > 0 {
                            Text("\(stats.positive)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }

                    SectorMark(
                        angle: .value("Count", stats.neutral),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(AppColors.neutral)
                    .annotation(position: .overlay) {
                        if stats.neutral > 0 {
                            Text("\(stats.neutral)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }

                    SectorMark(
                        angle: .value("Count", stats.negative),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(AppColors.negative)
                    .annotation(position: .overlay) {
                        if stats.negative > 0 {
                            Text("\(stats.negative)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 200)

                HStack(spacing: 20) {
                    legendItem(color: AppColors.positive, label: "Positive")
                    legendItem(color: AppColors.neutral, label: "Neutral")
                    legendItem(color: AppColors.negative, label: "Negative")
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func trendChart(data: AnalyticsData) -> some View {
        if !data.timeSeries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sentiment Trends")
                    .font(.headline)

                Chart(data.timeSeries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Count", entry.positive)
                    )
                    .foregroundStyle(AppColors.positive)
                    .symbol(.circle)

                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Count", entry.negative)
                    )
                    .foregroundStyle(AppColors.negative)
                    .symbol(.triangle)

                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Count", entry.neutral)
                    )
                    .foregroundStyle(AppColors.neutral)
                    .symbol(.square)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }

                HStack(spacing: 20) {
                    legendItem(color: AppColors.positive, label: "Positive")
                    legendItem(color: AppColors.neutral, label: "Neutral")
                    legendItem(color: AppColors.negative, label: "Negative")
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func departmentBreakdown(data: AnalyticsData) -> some View {
        if !data.departmentStats.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Department Breakdown")
                    .font(.headline)

                ForEach(data.departmentStats) { dept in
                    DepartmentRow(department: dept)
                }
            }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct DepartmentRow: View {
    let department: DepartmentStats
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(department.category)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        HStack(spacing: 12) {
                            Label("\(department.complaints)", systemImage: "arrow.down.circle.fill")
                                .font(.caption)
                                .foregroundStyle(AppColors.negative)
                            Label("\(department.compliments)", systemImage: "arrow.up.circle.fill")
                                .font(.caption)
                                .foregroundStyle(AppColors.positive)
                            Label("\(department.total)", systemImage: "number")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(AppColors.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(department.subcategories) { sub in
                        HStack {
                            Text(sub.subcategory)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Spacer()

                            HStack(spacing: 8) {
                                Text("\(sub.complaints)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.negative.opacity(0.15))
                                    .foregroundStyle(AppColors.negative)
                                    .clipShape(Capsule())

                                Text("\(sub.compliments)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.positive.opacity(0.15))
                                    .foregroundStyle(AppColors.positive)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
