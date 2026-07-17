import Foundation
import Combine
import PoseKit

final class PoseLibraryViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var selectedTag: String?

    private let library: PoseLibraryProviding

    init(library: PoseLibraryProviding = PoseLibraryService()) {
        self.library = library
    }

    var results: [ReferencePose] {
        library.poses(matching: query, tag: selectedTag)
    }

    var tags: [String] { library.allTags() }

    func toggleTag(_ tag: String) {
        selectedTag = (selectedTag == tag) ? nil : tag
    }
}
