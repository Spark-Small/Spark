// Module: SparkSearch — DTO mapping.

import Foundation

enum SearchDTOMapper {
    static func result(from dto: SearchResultItemDTO) -> SearchResultItem {
        SearchResultItem(
            id: dto.id,
            title: dto.title,
            subtitle: dto.subtitle,
            kind: dto.kind
        )
    }
}
