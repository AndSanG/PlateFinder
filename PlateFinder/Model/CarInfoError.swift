
import Foundation

enum CarInfoError: LocalizedError {
    case networkError(Error)
    case noDataFound
    case invalidPlateFormat
    case parsingError(String)
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "No se pudo conectar al servidor. Verifique su conexión a internet."
        case .noDataFound:
            return "No se encontró información para esta placa. Verifique que el número sea correcto."
        case .invalidPlateFormat:
            return "El formato de la placa no es válido. Use el formato ABC1234."
        case .parsingError:
            return "Error al procesar la información. Intente nuevamente."
        case .serverError:
            return "El servidor no está disponible en este momento. Intente más tarde."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Verifique su conexión a internet e intente nuevamente."
        case .noDataFound:
            return "Asegúrese de que la placa esté registrada y tenga el formato correcto."
        case .invalidPlateFormat:
            return "Use el formato: 3 letras seguidas de 4 números (ej: ABC1234)."
        case .parsingError, .serverError:
            return "Intente nuevamente en unos minutos."
        }
    }
}
