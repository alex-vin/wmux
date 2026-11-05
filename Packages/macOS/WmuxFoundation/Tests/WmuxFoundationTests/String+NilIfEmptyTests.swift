import Testing

@testable import WmuxFoundation

@Suite struct StringNilIfEmptyTests {
    @Test func emptyStringBecomesNil() {
        #expect("".nilIfEmpty == nil)
    }

    @Test func nonEmptyStringPassesThrough() {
        #expect("wmux".nilIfEmpty == "wmux")
    }

    @Test func whitespaceIsNotEmpty() {
        // nilIfEmpty only checks isEmpty; a space is non-empty and passes through.
        #expect(" ".nilIfEmpty == " ")
    }
}
