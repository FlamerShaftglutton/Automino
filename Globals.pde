
class Globals
{
  Grid active_grid;
  ArrayList<NonGriddle> nongriddles = new ArrayList<NonGriddle>();
  ArrayList<NonGriddle> nongriddles_to_delete = new ArrayList<NonGriddle>();
  NonGriddleFactory ngFactory = new NonGriddleFactory();
  GriddleFactory gFactory = new GriddleFactory();
  SpriteFactory sprites = new SpriteFactory();
  InteractionFactory interactions = new InteractionFactory();
  GameSession session = null;
  
  
  boolean newgame = false;
  boolean loading = false;
  boolean saving  = false;
  String load_file_path;
  String save_file_path;
  
  boolean mouseReleased = false;
  boolean keyReleased = false;
  
  NonGriddle create_and_register_ng(String name)
  {
    NonGriddle retval = ngFactory.create_ng(name);
    
    register_ng(retval);
    
    return retval;
  }
  
  void register_ng(NonGriddle ng) { nongriddles.add(ng); }
  
  void destroy_ng(NonGriddle ng)
  {
    nongriddles_to_delete.add(ng);
  }
}
