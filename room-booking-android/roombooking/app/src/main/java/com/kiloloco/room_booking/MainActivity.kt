package com.kiloloco.room_booking

import android.content.Context
import android.os.Bundle
import android.util.AttributeSet
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.material.Button
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.setContent
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.navigate
import androidx.navigation.compose.rememberNavController
import com.kiloloco.room_booking.ui.RoombookingTheme

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            RoombookingTheme {
                RoomBookingApp()
            }
        }
    }
}

@Composable
fun RoomBookingApp() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = "home") {
        composable("home") { StartView(navController) }
        composable("second") { SecondView(navController) }
    }
}

@Composable
fun StartView(navController: NavController) {
    Button(onClick = { navController.navigate("second") }) {
        Text("Get started")
    }
}

@Composable
fun SecondView(navController: NavController) {
    Text("Second View")
}