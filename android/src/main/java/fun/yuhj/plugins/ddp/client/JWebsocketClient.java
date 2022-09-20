package fun.yuhj.plugins.ddp.client;

import android.util.Log;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft_6455;
import org.java_websocket.handshake.ServerHandshake;

import java.net.URI;

public class JWebsocketClient extends WebSocketClient {
  public JWebsocketClient(URI serverUri) {
    super(serverUri, new Draft_6455());
  }

  @Override
  public void onOpen(ServerHandshake handshakedata) {
    Log.e("JWebSocketClient", "onOpen()");
  }

  @Override
  public void onMessage(String message) {
    Log.e("JWebSocketClient", "onMessage():" + message);
  }

  @Override
  public void onClose(int code, String reason, boolean remote) {
    Log.e("JWebSocketClient", "onClose() " + code + " reason" + reason);
  }

  @Override
  public void onError(Exception ex) {
    Log.e("JWebSocketClient", "onError()" + ex.getMessage());
  }
}
