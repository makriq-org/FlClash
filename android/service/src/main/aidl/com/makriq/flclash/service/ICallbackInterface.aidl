// ICallbackInterface.aidl
package com.makriq.flclash.service;

import com.makriq.flclash.service.IAckInterface;

interface ICallbackInterface {
    oneway void onResult(in byte[] data,in boolean isSuccess, in IAckInterface ack);
}