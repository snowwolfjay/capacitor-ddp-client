package fun.yuhj.plugins.ddp.client;

import android.util.Log;

public class DDPClient {
  private JWebsocketClient client = null;
  private boolean connected = false;
  private boolean connecting = false;
  private String ddpUrl = null;
  public static FloatTopPlugin instance = null;

  public String echo(String value) {
        Log.i("Echo", value);
        return value;
  }
  private void createWebsocketClient() {
    if (client != null) {
      if (connected || connecting) {
        return;
      } else {
        client.close();
      }
    }
    if (ddpUrl == null) {
      return;
    }
    URI uri = URI.create(ddpUrl);
    connecting = true;
    client = new JWebsocketClient(uri) {
      @Override
      public void onMessage(String message) {
        //message就是接收到的消息;
        Log.i("Message", message);
        super.onMessage(message);
        JSONObject resp;
        try {
          resp = new JSONObject(message);
        } catch (JSONException e) {
          e.printStackTrace();
          return;
        }
        String kind = getJSONValue(resp, "msg");
        Log.i("DDP MESSAGE ", kind);
        if (kind.equals("connected")) {
          connected = true;
          connecting = false;
          doCall();
          return;
        }
        if (kind.equals("ping")) {
          client.send("{\"msg\":\"pong\"}");
          return;
        }
        if (kind.equals("failed")) {
          connected = false;
          connecting = false;
          return;
        }
        if (kind.equals("result")) {
          String id = getJSONValue(resp, "id");
          Log.i("HANDLE DDP RESULT", message);
          int i = revokers.size();
          if (i < 1) return;
          Log.i("HANDLE DDP RESULT ID", id);
          for (int j = 0; j < i; j++) {
            DDPMethodInvoker r = revokers.get(j);
            if (id.equals(r.id)) {
              revokers.remove(r);
              Log.e("DDP REVOKE-------------", r.id + " left " + revokers.size());
              String error = getJSONValue(resp,"error");
              if(error == null){
                r.onSuccess(resp);
              }else{
                r.onError(error);
              }
              return;
            }
          }
          return;
        }
        if (kind.equals("added")) {
          String col = getJSONValue(resp, "collection");
          String id = getJSONValue(resp, "id");
          String fields = getJSONValue(resp, "fields");
          cp.handleCollectAdd(col, id, fields);
        }
      }

      private String getJSONValue(JSONObject source, String key) {
        try {
          return source.getString(key);
        } catch (JSONException e) {
          e.printStackTrace();
          return null;
        }
      }

      @Override
      public void onOpen(ServerHandshake handshakedata) {
        super.onOpen(handshakedata);
        client.send("{\"msg\":\"connect\",\"version\":\"1\",\"support\":[\"1\",\"pre2\",\"pre1\"]}");
        if (!hasLogin && token != null) {
          callMethod(new DDPMethodInvoker("login", getLoginParams()) {
            @Override
            public void onSuccess(JSONObject d) {
              super.onSuccess(d);
              Log.e("DDP Login", "SUCCESS-------------");
              onLogin();
            }

            @Override
            public void onError(String d) {
              super.onError(d);
              onLogout();
              Log.e("DDP Login", "FAIL-------------");
            }
          });
        }
      }

      @Override
      public void onClose(int code, String reason, boolean remote) {
        connected = false;
        connecting = false;
        hasLogin = false;
        Log.e("WEBSOCKET----", "CLOSED ---"+ code + " -- " + reason);
        Timer timer = new Timer();
        timer.schedule(new TimerTask() {
          @Override
          public void run() {
            createWebsocketClient();
          }
        }, 5000);
      }
    };
    client.connect();
  }
}
