require 'open-uri'
require 'hpricot'

class BeijingTally < CampfireBot::Plugin
  
  on_command 'tally', :tally
  
  def tally(msg)
    output    = "#{'Pos.'.rjust(6)} - #{'Country'.ljust(25)} -   G -   S -   B - Total\n"
    rows      = ((Hpricot(open('http://results.beijing2008.cn/WRM/ENG/INF/GL/95A/GL0000000.shtml'))/'//table')[1]/'tr')[2..-1]
    rows.each_with_index do |row, i|
      cells   = row/'td'
      output += "#{strip_tags_or_zero(cells[0].inner_html).rjust(6)} - " # position
      output += "#{((i == rows.length - 1) ? '' : strip_tags_or_zero(cells[1].inner_html)).ljust(25)} - " # country
      output += "#{strip_tags_or_zero(cells[-5].inner_html).rjust(3)} - " # gold
      output += "#{strip_tags_or_zero(cells[-4].inner_html).rjust(3)} - " # silver
      output += "#{strip_tags_or_zero(cells[-3].inner_html).rjust(3)} - " # bronze
      output += "#{strip_tags_or_zero(cells[-2].inner_html).rjust(3)}\n"  # total
    end
    
    msg.paste(output)
  end
  
  private
  
  # Take away the HTML tags from the string and insert a '0' if it is empty
  def strip_tags_or_zero(str)
    (out = str.gsub(/<\/?[^>]*>/, "").strip).blank? ? '0' : out
  end
end