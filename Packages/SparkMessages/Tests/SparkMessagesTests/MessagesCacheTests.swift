// Module: SparkMessagesTests

import SparkMessages
import Testing

struct MessagesCacheTests {
    @Test func storesAndReturnsUnreadCount() async {
        let cache = MessagesCache()
        await cache.set(9)
        #expect(await cache.get() == 9)
        await cache.clear()
        #expect(await cache.get() == 0)
    }
}
