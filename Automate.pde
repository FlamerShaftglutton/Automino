Globals globals = new Globals();

void setup()
{
  size(1000,800);
  
  initglobals();
}

void draw()
{
  background(200);
  
  update();
  
  globals.active_grid.draw();

  for (NonGriddle ng : globals.nongriddles)
    ng.draw();
  
  globals.mouseReleased = false;
  globals.keyReleased = false;
  
  if (globals.loading)
  {
    globals.session = new GameSession();
    globals.session.load(dataPath(globals.load_file_path));
    //globals.active_grid = new Grid(new PVector(100f,100f), new PVector(800,600f));
    //globals.active_grid.deserialize(dataPath(globals.load_file_path));
    globals.loading = false;
  }
  
  if (globals.newgame)
  {
    globals.session = new GameSession();
    globals.session.create_new();
    globals.session.save_path = "Game1.json";
    globals.newgame = false;
  }
  
  //text(""+globals.nongriddles.size(), 900, 50);
}

void update()
{
  if (globals.session == null)
    globals.active_grid.update();
  else
    globals.session.update();
  
  for (NonGriddle dng : globals.nongriddles_to_delete)
    globals.nongriddles.remove(dng);
  
  globals.nongriddles_to_delete.clear();
  
  //for (NonGriddle ng : globals.nongriddles)
  //  ng.update();
}

void initglobals()
{
  globals.sprites.load(dataPath(""));
  globals.ngFactory.load(dataPath("NonGriddles.json"));
  globals.gFactory.load(dataPath("Griddles.json"));
  globals.interactions.load(dataPath("Interactions.json"));
  
  globals.active_grid = new Grid(new PVector(100f,100f), new PVector(800,600f));
  globals.active_grid.deserialize(loadJSONObject(dataPath("menu.json")));
  
  //create_level_editor_ngs();
}

//void create_level_editor_ngs()
//{
//  for(String s : globals.gFactory.templates.keySet())
//  {
//    globals.ngFactory.add_ng_template("__LevelEditor__" + s, globals.gFactory.templates.get(s).base.getString("sprite"));
//  }
//}

void mouseReleased()
{
  globals.mouseReleased = true;
}

void keyReleased()
{
  //if (key == 's')
  //  globals.active_grid.save(dataPath("layout.json"));
  
  globals.keyReleased = true;
}


void translate(PVector p) { translate(p.x,p.y); }

void fileSelected(File selection)
{
  if (selection != null)
  {
    globals.saving = true;
    globals.save_file_path = selection.getAbsolutePath();
  }
}
