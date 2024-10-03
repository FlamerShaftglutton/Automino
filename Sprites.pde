class SpriteFactory
{
  HashMap<String, PShape> sprites;
  
  void load(String sprite_folder)
  {
    sprites = new HashMap<String, PShape>();
    
    File dir = new File(sprite_folder);
    
    File[] files = dir.listFiles();
    
    for (File f : files)
    {
      if (f.isDirectory() || !f.getName().endsWith("svg"))
        continue;
      
      String name = f.getName().split("\\.")[0];
      
      PShape p = loadShape(f.getAbsolutePath());
      
      p.scale(1f/p.getWidth(), 1f/p.getHeight());
      p.setName(name);
      sprites.put(name, p);
    }
  }
  
  PShape get(String name) 
  { 
    if (!sprites.containsKey(name)) 
    { 
      println("No sprite found with name '" + name + "'. Using null sprite."); //<>//
      return sprites.get("null"); 
    }
    
    return sprites.get(name); 
  }
  
  PShape get(StringList names) 
  {
    PShape retval = createShape(GROUP);
    retval.setName("_GROUP");
    
    for (String name : names)
      retval.addChild(get(name)); //<>//
    
    return retval;
  }

  boolean has_sprite(String name) { return sprites.containsKey(name); }
  
  StringList get_sprite_names()
  {
    return new StringList(sprites.keySet());
  }
}
