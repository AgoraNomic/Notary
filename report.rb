require 'yaml'
require 'active_support/all'
require 'unicode/display_width'

pledges = YAML.load_file('pledges.yml').sort_by { |x| x['date'] }
contracts = Dir['contracts/*.yml'].map { |f| YAML.load_file(f) }

DURATION_PARTS = {
    years: 'yr',
    months: 'mo',
    days: 'dy',
    hours: 'hr',
    minutes: 'mn'
}

$footnotes = []

def pad(str, total_width, side = :left)
  str_width = Unicode::DisplayWidth.of(str, emoji: true)

  if str_width <= total_width
    padding = (" " * (total_width - str_width))
    if side == :left
      str + padding
    else
      padding + str
    end
  else
    $footnotes.push str

    pad("*#{$footnotes.length}", total_width, side)
  end
end
puts "NOTARY'S REPORT OF #{Time.now.strftime('%^B %d %Y')}"

puts ""

puts "An up-to-date version of this report is available online at"
puts "https://agoranomic.org/Notary/."

puts ""

if contracts.length == 1
  puts "There is one non-invisible contract."
else
  puts "There are #{contracts.length} non-invisible contracts."
end

puts ""

contracts.each do |contract|
  rev = contract['history'].count { |event| event['event'].include? '($)' }
  rev_str = "rev. #{rev}"
  puts "=============================== CONTRACT ==============================="
  puts "|#{ pad(contract['title'], 70 - rev_str.length) }#{rev_str}|"
  puts "|PARTIES: #{ pad(contract['parties'].join(', '), 61) }|"
  puts "========================================================================"
  puts contract['text']

  if contract['assets']
    puts "------------------------------------------------------------------------"
    puts "Asset ownership (self-ratifying if I am the recordkeepor):"
    puts contract['assets']
  end

  if contract['notes']
    puts "------------------------------------------------------------------------"
    puts "Notes:"
    puts contract['notes']
  end

  if contract['history']
    puts "------------------------------------------------------------------------"
    puts "History:"
    rev = 0
    contract['history'].each do |event|
      if event['event'].include? '($)'
        rev += 1
        event['event'].gsub!('($)', "(#{rev})")
      end
      date_str = event['date'].utc.strftime('%b %d %Y %H:%M') + ': '
      if Unicode::DisplayWidth.of(date_str + event['event'], emoji: true) < 72
        puts date_str + event['event']
      else
        puts date_str
        puts "  " + event['event']
      end
    end
  end
  puts "========================================================================"
  puts ""
end

if pledges.length == 1
  puts "There is one non-invisible pledge."
else
  puts "There are #{ pledges.length } non-invisible pledges."
end


pledges.each do |pledge|
  window = pledge['window'] ? ActiveSupport::Duration.parse("P" + pledge['window']) : 60.days
  window_str = window.parts.map { |type, value| "#{value}#{DURATION_PARTS[type]}" }.join(' ')
  expire = pledge['date'].utc + window
  if expire < Time.now
    raise "pledges.yml contains expired pledge: #{pledge['title']}"
  end

  puts "================================ PLEDGE ================================"
  puts "|#{ pad(pledge['title'], 70 - pledge['by'].length) }#{ pledge['by'] }|"
  puts "|MADE: #{ pledge['date'].utc.strftime('%b %d %Y %H:%M') }|WINDOW: #{ pad(window_str, 5, :right) }|EXPIRES: #{ pad((pledge['date'].utc + window).strftime('%b %d %Y %H:%M'), 17, :right) }|N: #{ pad((pledge['n'] || 2).to_s, 2, :right) }|"
  puts "========================================================================"
  puts pledge['text']
  puts "========================================================================"
  
  puts ""
end

$footnotes.each_with_index do |str, idx|
 puts "*#{ idx + 1}: #{ str }"
end

puts ""

puts "The transitional period can end on or after April 27, 2020. At that"
puts "point, any invisible contracts or pledges (i.e. those not listed above)"
puts "will be destroyed."