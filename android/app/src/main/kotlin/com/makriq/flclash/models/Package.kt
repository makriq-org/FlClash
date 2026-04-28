package com.makriq.flclash.models

data class Package(
    val packageName: String,
    val label: String,
    val system: Boolean,
    val internet: Boolean,
    val lastUpdateTime: Long,
)
