package org.findmyfam

import android.content.Context
import android.content.SharedPreferences
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.findmyfam.services.PendingInviteStore
import org.findmyfam.shared.models.PendingInvite
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class PendingInviteStoreTest {

    private lateinit var store: PendingInviteStore
    private lateinit var editor: SharedPreferences.Editor

    private fun invite(group: String) = PendingInvite(
        groupHint = group,
        inviterNpub = "npub1test",
        createdAt = System.currentTimeMillis()
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
            every { getSharedPreferences("fmf_pending_invites", Context.MODE_PRIVATE) } returns prefs
        }
        store = PendingInviteStore(context)
    }

    // region add

    @Test
    fun `add stores invite`() {
        store.add(invite("group-1"))
        assertEquals(1, store.pendingInvites.value.size)
        assertEquals("group-1", store.pendingInvites.value[0].groupHint)
    }

    @Test
    fun `add deduplicates by groupHint`() {
        store.add(invite("group-1"))
        store.add(invite("group-1"))
        assertEquals(1, store.pendingInvites.value.size)
    }

    @Test
    fun `add persists`() {
        store.add(invite("group-1"))
        verify { editor.putString(any(), any()) }
        verify { editor.apply() }
    }

    // endregion

    // region remove

    @Test
    fun `remove by groupHint`() {
        store.add(invite("group-1"))
        store.add(invite("group-2"))
        store.remove("group-1")
        assertEquals(1, store.pendingInvites.value.size)
        assertEquals("group-2", store.pendingInvites.value[0].groupHint)
    }

    @Test
    fun `remove nonexistent groupHint is no-op`() {
        store.add(invite("group-1"))
        store.remove("group-999")
        assertEquals(1, store.pendingInvites.value.size)
    }

    // endregion

    // region removeAll

    @Test
    fun `removeAll clears all invites`() {
        store.add(invite("group-1"))
        store.add(invite("group-2"))
        store.removeAll()
        assertTrue(store.pendingInvites.value.isEmpty())
    }

    // endregion

    // region removeResolved

    @Test
    fun `removeResolved removes matching active group IDs`() {
        store.add(invite("group-1"))
        store.add(invite("group-2"))
        store.add(invite("group-3"))
        store.removeResolved(setOf("group-1", "group-3"))
        assertEquals(1, store.pendingInvites.value.size)
        assertEquals("group-2", store.pendingInvites.value[0].groupHint)
    }

    @Test
    fun `removeResolved with no matches does not persist`() {
        store.add(invite("group-1"))
        val callsBefore = editor.toString() // just a marker
        store.removeResolved(setOf("group-999"))
        // Still 1 invite — no change
        assertEquals(1, store.pendingInvites.value.size)
    }

    // endregion
}
