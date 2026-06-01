import SwiftUI

struct CarPlayView: View {
    let searchViewModel: SearchViewModel
    let plate: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("PlateFinder")
                .font(.title)
                .fontWeight(.bold)

            switch searchViewModel.state {
            case .idle:
                VStack(spacing: 16) {
                    Text("Search a License Plate")
                        .font(.headline)

                    if let plate {
                        Text(plate)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)

                        Button("Search") {
                            Task { await searchViewModel.search(plate: plate) }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Text("Use Siri or search from iPhone")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

            case .loading:
                ProgressView()
                    .scaleEffect(1.5)

            case .success(let car):
                VStack(spacing: 12) {
                    Text(car.plate)
                        .font(.title2)
                        .fontWeight(.bold)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "Brand", value: car.manufacturer)
                        DetailRow(label: "Model", value: car.model)
                        DetailRow(label: "Year", value: car.year)
                        DetailRow(label: "Color", value: car.colorName)
                    }
                    .font(.callout)
                }

            case .error(let message):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Button("New Search") {
                searchViewModel.reset()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .task {
            if let plate {
                await searchViewModel.search(plate: plate)
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
