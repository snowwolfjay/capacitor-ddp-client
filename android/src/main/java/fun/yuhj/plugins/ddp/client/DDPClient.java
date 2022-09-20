package fun.yuhj.plugins.ddp.client;

import android.util.Log;

public class DDPClient {

    public String echo(String value) {
        Log.i("Echo", value);
        return value;
    }
}
