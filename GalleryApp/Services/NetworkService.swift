import Foundation

protocol NetworkServiceProtocol {
    func fetchPhotos(page: Int, completion: @escaping (Result<PhotoResponse, Error>) -> Void)
}

class NetworkService: NetworkServiceProtocol {
    private let baseURL = "https://api.unsplash.com"
    private let accessKey = "elw8fVRTyxrax_u8IS7Qu_MDuicPoA88mOA0SqV_AlM"
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    func fetchPhotos(page: Int, completion: @escaping (Result<PhotoResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/search/photos"
        guard var urlComponents = URLComponents(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: "nature"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "30"),
            URLQueryItem(name: "orientation", value: "portrait")
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    completion(.failure(NetworkError.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let photoResponse = try JSONDecoder().decode(PhotoResponse.self, from: data)
                    completion(.success(photoResponse))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case httpError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .noData:
            return "Нет данных"
        case .httpError(let code):
            return "HTTP ошибка: \(code)"
        case .decodingError:
            return "Ошибка декодирования данных"
        }
    }
}
