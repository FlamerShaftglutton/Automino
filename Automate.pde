Globals globals = new Globals();

void setup()
{
  size(1920,1080);
  
  initglobals();
}

void draw()
{
  background(200);
  
  globals.game.active().update();
  globals.game.active().draw();
  
  //globals.mouseReleased = false;
  globals.keyboard.update();
  
  //DEBUG
  //fill(#000000);
  //textSize(14);
  //text("" + mouseX + ", " + mouseY, width - 60f, 25f);
}


void initglobals()
{
  globals.sprites.load(dataPath(""));
  globals.ngFactory.load(dataPath("NonGriddles.json"));
  globals.gFactory.load(dataPath("Griddles.json"));
  globals.interactions.load(dataPath("Interactions.json"));
  globals.ruleFactory.load(dataPath("Rules.json"));
  globals.profiles.load(dataPath("Profiles.json"));
  
  MainMenuGameFlow mm = new MainMenuGameFlow();
  mm.save_path = dataPath("menu.json");
  globals.game.push(mm);
}

//void mouseReleased()
//{
//  globals.mouseReleased = true;
//}

void keyPressed()
{
  globals.keyboard.handle_keyPressed();
}

void keyReleased()
{
  globals.keyboard.handle_keyReleased();
}


String save_filename()
{
  String retval = "save_";
  
  retval += right("0000" + year(),4);
  retval += right("00" + month(),2);
  retval += right("00" + day(),2);
  retval += right("00" + hour(),2);
  retval += right("00" + minute(),2);
  retval += right("00" + second(),2);
  
  retval += ".json";
  
  return retval;
}
