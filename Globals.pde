
class Globals
{
  NonGriddleFactory ngFactory = new NonGriddleFactory();
  GriddleFactory gFactory = new GriddleFactory();
  SpriteFactory sprites = new SpriteFactory();
  InteractionFactory interactions = new InteractionFactory();
  RuleFactory ruleFactory = new RuleFactory();
  GameFlowManager game = new GameFlowManager();
  MessageQueue messages = new MessageQueue();
  ProfileManager profiles = new ProfileManager();
  
  KeyboardManager keyboard = new KeyboardManager();
  
  //boolean mouseReleased = false;
}










class Message
{
  String target;
  String value;
  Object sender;
  
  Message() { this("", "", null); }
  Message(String target, String value) { this(target,value,null); }
  Message(String target, String value, Object sender) { this.target = target; this.value = value; this.sender = sender; }
}

class MessageQueue
{
  ArrayList<Message> queue = new ArrayList<Message>();
  
  void post_message(Message message) { queue.add(message); }
  void post_message(String target, String value) { post_message(new Message(target, value)); }
  void post_message(String target, String value, Object sender) { post_message(new Message(target,value, sender)); }
  
  Message consume_message() { return isEmpty() ? null : queue.remove(0); }
  
  boolean isEmpty() { return queue.isEmpty(); }
}










class KeyboardManager
{
  HashMap<Integer, KeyState> keystates = new HashMap<Integer, KeyState>();
  HashMap<Integer, KeyState> codedkeystates = new HashMap<Integer, KeyState>();
  
  KeyState get_key(char k) { return keystates.getOrDefault(int(k), KeyState.NONE); }
  KeyState get_coded_key(int k) { return codedkeystates.getOrDefault(k, KeyState.NONE); }
  
  boolean is_key_pressed(char k)  { return keystates.getOrDefault(int(k), KeyState.NONE) == KeyState.PRESSED;  }
  boolean is_key_held(char k)     { return keystates.getOrDefault(int(k), KeyState.NONE) == KeyState.HELD;     }
  boolean is_key_released(char k) { return keystates.getOrDefault(int(k), KeyState.NONE) == KeyState.RELEASED; }
  boolean is_key_none(char k)     { return keystates.getOrDefault(int(k), KeyState.NONE) == KeyState.NONE;     }
  
  boolean is_coded_key_pressed(int k)  { return codedkeystates.getOrDefault(k, KeyState.NONE) == KeyState.PRESSED;  }
  boolean is_coded_key_held(int k)     { return codedkeystates.getOrDefault(k, KeyState.NONE) == KeyState.HELD;     }
  boolean is_coded_key_released(int k) { return codedkeystates.getOrDefault(k, KeyState.NONE) == KeyState.RELEASED; }
  boolean is_coded_key_none(int k)     { return codedkeystates.getOrDefault(k, KeyState.NONE) == KeyState.NONE;     }
  
  void handle_keyPressed()
  {
    if (key == CODED)
    {
      if (is_coded_key_none(keyCode))
        codedkeystates.put(keyCode, KeyState.PRESSED);
      else
        codedkeystates.put(keyCode, KeyState.HELD);
    }
    else
    {
      if (is_key_none(key))
        keystates.put(int(key), KeyState.PRESSED);
      else
        keystates.put(int(key), KeyState.HELD);
    }
  }
  
  void handle_keyReleased()
  {
    if (key == CODED)
      codedkeystates.put(keyCode, KeyState.RELEASED);
    else
      keystates.put(int(key), KeyState.RELEASED);
  }
  
  void update()
  { 
    for (Integer k : keystates.keySet()) 
    { 
      if (keystates.get(k) == KeyState.RELEASED) 
        keystates.put(k, KeyState.NONE); 
      
      if (keystates.get(k) == KeyState.PRESSED)
        keystates.put(k, KeyState.HELD);
    } 
  
    for (Integer c : codedkeystates.keySet()) 
    { 
      if (codedkeystates.get(c) == KeyState.RELEASED) 
        codedkeystates.put(c, KeyState.NONE); 
      if (codedkeystates.get(c) == KeyState.PRESSED)
        codedkeystates.put(c, KeyState.HELD);
    }
  }
}

class ProfileManager
{
  ArrayList<Profile> profiles = new ArrayList<Profile>();
  int current_profile = 0;
  String save_path;
  
  void load(String json_file)
  {
    JSONArray root = loadJSONArray(json_file);
    
    for (int i = 0; i < root.size(); ++i)
    {
      Profile p = new Profile();
      JSONObject o = root.getJSONObject(i);
      p.deserialize(o);
      profiles.add(p);
      
      if (o.getBoolean("default",false))
        current_profile = i;
    }
    
    save_path = json_file;
  }
  
  void save()
  {
    JSONArray root = new JSONArray();
    
    for (int i = 0; i < profiles.size(); ++i)
    {
      JSONObject o = profiles.get(i).serialize(); 
      if (i == current_profile)
        o.setBoolean("default",true);
      
      root.append(o);
    }
    
    saveJSONArray(root, save_path);
  }
  
  Profile add() { Profile p = new Profile(); profiles.add(p); return p; }
  
  void set_current(Profile p) { current_profile = profiles.indexOf(p); }
  
  Profile current() { return profiles.get(current_profile); }
  Profile get(String name) { for (Profile p : profiles) { if (p.name.equals(name)) return p; } return null; }
  Profile get(int index) { return profiles.get(index); }
  
  StringList get_names() { StringList retval = new StringList(); for (Profile p : profiles) retval.append(p.name); return retval; }
  
  int size() { return profiles.size(); }
}

class Profile
{
  String name;
  String sprite;
  StringList discovered_rules;
  int highest_round;
  
  void deserialize(JSONObject o)
  {
    name = o.getString("name","nullname");
    sprite = o.getString("sprite", "player red");
    discovered_rules = getStringList("discovered_rules", o);
    highest_round = o.getInt("highest_round",0);
  }
  
  JSONObject serialize()
  {
    JSONObject o = new JSONObject();
    o.setString("name", name);
    o.setString("sprite", sprite);
    o.setInt("highest_round", highest_round);
    o.setJSONArray("discovered_rules", new JSONArray(discovered_rules));
    return o;
  }
}

enum KeyState
{
  PRESSED,
  HELD,
  RELEASED,
  NONE
}
