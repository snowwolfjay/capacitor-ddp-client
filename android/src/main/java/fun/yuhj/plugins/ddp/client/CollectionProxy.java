package fun.yuhj.plugins.ddp.client;


public abstract class CollectionProxy {
  public void handleCollectAdd(String colName, String id, String fields) {
    MongoCollection col = MongoCollection.getInstance(colName);
    col.add(id, fields);
    onCollectionAdd(colName, id);
  }

  public void onCollectionAdd(String colName, String id) {
    //
  }

}
