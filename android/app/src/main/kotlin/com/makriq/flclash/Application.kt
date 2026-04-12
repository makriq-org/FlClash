package com.makriq.flclash

import android.app.Application
import android.content.Context
import com.makriq.flclash.common.GlobalState

class Application : Application() {

    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }
}
