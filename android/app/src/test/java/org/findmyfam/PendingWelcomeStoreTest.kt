package org.findmyfam

import android.content.Context
import android.content.SharedPreferences
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.findmyfam.services.PendingWelcomeItem
import org.findmyfam.services.PendingWelcomeStore
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class PendingWelcomeStoreTest {

    private lateinit var store: PendingWelcomeStore
    private lateinit var editor: SharedPreferences.Editor

    private fun welcome(groupId: String) = PendingWelcomeItem(
        mlsGroupId = groupId,
        senderPubkeyHex = "a".repeat(64),
        wrapperEventId = "evt-$groupId",
        receivedAt = System.currentTimeMillis()
    )

    @Before
    fun setUp() {
        editor = mockk(relaxed = true)
        every { editor.putString(any(), any()) } returns editor
        val prefs = mockk<SharedPreferences> {
            every { getString(any(), any()) } returns null
            every { edit() } returns editor
        }
        val context = mockk<Context> {
            every { getSharedPreferences("fmf_pending_welcomes", Context.MODE_PRIVATE) } returns prefs
        }
        store = PendingWelcomeStore(context)
    }

    // region add

    @Test
    fun `add stores welcome`() {
        store.add(welcome("group-1"))
        assertEquals(1, store.pendingWelcomes.value.size)
        assertEquals("group-1", store.pendingWelcomes.value[0].mlsGroupId)
    }

    @Test
    fun `add deduplicates by mlsGroupId`() {
        store.add(welcome("group-1"))
        store.add(welcome("group-1"))
        assertEquals(1, store.pendingWelcomes.value.size)
    }

    @Test
    fun `add multiple different groups`() {
        store.add(welcome("group-1"))
        store.add(welcome("group-2"))
        assertEquals(2, store.pendingWelcomes.value.size)
    }

    @Test
    fun `add persists`() {
        store.add(welcome("group-1"))
        verify { editor.putString(any(), any()) }
        verify { editor.apply() }
    }

    // endregion

    // region remove

    @Test
    fun `remove by mlsGroupId`() {
        store.add(welcome("group-1"))
        store.add(welcome("group-2"))
        store.remove("group-1")
        assertEquals(1, store.pendingWelcomes.value.size)
        assertEquals("group-2", store.pendingWelcomes.value[0].mlsGroupId)
    }

    @Test
    fun `remove nonexistent group is safe`() {
        store.add(welcome("group-1"))
        store.remove("group-999")
        assertEquals(1, store.pendingWelcomes.value.size)
    }

    // endregion

    // region removeAll

    @Test
    fun `removeAll clears everything`() {
        store.add(welcome("group-1"))
        store.add(welcome("group-2"))
        store.removeAll()
        assertTrue(store.pendingWelcomes.value.isEmpty())
    }

    @Test
    fun `removeAll persists`() {
        store.add(welcome("group-1"))
        store.removeAll()
        verify(atLeast = 2) { editor.putString(any(), any()) }
    }

    // endregion
}
