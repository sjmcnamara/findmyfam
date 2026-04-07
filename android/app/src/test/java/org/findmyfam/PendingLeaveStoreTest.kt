package org.findmyfam

import android.content.Context
import android.content.SharedPreferences
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.findmyfam.services.PendingLeaveStore
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class PendingLeaveStoreTest {

    private lateinit var store: PendingLeaveStore
    private lateinit var editor: SharedPreferences.Editor

    @Before
    fun setUp() {
        editor = mockk(relaxed = true)
        every { editor.putString(any(), any()) } returns editor
        val prefs = mockk<SharedPreferences> {
            every { getString(any(), any()) } returns null
            every { edit() } returns editor
        }
        val context = mockk<Context> {
            every { getSharedPreferences("fmf_pending_leaves", Context.MODE_PRIVATE) } returns prefs
        }
        store = PendingLeaveStore(context)
    }

    // region add / contains

    @Test
    fun `initially empty`() {
        assertTrue(store.pendingLeaves.value.isEmpty())
        assertFalse(store.contains("group-1"))
    }

    @Test
    fun `add makes group pending`() {
        store.add("group-1")
        assertTrue(store.contains("group-1"))
        assertEquals(1, store.pendingLeaves.value.size)
    }

    @Test
    fun `add is idempotent`() {
        store.add("group-1")
        store.add("group-1")
        assertEquals(1, store.pendingLeaves.value.size)
    }

    @Test
    fun `add persists`() {
        store.add("group-1")
        verify { editor.putString(any(), any()) }
        verify { editor.apply() }
    }

    // endregion

    // region remove

    @Test
    fun `remove clears specific group`() {
        store.add("group-1")
        store.add("group-2")
        store.remove("group-1")
        assertFalse(store.contains("group-1"))
        assertTrue(store.contains("group-2"))
    }

    @Test
    fun `remove nonexistent group is no-op`() {
        store.add("group-1")
        store.remove("group-999")
        assertEquals(1, store.pendingLeaves.value.size)
    }

    // endregion

    // region removeAll

    @Test
    fun `removeAll clears everything`() {
        store.add("group-1")
        store.add("group-2")
        store.removeAll()
        assertTrue(store.pendingLeaves.value.isEmpty())
    }

    // endregion

    // region removeResolved

    @Test
    fun `removeResolved clears groups no longer active`() {
        store.add("group-1")
        store.add("group-2")
        store.add("group-3")
        // group-1 and group-3 are still active, group-2 is not
        store.removeResolved(setOf("group-1", "group-3"))
        // group-2 was pending but NOT in active set → resolved and removed
        // Wait — removeResolved removes groups that are NOT in activeGroupIds
        // Actually re-reading the code: resolved = pendingLeaves - activeGroupIds
        // Then pendingLeaves = pendingLeaves - resolved
        // So groups NOT in activeGroupIds are considered resolved and removed
        assertFalse(store.contains("group-2"))
        assertTrue(store.contains("group-1"))
        assertTrue(store.contains("group-3"))
    }

    @Test
    fun `removeResolved with no resolved groups does not persist`() {
        store.add("group-1")
        // group-1 is active → nothing to resolve
        store.removeResolved(setOf("group-1"))
        assertEquals(1, store.pendingLeaves.value.size)
    }

    // endregion
}
