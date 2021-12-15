package com.connectsdkreactnative;

import androidx.annotation.NonNull;

import java.util.ArrayList;

import org.jetbrains.annotations.NotNull;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.connectsdk.device.ConnectableDevice;
import com.connectsdk.discovery.CapabilityFilter;
import com.connectsdk.discovery.DiscoveryManager;
import com.connectsdk.discovery.DiscoveryManager.PairingLevel;
import com.connectsdk.discovery.DiscoveryManagerListener;
import com.connectsdk.service.command.ServiceCommandError;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;

public class DiscoveryManagerWrapper extends ReactContextBaseJavaModule implements DiscoveryManagerListener {
    ConnectSDKModule module;
    DiscoveryManager discoveryManager;
    Callback callbackContext;

    @NonNull
    @NotNull
    @Override
    public String getName() {
        return "DiscoveryManager";
    }

    DiscoveryManagerWrapper(ConnectSDKModule module, DiscoveryManager discoveryManager) {
        this.module = module;

        this.discoveryManager = discoveryManager;
        discoveryManager.addListener(this);
    }

    public void setCallbackContext(Callback callbackContext) {
        this.callbackContext = callbackContext;
    }

    public void start() {
        discoveryManager.start();
    }

    public void stop() {
        discoveryManager.stop();
    }

    public void configure(JSONObject config) throws JSONException {
        if (config.has("pairingLevel")) {
            String pairingLevel = config.getString("pairingLevel");

            if ("off".equals(pairingLevel)) {
                discoveryManager.setPairingLevel(PairingLevel.OFF);
            } else if ("on".equals(pairingLevel)) {
                discoveryManager.setPairingLevel(PairingLevel.ON);
            }
        }

        if (config.has("capabilityFilters")) {
            JSONArray filters = config.getJSONArray("capabilityFilters");
            ArrayList<CapabilityFilter> capabilityFilters = new ArrayList<>();

            for (int i = 0; i < filters.length(); i++) {
                JSONArray filter = filters.getJSONArray(i);
                CapabilityFilter capabilityFilter = new CapabilityFilter();

                for (int j = 0; j < filter.length(); j++) {
                    capabilityFilter.addCapability(filter.getString(j));
                }

                capabilityFilters.add(capabilityFilter);
            }

            discoveryManager.setCapabilityFilters(capabilityFilters);
        }
    }

    @Override
    public void onDeviceAdded(DiscoveryManager manager, ConnectableDevice device) {
        sendDeviceEvent("devicefound", device);
    }

    @Override
    public void onDeviceUpdated(DiscoveryManager manager, ConnectableDevice device) {
        sendDeviceEvent("deviceupdated", device);
    }

    @Override
    public void onDeviceRemoved(DiscoveryManager manager, ConnectableDevice device) {
        sendDeviceEvent("devicelost", device);
        module.removeDeviceWrapper(device);
    }

    @Override
    public void onDiscoveryFailed(DiscoveryManager manager, ServiceCommandError error) {
        if (callbackContext != null) {
            module.error(callbackContext, error);
        }
    }

    public JSONObject getDeviceJSON(ConnectableDevice device) {
        ConnectableDeviceWrapper wrapper = module.getDeviceWrapper(device);
        return wrapper.toJSONObject();
    }

    public void sendDeviceEvent(String event, ConnectableDevice device) {
        JSONObject obj = new JSONObject();
        try {
            obj.put("device", getDeviceJSON(device));
        } catch (JSONException e) {
        }

        sendEvent(event, obj);
    }

    public void sendEvent(String event, JSONObject obj) {
        if (callbackContext != null) {
            module.sendEvent(callbackContext, event, obj);
        }
    }

    @ReactMethod
    void startDiscovery(ReadableMap mapArgs, final Callback Callback) throws JSONException {
        JSONObject args = ConnectSDKModule.convertMapToJson(mapArgs);

        if (args != null && args.length() > 0) {
            configure(args);
        }

        setCallbackContext(Callback);
        start();
    }

    @ReactMethod
    void stopDiscovery(JSONArray args, final Callback Callback) throws JSONException {
        stop();
        module.success(Callback);
    }
}
