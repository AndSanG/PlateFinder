import SwiftUI

struct CarDetailView: View {
    let car: Car
    @Environment(HistoryViewModel.self) private var historyViewModel

    private var isFavorite: Bool {
        if case .loaded(_, let favs) = historyViewModel.state {
            return favs.contains(car.plate)
        }
        return false
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(car.manufacturer + " " + car.model)
                        .font(.title).bold()
                    Text(car.plate)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    Task { await historyViewModel.toggleFavorite(car.plate) }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
            }
            .padding(16)

            VStack(alignment: .leading) {
                CarDetailItem(title: "year".localized, subtitle: car.year, iconName: "number")
                CarDetailItem(title: "color".localized, subtitle: car.colorName, iconName: "paintbrush")
                CarDetailItem(title: "usage".localized, subtitle: car.segment.capitalized + " de " + car.service.lowercased(), iconName: "car.2")
                CarDetailItem(title: "registration".localized, subtitle: car.registrationYear, iconName: "document")
                CarDetailItem(title: "registration_validity".localized, subtitle: car.registrationDate + "  ->  " + car.expirationDate, iconName: "calendar.circle")
                if !car.tintExpirationDate.isEmpty {
                    CarDetailItem(title: "tint_validity".localized, subtitle: car.tintExpirationDate, iconName: "calendar")
                }
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
        }
    }
}
