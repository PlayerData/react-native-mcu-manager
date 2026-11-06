package uk.co.playerdata.reactnativemcumanager

import expo.modules.kotlin.AppContext
import expo.modules.kotlin.jni.JavaScriptFunction

internal fun JavaScriptFunction<Any?>.invokeWithContext(appContext: AppContext, vararg args: Any?) {
  invoke(*args, converterContext = appContext)
}
