package org.findmyfam.ui.common

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.findmyfam.R
import org.findmyfam.viewmodels.AppViewModel.StartupPhase

@Composable
fun SplashScreen(phase: StartupPhase) {
    val screenWidth = LocalConfiguration.current.screenWidthDp.dp

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxSize()
        ) {
            Spacer(modifier = Modifier.weight(1f))

            Image(
                painter = painterResource(id = R.drawable.whistle_logo),
                contentDescription = "Whistle",
                modifier = Modifier.width(screenWidth * 0.55f),
                contentScale = ContentScale.FillWidth,
                colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.onBackground)
            )

            Spacer(modifier = Modifier.weight(1f))

            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    strokeWidth = 2.dp
                )

                Spacer(modifier = Modifier.height(14.dp))

                val statusText = when (phase) {
                    StartupPhase.SPLASH -> "Starting…"
                    StartupPhase.CONNECTING -> "Connecting to relays…"
                    StartupPhase.INITIALISING_ENCRYPTION -> "Initialising encryption…"
                    StartupPhase.LOADING_GROUPS -> "Loading groups…"
                    StartupPhase.READY -> "Ready"
                }

                Text(
                    text = statusText,
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(56.dp))
        }
    }
}
