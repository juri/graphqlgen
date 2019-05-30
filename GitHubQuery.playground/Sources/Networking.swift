import Foundation

// Add your GitHub auth token here.
public let token = ""

struct QueryWrapper: Encodable {
    let query: String
}

enum NetworkingError: Error {
    case expectedResponseNotReceived
    case unexpectedStatus(Int, String)
    case noDataReceived
    case unexpectedJSONData
    case dataNotJSON(Data, Error)
}

public func query(_ gqlString: String, callback: @escaping (Result<Dictionary<AnyHashable, Any>, Error>) -> Void) {
    let wrappedGraphQL = try! JSONEncoder().encode(QueryWrapper(query: gqlString))
    let url = URL(string: "https://api.github.com/graphql")!
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("bearer \(token)", forHTTPHeaderField: "Authorization")
    req.httpBody = wrappedGraphQL

    let session = URLSession.shared
    let task = session.dataTask(with: req) { data, response, error in
        if let error = error {
            callback(.failure(error))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            callback(.failure(NetworkingError.expectedResponseNotReceived))
            return
        }

        guard httpResponse.statusCode == 200 else {
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "(failed to read)"
            callback(.failure(NetworkingError.unexpectedStatus(httpResponse.statusCode, body)))
            return
        }

        guard let data = data else {
            callback(.failure(NetworkingError.noDataReceived))
            return
        }

        let json: Dictionary<AnyHashable, Any>
        do {
            let jsonAny = try JSONSerialization.jsonObject(with: data, options: [])
            guard let jsonDict = jsonAny as? Dictionary<AnyHashable, Any> else {
                callback(.failure(NetworkingError.unexpectedJSONData))
                return
            }
            json = jsonDict
        } catch {
            callback(.failure(NetworkingError.dataNotJSON(data, error)))
            return
        }

        callback(.success(json))
    }
    task.resume()
}

