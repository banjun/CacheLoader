import Foundation

private class BundleFinder {}
extension Bundle {
    static let module = Bundle(for: BundleFinder.self)
}
