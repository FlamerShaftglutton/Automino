
class Globals
{
  NonGriddleFactory ngFactory = new NonGriddleFactory();
  GriddleFactory gFactory = new GriddleFactory();
  SpriteFactory sprites = new SpriteFactory();
  InteractionFactory interactions = new InteractionFactory();
  GameFlowManager game = new GameFlowManager();
  MessageQueue messages = new MessageQueue();
  
  boolean mouseReleased = false;
  boolean keyReleased = false;
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
