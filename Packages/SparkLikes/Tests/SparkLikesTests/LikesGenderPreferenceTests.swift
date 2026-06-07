// Module: SparkLikesTests — Feed preference enums.

import SparkLikes
import Testing

struct LikesGenderPreferenceTests {
    @Test func genderPreferenceWireValues() {
        #expect(LikesGenderPreference.all.wireValue == "all")
        #expect(LikesGenderPreference.same.wireValue == "same")
        #expect(LikesGenderPreference.opposite.wireValue == "opposite")
    }

    @Test func genderPreferenceLocalizedTitlesAreNonEmpty() {
        for preference in LikesGenderPreference.allCases {
            #expect(preference.localizedTitle.isEmpty == false)
            #expect(preference.id == preference.rawValue)
        }
    }

    @Test func intentWireValuesAndTitles() {
        for intent in LikesIntent.allCases {
            #expect(intent.wireValue == intent.rawValue)
            #expect(intent.localizedTitle.isEmpty == false)
        }
    }
}
