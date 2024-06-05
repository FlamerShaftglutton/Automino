Globals globals = new Globals();

void setup()
{
  size(1000,800);
  
  initglobals();
}

void draw()
{
  background(200);
  
  globals.game.active().update();
  globals.game.active().draw();
  
  globals.mouseReleased = false;
  globals.keyReleased = false;
}


void initglobals()
{
  globals.sprites.load(dataPath(""));
  globals.ngFactory.load(dataPath("NonGriddles.json"));
  globals.gFactory.load(dataPath("Griddles.json"));
  globals.interactions.load(dataPath("Interactions.json"));
  globals.ruleFactory.load(dataPath("Rules.json"));
  
  MainMenuGameFlow mm = new MainMenuGameFlow();
  mm.save_path = dataPath("menu.json");
  globals.game.push(mm);
}

void mouseReleased()
{
  globals.mouseReleased = true;
}

void keyReleased()
{
  globals.keyReleased = true;
}
