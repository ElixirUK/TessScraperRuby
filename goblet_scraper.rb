#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_uploader'

$root_url = 'http://www.mygoblet.org/'
$owner_org = 'goblet'
$lessons = {}
$debug = true

def parse_data(page)
    topic_match = Regexp.new('topic-tags')
    audience_match = Regexp.new('audience-tags')
    portal_match = Regexp.new('training-portal')

    if $debug
        puts 'Opening local file.'
        begin
          f = File.open("goblet.html")
          doc = Nokogiri::HTML(f)
          f.close
        rescue
          puts "Failed to open goblet.html file."
        end
    else
        puts "Opening: #{$root_url + page}"
        doc = Nokogiri::HTML(open($root_url + page))
    end

    doc.search('tbody > tr').each do |row|
        key = nil
        name = nil
        topics = []
        audience = []
        row.search('a').each do |link|
            href = link['href']
            text = link.text
            if $debug
                puts "HREF: #{href}"
                puts "TEXT: #{text}"
            end
            if topic_match.match(href)
                topics << text
            elsif audience_match.match(href)
                audience << text
            elsif portal_match.match(href)
                key = href
                name = text[0..-1] # Trim off extraneous quotes.
            end
        end
        # This next bit is to get the last modified date, but getting the second part of the first <td> element,
        # after the <br>. 'slice' removes the name as required
        date_modified = 'Unknown'
        stuff = nil
        row.search('td').each do |text|
            stuff = text.text.strip
            break
        end
        # This relative date needs to be fixed later
        stuff.slice! "#{name}"
        date_modified = return_date(stuff)
        $lessons[key] = {'audience' => audience, # could be treated similarly to topics
                         'topics' => topics.map{|t| {'name' => t} },
                         'last_modified' => date_modified,
                         'name' => name}
        if $debug
            puts "Key: #{key}"
            puts "Lessons: #{$lessons[key]}"
        end
    end
end

# This monstrosity would not be required if we had a proper feed
# with the actual date in it.
def return_date(datestring)
    if datestring.nil?
        return 'Unknown'
    end
    parts = datestring.split
    today = DateTime.now
    years = 0
    months = 0
    weeks = 0
    days = 0
    year_match = Regexp.new('year', Regexp::EXTENDED)
    month_match = Regexp.new('month', Regexp::EXTENDED)
    week_match = Regexp.new('week', Regexp::EXTENDED)
    day_match = Regexp.new('day', Regexp::EXTENDED)

    if month_match.match(parts[2])
        months = parts[1].to_i
    elsif year_match.match(parts[2])
        years = parts[1].to_i
    elsif week_match.match(parts[2])
        weeks = parts[1].to_i
    end

    if month_match.match(parts[4])
        months = parts[3].to_i
    elsif week_match.match(parts[4])
        weeks = parts[3].to_i
    elsif day_match.match(parts[4])
        days = parts[3].to_i
    end

    diff = days + (weeks * 7) + (months * 30) + (years * 365)
    earlier = (today - diff).to_s

    return earlier.split(/\./)[0].gsub!('+00:00','') # Trim off final decimals and timezone
end

##################################################
# Main body of the script below, functions above #
##################################################

# Actually run the code here...
if $debug
  parse_data('a random string')
else
  0.upto(2) do |p|
    parse_data('training-portal?page=' + p.to_s)
  end
end

org_title = 'Goblet'
org_name = 'goblet'
org_desc = 'GOBLET, the Global Organisation for Bioinformatics Learning, Education and Training, is a legally registered foundation providing a global, sustainable support and networking structure for bioinformatics educators/trainers and students/trainees .'
org_image_url = 'http://www.mygoblet.org/sites/default/files/logo_goblet_trans.png'
homepage = $root_url
node_id = ''
organisation = Organisation.new(org_title,org_name,org_desc,org_image_url,homepage,node_id)
Uploader.check_create_organisation(organisation)


# each individual tutorial
$lessons.each_key do |key|
    course = Tuition::Tutorial.new
    course.url = $root_url + key
    course.owner_org = $owner_org
    course.title = $lessons[key]['name']
    course.set_name($owner_org,$lessons[key]['name'])
    course.last_modified = $lessons[key]['last_modified']
    course.created = $lessons[key]['last_modified']
    course.audience = $lessons[key]['audience']
    course.tags = $lessons[key]['topics']
    course.description = $lessons[key]['name']
    course.notes = "#{$lessons[key]['name']} from #{$root_url + key}, added automatically."
    course.format = 'html'

    #puts "Course: #{course.dump}"

    # Before attempting to create anything we need to check if the resource/dataset already exists, updating it
    # as and where necessary.
    Uploader.create_or_update(course)
    #Uploader.check_dataset(course)

end

