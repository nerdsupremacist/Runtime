
import Foundation

extension Sequence {

    func first<T>(_ transform: (Element) throws -> T?) rethrows -> T? {
        for element in self {
            if let result = try transform(element) {
                return result
            }
        }
        return nil
    }

}
