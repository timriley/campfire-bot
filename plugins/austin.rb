require 'open-uri'
require 'hpricot'

class Austin < PluginBase
  BASE_URL = 'http://www.imdb.com/character/ch0002425/quotes'
  
  on_command 'austin', :austin
  
  def austin(msg)
    doc = Hpricot(open(BASE_URL))
    chunks = []
    doc.traverse_element("br") {|b| chunks << b if b.next_node != nil && b.next_node.elem? && b.next_node.to_s == '<br />' }
    chunks.pop
    random_chunk = rand(chunks.size - 1)
    raw_quote = chunks[random_chunk].nodes_at(2..(chunks[random_chunk + 1].node_position - chunks[random_chunk].node_position - 1))
    quote = raw_quote.to_s
    quote.gsub!(/(\\n)/, "")
    quote.gsub!(/(<br \/>)/, "\n")
    quote.gsub!(/^\s/, "")
    quote.gsub!(/ {2,}/, " ")
    quote.gsub!(/<\/?[^>]*>/, "")
    quote.split("\n")
    
    quote.each {|l| speak l}
    
  rescue
    speak 'Austin Powers: Yeah, baby, yeah'
  end
end