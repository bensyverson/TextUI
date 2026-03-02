import Testing
@testable import TextUI

@Suite("LayoutCache")
struct LayoutCacheTests {
    @Test("get returns nil for missing key")
    func getMissing() {
        let cache = LayoutCache()
        #expect(cache.get(forKey: "missing", as: Int.self) == nil)
    }

    @Test("set and get round-trip")
    func setAndGet() {
        let cache = LayoutCache()
        cache.set(42, forKey: "answer")
        #expect(cache.get(forKey: "answer", as: Int.self) == 42)
    }

    @Test("get returns nil for type mismatch")
    func typeMismatch() {
        let cache = LayoutCache()
        cache.set(42, forKey: "answer")
        #expect(cache.get(forKey: "answer", as: String.self) == nil)
    }

    @Test("different keys are isolated")
    func keyIsolation() {
        let cache = LayoutCache()
        cache.set("hello", forKey: "a")
        cache.set("world", forKey: "b")
        #expect(cache.get(forKey: "a", as: String.self) == "hello")
        #expect(cache.get(forKey: "b", as: String.self) == "world")
    }

    @Test("overwrite replaces previous value")
    func overwrite() {
        let cache = LayoutCache()
        cache.set(1, forKey: "k")
        cache.set(2, forKey: "k")
        #expect(cache.get(forKey: "k", as: Int.self) == 2)
    }

    @Test("separate cache instances are independent")
    func instanceIsolation() {
        let cache1 = LayoutCache()
        let cache2 = LayoutCache()
        cache1.set(1, forKey: "k")
        #expect(cache2.get(forKey: "k", as: Int.self) == nil)
    }
}
