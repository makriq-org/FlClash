package com.makriq.flclash.service

import com.makriq.flclash.common.BroadcastAction
import com.makriq.flclash.common.GlobalState
import com.makriq.flclash.common.sendBroadcast

interface IBaseService {
    fun handleCreate() {
        GlobalState.log("Service create")
        BroadcastAction.SERVICE_CREATED.sendBroadcast()
    }

    fun handleDestroy() {
        GlobalState.log("Service destroy")
        BroadcastAction.SERVICE_DESTROYED.sendBroadcast()
    }

    fun start()

    fun stop()
}