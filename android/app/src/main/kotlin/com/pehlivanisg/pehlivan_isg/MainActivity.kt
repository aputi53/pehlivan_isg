package com.pehlivanisg.pehlivan_isg

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.pehlivanisg.pehlivan_isg/location"
    private val LOCATION_PERMISSION_CODE = 100
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        val fine = Manifest.permission.ACCESS_FINE_LOCATION
                        val coarse = Manifest.permission.ACCESS_COARSE_LOCATION

                        val alreadyGranted =
                            ContextCompat.checkSelfPermission(this, fine) ==
                                    PackageManager.PERMISSION_GRANTED

                        if (alreadyGranted) {
                            result.success(true)
                        } else {
                            pendingResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(fine, coarse),
                                LOCATION_PERMISSION_CODE
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == LOCATION_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED

            pendingResult?.success(granted)
            pendingResult = null
        }
    }
}