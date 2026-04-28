package com.makriq.flclash.service

import android.content.Intent
import android.net.ConnectivityManager
import android.net.ProxyInfo
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.Parcel
import android.os.RemoteException
import android.util.Log
import androidx.core.content.getSystemService
import com.makriq.flclash.common.AccessControlMode
import com.makriq.flclash.common.GlobalState
import com.makriq.flclash.core.Core
import com.makriq.flclash.service.models.VpnOptions
import com.makriq.flclash.service.models.getIpv4RouteAddress
import com.makriq.flclash.service.models.getIpv6RouteAddress
import com.makriq.flclash.service.models.toCIDR
import com.makriq.flclash.service.modules.NetworkObserveModule
import com.makriq.flclash.service.modules.NotificationModule
import com.makriq.flclash.service.modules.SuspendModule
import com.makriq.flclash.service.modules.moduleLoader
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import java.net.InetSocketAddress
import java.security.SecureRandom
import android.net.VpnService as SystemVpnService

class VpnService : SystemVpnService(), IBaseService,
    CoroutineScope by CoroutineScope(Dispatchers.Default) {

    private data class TunnelAddresses(
        val session: String,
        val ipv4: String,
        val dns4: String,
        val ipv6: String,
        val dns6: String,
    ) {
        fun address(ipv6Enabled: Boolean): String {
            return buildString {
                append(ipv4)
                if (ipv6Enabled) {
                    append(",")
                    append(ipv6)
                }
            }
        }

        fun dns(ipv6Enabled: Boolean, dnsHijacking: Boolean): String {
            if (dnsHijacking) {
                return "0.0.0.0"
            }
            return buildString {
                append(dns4)
                if (ipv6Enabled) {
                    append(",")
                    append(dns6)
                }
            }
        }
    }

    private val self: VpnService
        get() = this

    private val loader = moduleLoader {
        install(NetworkObserveModule(self))
        install(NotificationModule(self))
        install(SuspendModule(self))
    }

    override fun onCreate() {
        super.onCreate()
        handleCreate()
    }

    override fun onDestroy() {
        handleDestroy()
        super.onDestroy()
    }

    private val connectivity by lazy {
        getSystemService<ConnectivityManager>()
    }
    private val uidPageNameMap = mutableMapOf<Int, String>()

    private fun resolverProcess(
        protocol: Int,
        source: InetSocketAddress,
        target: InetSocketAddress,
        uid: Int,
    ): String {
        val nextUid = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            connectivity?.getConnectionOwnerUid(protocol, source, target) ?: -1
        } else {
            uid
        }
        if (nextUid == -1) {
            return ""
        }
        if (!uidPageNameMap.containsKey(nextUid)) {
            uidPageNameMap[nextUid] = this.packageManager?.getPackagesForUid(nextUid)?.first() ?: ""
        }
        return uidPageNameMap[nextUid] ?: ""
    }

    override fun onLowMemory() {
        Core.forceGC()
        super.onLowMemory()
    }

    private val binder = LocalBinder()

    inner class LocalBinder : Binder() {
        fun getService(): VpnService = this@VpnService

        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            try {
                val isSuccess = super.onTransact(code, data, reply, flags)
                if (!isSuccess) {
                    GlobalState.log("VpnService disconnected")
                    handleDestroy()
                }
                return isSuccess
            } catch (e: RemoteException) {
                GlobalState.log("VpnService onTransact $e")
                return false
            }
        }
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    private fun createTunnelAddresses(): TunnelAddresses {
        val random = SecureRandom()
        val second = 16 + random.nextInt(16)
        val third = random.nextInt(256)
        val fourthBase = random.nextInt(64) * 4
        val ipv4 = "172.$second.$third.${fourthBase + 1}/30"
        val dns4 = "172.$second.$third.${fourthBase + 2}"
        val h1 = random.nextInt(0x10000)
        val h2 = random.nextInt(0x10000)
        val h3 = random.nextInt(0x10000)
        val h4 = random.nextInt(0x10000)
        val prefix = "fd%04x:%04x:%04x:%04x".format(h1, h2, h3, h4)
        return TunnelAddresses(
            session = "VPN",
            ipv4 = ipv4,
            dns4 = dns4,
            ipv6 = "$prefix::1/126",
            dns6 = "$prefix::2",
        )
    }

    private fun handleStart(options: VpnOptions) {
        val tunnelAddresses = createTunnelAddresses()
        val fd = with(Builder()) {
            val cidr = tunnelAddresses.ipv4.toCIDR()
            addAddress(cidr.address, cidr.prefixLength)
            Log.d(
                "addAddress", "address: ${cidr.address} prefixLength:${cidr.prefixLength}"
            )
            val routeAddress = options.getIpv4RouteAddress()
            if (routeAddress.isNotEmpty()) {
                try {
                    routeAddress.forEach { i ->
                        Log.d(
                            "addRoute4", "address: ${i.address} prefixLength:${i.prefixLength}"
                        )
                        addRoute(i.address, i.prefixLength)
                    }
                } catch (_: Exception) {
                    addRoute(NET_ANY, 0)
                }
            } else {
                addRoute(NET_ANY, 0)
            }
            if (options.ipv6) {
                try {
                    val cidr = tunnelAddresses.ipv6.toCIDR()
                    Log.d(
                        "addAddress6", "address: ${cidr.address} prefixLength:${cidr.prefixLength}"
                    )
                    addAddress(cidr.address, cidr.prefixLength)
                } catch (_: Exception) {
                    Log.d(
                        "addAddress6", "IPv6 is not supported."
                    )
                }

                try {
                    val routeAddress = options.getIpv6RouteAddress()
                    if (routeAddress.isNotEmpty()) {
                        try {
                            routeAddress.forEach { i ->
                                Log.d(
                                    "addRoute6",
                                    "address: ${i.address} prefixLength:${i.prefixLength}"
                                )
                                addRoute(i.address, i.prefixLength)
                            }
                        } catch (_: Exception) {
                            addRoute("::", 0)
                        }
                    } else {
                        addRoute(NET_ANY6, 0)
                    }
                } catch (_: Exception) {
                    addRoute(NET_ANY6, 0)
                }
            }
            addDnsServer(tunnelAddresses.dns4)
            if (options.ipv6) {
                addDnsServer(tunnelAddresses.dns6)
            }
            setMtu(9000)
            options.accessControlProps.let { accessControl ->
                if (accessControl.enable) {
                    when (accessControl.mode) {
                        AccessControlMode.ACCEPT_SELECTED -> {
                            (accessControl.acceptList + packageName).forEach {
                                addAllowedApplication(it)
                            }
                        }

                        AccessControlMode.REJECT_SELECTED -> {
                            (accessControl.rejectList - packageName).forEach {
                                addDisallowedApplication(it)
                            }
                        }
                    }
                }
            }
            setSession(tunnelAddresses.session)
            setBlocking(false)
            if (Build.VERSION.SDK_INT >= 29) {
                setMetered(false)
            }
            if (options.allowBypass) {
                allowBypass()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && options.systemProxy) {
                GlobalState.log("Open http proxy")
                setHttpProxy(
                    ProxyInfo.buildDirectProxy(
                        "127.0.0.1", options.port, options.bypassDomain
                    )
                )
            }
            establish()?.detachFd()
                ?: throw NullPointerException("Establish VPN rejected by system")
        }
        Core.startTun(
            fd,
            protect = this::protect,
            resolverProcess = this::resolverProcess,
            options.stack,
            tunnelAddresses.address(options.ipv6),
            tunnelAddresses.dns(options.ipv6, options.dnsHijacking)
        )
    }

    override fun start() {
        try {
            loader.load()
            State.options?.let {
                handleStart(it)
            }
        } catch (_: Exception) {
            stop()
        }
    }

    override fun stop() {
        loader.cancel()
        Core.stopTun()
        stopSelf()
    }

    companion object {
        private const val NET_ANY = "0.0.0.0"
        private const val NET_ANY6 = "::"
    }
}
