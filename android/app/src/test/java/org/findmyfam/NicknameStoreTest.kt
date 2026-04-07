package org.findmyfam

import android.content.Context
import android.content.SharedPreferences
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.findmyfam.services.NicknameStore
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class NicknameStoreTest {

    private lateinit var store: NicknameStore
    private lateinit var editor: SharedPreferences.Editor

    private val alice = "a".repeat(64)
    private val bob = "b".repeat(64)

    @Before
    fun setUp() {
        editor = mockk(relaxed = true)
        every { editor.putString(any(), any()) } returns editor
        val prefs = mockk<SharedPreferences> {
            every { getString(any(), any()) } returns null
            every { edit() } returns editor
        }
        val context = mockk<Context> {
            every { getSharedPreferences("fmf_nicknames", Context.MODE_PRIVATE) } returns prefs
        }
        store = NicknameStore(context)
    }

    // region displayName

    @Test
    fun `displayName returns short hex fallback for unknown pubkey`() {
        val name = store.displayName(alice)
        assertEquals("${alice.take(8)}...", name)
    }

    @Test
    fun `displayName returns stored name`() {
        store.set("Alice", alice)
        assertEquals("Alice", store.displayName(alice))
    }

    // endregion

    // region set

    @Test
    fun `set adds nickname to flow`() {
        store.set("Alice", alice)
        assertEquals(mapOf(alice to "Alice"), store.nicknames.value)
    }

    @Test
    fun `set overwrites existing nickname`() {
        store.set("Alice", alice)
        store.set("Ally", alice)
        assertEquals("Ally", store.nicknames.value[alice])
    }

    @Test
    fun `set empty string removes nickname`() {
        store.set("Alice", alice)
        store.set("", alice)
        assertFalse(store.nicknames.value.containsKey(alice))
    }

    @Test
    fun `set persists to SharedPreferences`() {
        store.set("Alice", alice)
        verify { editor.putString(any(), any()) }
        verify { editor.apply() }
    }

    @Test
    fun `multiple nicknames tracked independently`() {
        store.set("Alice", alice)
        store.set("Bob", bob)
        assertEquals(2, store.nicknames.value.size)
        assertEquals("Alice", store.nicknames.value[alice])
        assertEquals("Bob", store.nicknames.value[bob])
    }

    // endregion

    // region clearAll

    @Test
    fun `clearAll empties all nicknames`() {
        store.set("Alice", alice)
        store.set("Bob", bob)
        store.clearAll()
        assertTrue(store.nicknames.value.isEmpty())
    }

    @Test
    fun `clearAll persists`() {
        store.set("Alice", alice)
        store.clearAll()
        verify(atLeast = 2) { editor.putString(any(), any()) }
    }

    // endregion
}
