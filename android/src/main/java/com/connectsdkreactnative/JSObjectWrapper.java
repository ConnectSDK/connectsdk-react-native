package com.connectsdkreactnative;

import org.json.JSONException;
import org.json.JSONObject;

import com.connectsdk.core.JSONSerializable;
import com.facebook.react.bridge.Callback;

public class JSObjectWrapper implements JSONSerializable {
    ConnectSDKModule module;
    Callback callbackContext;

    static long nextObjectId = 0;
    public String objectId;
    public String callbackId;

    public JSObjectWrapper(ConnectSDKModule module) {
        this.module = module;
        this.objectId = "object_" + Long.toString(++nextObjectId);
        this.callbackContext = null;
    }

    public void cleanup() {
    }

    public void setCallbackId(String callbackId) {
        this.callbackId = callbackId;
    }

    public void sendEvent(String event, Object ... objs) {
        module.sendEvent(callbackContext, callbackId, objs);
    }

    @Override
    public JSONObject toJSONObject() throws JSONException {
        JSONObject obj = new JSONObject();
        obj.put("objectId", objectId);
        return obj;
    }
}
