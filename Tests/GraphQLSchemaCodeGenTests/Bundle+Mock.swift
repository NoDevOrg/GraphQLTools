import Foundation

struct BundleError: Error {
    let description: String
}

extension Bundle {
    func contents(forResource: String, withExtension: String) throws -> String {
        guard let url = url(forResource: forResource, withExtension: withExtension, subdirectory: "Mocks") else {
            throw BundleError(description: "Could not find url for \(forResource).\(withExtension)")
        }

        let data = try Data(contentsOf: url)

        guard let string = String(data: data, encoding: .utf8) else {
            throw BundleError(description: "Could not read data as utf8 string")
        }

        return string
    }
}
