require 'mechanize'

agent = Mechanize.new
page = agent.get('https://www.just-eat.ie/restaurants-andersons-foodhall-and-cafe-dublin/menu')

all_titles = page.css('._50YZr ._3hlni .oWmW1s')

all_titles.each do |title|
  puts title.text.strip
end



