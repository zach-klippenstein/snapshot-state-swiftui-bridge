package com.zachklipp.kmpswiftuitest

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform