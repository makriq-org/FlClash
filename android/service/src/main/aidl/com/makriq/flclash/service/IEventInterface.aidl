// IEventInterface.aidl
package com.makriq.flclash.service;

import com.makriq.flclash.service.IAckInterface;

interface IEventInterface {
    oneway void onEvent(in String id, in byte[] data,in boolean isSuccess, in IAckInterface ack);
}