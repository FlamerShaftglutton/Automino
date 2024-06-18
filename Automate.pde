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
  globals.keyboard.update();
  
  fill(#000000);
  textSize(14);
  
  //DEBUG
  //text("" + mouseX + ", " + mouseY, width - 60f, 25f);
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

void keyPressed()
{
  globals.keyboard.handle_keyPressed();
}

void keyReleased()
{
  globals.keyboard.handle_keyReleased();
}
