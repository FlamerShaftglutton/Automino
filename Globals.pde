
class Globals
{
  NonGriddleFactory ngFactory = new NonGriddleFactory();
  GriddleFactory gFactory = new GriddleFactory();
  SpriteFactory sprites = new SpriteFactory();
  InteractionFactory interactions = new InteractionFactory();
  RuleFactory ruleFactory = new RuleFactory();
  GameFlowManager game = new GameFlowManager();
  MessageQueue messages = new MessageQueue();
  
  KeyboardManager keyboard = new KeyboardManager();
  
  boolean mouseReleased = false;
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

enum KeyState
{
  PRESSED,
  HELD,
  RELEASED,
  NONE
}
