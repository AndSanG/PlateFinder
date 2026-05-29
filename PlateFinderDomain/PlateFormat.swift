public enum PlateFormat: Equatable {
    case empty
    case partiallyValid
    case invalid
    case bike       // AA123A
    case car        // AAA1234
    case special    // CD1234
}
