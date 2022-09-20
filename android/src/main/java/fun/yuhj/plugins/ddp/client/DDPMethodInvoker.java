package fun.yuhj.plugins.ddp.client;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;

import org.json.JSONObject;

public class DDPMethodInvoker {
  private static int reqId = 1;
  public JSObject params;
  public JSArray paramsArray;
  public String name;
  public String id;
  public String key;

  public DDPMethodInvoker(String name, JSArray params, String key) {
    this.name = name;
    this.paramsArray = params;
    this.id = "" + DDPMethodInvoker.reqId++;
    this.key = key;
  }

  public DDPMethodInvoker(String name, JSArray params) {
    this.name = name;
    this.paramsArray = params;
    this.id = "" + DDPMethodInvoker.reqId++;
  }

  public void onSuccess(JSONObject data) {

  }

  public void onError(String str) {

  }
}
