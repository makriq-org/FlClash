// IRemoteInterface.aidl
package com.makriq.flclash.service;

import com.makriq.flclash.service.ICallbackInterface;
import com.makriq.flclash.service.IEventInterface;
import com.makriq.flclash.service.IResultInterface;
import com.makriq.flclash.service.IVoidInterface;
import com.makriq.flclash.service.models.VpnOptions;
import com.makriq.flclash.service.models.NotificationParams;

interface IRemoteInterface {
    void invokeAction(in String data, in ICallbackInterface callback);
    void quickSetup(in String initParamsString, in String setupParamsString, in ICallbackInterface callback, in IVoidInterface onStarted);
    void updateNotificationParams(in NotificationParams params);
    void startService(in VpnOptions options, in long runTime, in IResultInterface result);
    void stopService(in IResultInterface result);
    void setEventListener(in IEventInterface event);
    void setCrashlytics(in boolean enable);
    long getRunTime();
}