package org.findmyfam

import android.content.Context
import io.mockk.every
import io.mockk.mockk
import org.findmyfam.models.AppSettings
import org.findmyfam.services.AppLockService
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class AppLockServiceTest {

    private lateinit var settings: AppSettings
    private lateinit var service: AppLockService

    @Before
    fun setUp() {
        settings = mockk(relaxed = true) {
            every { isAppLockEnabled } returns false
            every { isAppLockReauthOnForeground } returns false
        }
        val context = mockk<Context>(relaxed = true)
        service = AppLockService(context, settings)
    }

    // region onLaunch

    @Test
    fun `onLaunch with lock disabled does not lock`() {
        every { settings.isAppLockEnabled } returns false
        service.onLaunch()
        assertFalse(service.isLocked.value)
    }

    @Test
    fun `onLaunch with lock enabled locks the app`() {
        every { settings.isAppLockEnabled } returns true
        service.onLaunch()
        assertTrue(service.isLocked.value)
    }

    // endregion

    // region onResume

    @Test
    fun `onResume with lock disabled always unlocks`() {
        every { settings.isAppLockEnabled } returns false
        service.onResume()
        assertFalse(service.isLocked.value)
    }

    @Test
    fun `onResume with lock enabled and no prior unlock locks`() {
        every { settings.isAppLockEnabled } returns true
        service.onResume()
        assertTrue(service.isLocked.value)
    }

    @Test
    fun `onResume after onLaunch without lock stays unlocked on resume`() {
        every { settings.isAppLockEnabled } returns false
        service.onLaunch()
        // Now enable lock and resume
        every { settings.isAppLockEnabled } returns true
        service.onResume()
        // hasUnlockedThisSession is true (set in onLaunch when lock disabled)
        // and reauthOnForeground is false → stays unlocked
        assertFalse(service.isLocked.value)
    }

    @Test
    fun `onResume with reauth on foreground locks even after unlock`() {
        every { settings.isAppLockEnabled } returns false
        service.onLaunch() // sets hasUnlockedThisSession = true
        every { settings.isAppLockEnabled } returns true
        every { settings.isAppLockReauthOnForeground } returns true
        service.onResume()
        // reauthOnForeground overrides hasUnlockedThisSession
        assertTrue(service.isLocked.value)
    }

    // endregion

    // region initial state

    @Test
    fun `initial state is unlocked with no errors`() {
        assertFalse(service.isLocked.value)
        assertFalse(service.isAuthenticating.value)
        assertNull(service.errorMessage.value)
    }

    // endregion
}
