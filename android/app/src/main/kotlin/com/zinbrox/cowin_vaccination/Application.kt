package com.zinbrox.cowin_vaccination

import io.flutter.app.FlutterApplication
import io.flutter.plugins.androidalarmmanager.AlarmService
import io.flutter.plugins.androidalarmmanager.AndroidAlarmManagerPlugin


class Application : FlutterApplication(), io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback {

    override fun onCreate() {
        super.onCreate()
        // AlarmService.setPluginRegistrant(this)
    }

    override fun registerWith(registry: io.flutter.plugin.common.PluginRegistry) {
        AndroidAlarmManagerPlugin.registerWith(
                registry.registrarFor("io.flutter.plugins.androidalarmmanager.AndroidAlarmManagerPlugin"))
        AndroidAlarmManagerPlugin.registerWith(
                registry.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"))
        AndroidAlarmManagerPlugin.registerWith(
                registry.registrarFor("io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin"))
    }
}