import SwiftSoup

final class ANTCarHTMLMapper: CarHTMLMapper {
    func map(_ html: String) throws -> Car {
        let document = try SwiftSoup.parse(html)
        guard let table = try document.select("body > table").first() else {
            throw CarInfoError.noDataFound
        }
        let rows = try table.select("tr")
        guard rows.count >= 4 else {
            throw CarInfoError.noDataFound
        }
        let r0 = try rows.get(0).select("td")
        let r1 = try rows.get(1).select("td")
        let r2 = try rows.get(2).select("td")
        let r3 = try rows.get(3).select("td")
        return Car(
            plate:              r0.safeText(at: 0),
            manufacturer:       r0.safeText(at: 2),
            colorName:          r0.safeText(at: 4),
            registrationYear:   r0.safeText(at: 6),
            model:              r1.safeText(at: 1),
            segment:            r1.safeText(at: 3),
            registrationDate:   r1.safeText(at: 5),
            year:               r2.safeText(at: 1),
            service:            r2.safeText(at: 3),
            expirationDate:     r2.safeText(at: 5),
            tint:               r3.safeText(at: 1),
            tintExpirationDate: r3.safeText(at: 3)
        )
    }
}

private extension Elements {
    func safeText(at index: Int) -> String {
        guard index < count else { return "" }
        return (try? get(index).text()) ?? ""
    }
}
