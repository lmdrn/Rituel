import Foundation

enum Deduplication {
    /// Indices des éléments en trop : pour chaque clé, on garde celui que `prefer` place en premier.
    static func redundant<Item, Key: Hashable>(_ items: [Item], key: (Item) -> Key, prefer: (Item, Item) -> Bool) -> [Int] {
        var kept: [Key: Int] = [:]
        var extra: [Int] = []
        for (index, item) in items.enumerated() {
            let k = key(item)
            if let current = kept[k] {
                if prefer(item, items[current]) {
                    extra.append(current)
                    kept[k] = index
                } else {
                    extra.append(index)
                }
            } else {
                kept[k] = index
            }
        }
        return extra.sorted()
    }
}
