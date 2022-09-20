package fun.yuhj.plugins.ddp.client;

import java.util.ArrayList;
import java.util.HashMap;

public class MongoCollection {
  static ArrayList<MongoCollection> collections = new ArrayList<MongoCollection>();
  public String name;
  private final HashMap items = new HashMap<String, String>();
  MongoCollection(String n) {
    name = n;
  }

  public static MongoCollection getInstance(String col) {
    int i = MongoCollection.collections.size();
    for (int j = 0; j < i; j++) {
      MongoCollection c = MongoCollection.collections.get(j);
      if (c.name.equals(col)) {
        return c;
      }
    }
    MongoCollection newOne = new MongoCollection(col);
    MongoCollection.collections.add(newOne);
    return newOne;
  }

  public MongoCollection add(String id, String fields) {
    items.put(id, fields);
    return MongoCollection.this;
  }
}
