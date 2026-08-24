import Foundation

func drainPages<Page, Element>(
    first: Page,
    elements: (Page) -> [Element],
    next: (Page) async throws -> Page?
) async rethrows -> [Element] {
    var page = first
    var items = elements(page)
    while let following = try await next(page) {
        items.append(contentsOf: elements(following))
        page = following
    }
    return items
}
