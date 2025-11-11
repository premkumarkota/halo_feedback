package com.example.halo_feedback

import android.content.Context
import android.util.Log
import androidx.enterprise.feedback.KeyedAppState
import androidx.enterprise.feedback.KeyedAppStatesReporter

class KeyedAppStatesUtil {
    companion object {
        private const val TAG = "KeyedAppStatesUtil"

        fun appFeedback(context: Context, key: String, message: String) {
            try {
                Log.d(TAG, "Creating KeyedAppStatesReporter")
                val reporter = KeyedAppStatesReporter.create(context)

                Log.d(TAG, "Building KeyedAppState")
                val state = KeyedAppState.builder()
                    .setKey(key)
                    .setSeverity(KeyedAppState.SEVERITY_INFO)
                    .setMessage(message)
                    .setData(message)
                    .build()

                val states = HashSet<KeyedAppState>()
                states.add(state)

                Log.d(TAG, "Setting states immediately")
                reporter.setStatesImmediate(states)

                Log.d(TAG, "Feedback successfully reported")
            } catch (e: Exception) {
                Log.e(TAG, "appFeedback: ${e.message}", e)
            }
        }
    }
}

