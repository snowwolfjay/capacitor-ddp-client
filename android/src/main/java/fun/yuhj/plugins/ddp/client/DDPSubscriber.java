package fun.yuhj.plugins.ddp.client;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;

public class DDPSubscriber {
  private static int sid = 100000;
  private final String sname;
  private final JSArray sparams;
  private final String id = DDPSubscriber.getId();

  public DDPSubscriber(String name, JSArray params) {
    sname = name;
    sparams = params;
  }

  public static String getId() {
    sid++;
    return sid + "";
  }

  public static DDPSubscriber subCall(JWebsocketClient client) {
    DDPSubscriber sub = new DDPSubscriber("webrtc.p2pcall", new JSArray());

    return sub;
  }

  public String pack(boolean forSub) {
    JSObject req = new JSObject();
    if (forSub) {
      req.put("msg", "sub");
      req.put("name", sname);
      req.put("id", id);
      req.put("params", sparams);
    } else {
      req.put("msg", "unsub");
      req.put("id", id);
    }
    return req.toString();
  }
}
