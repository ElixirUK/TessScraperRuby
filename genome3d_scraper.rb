#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_uploader'

$root_url = 'http://genome3d.eu/'
$owner_org = 'genome3d'
$lessons = {}
$debug = false


def parse_data(page)
  # As usual, use a local page for testing to avoid hammering the remote server.
  if $debug
    puts 'Opening local file.'
    begin
      f = File.open("genome3d.html")
      doc = Nokogiri::HTML(f)
      f.close
    rescue
      puts 'Failed to open genome3d.html file.'
    end
  else
    puts "Opening: #{$root_url + page}"
    doc = Nokogiri::HTML(open($root_url + page))
  end

  # Now to obtain the exciting course information!
  #links = doc.css('#wiki-content-container').search('li')
  #links.each do |li|
  #  puts "LI: #{li}"
  #end

  links = doc.css('#wiki-content-container').search('ul').search('li')
  links.each do |link|
     if !(a = link.search('a')).empty?
        href = a[0]['href'].chomp
        name = a.text
        puts "Name = #{a.text}" if $debug
        puts "URL = #{a[0]['href'].chomp}" if $debug
        description = nil
        if !(li = link.search('li')).empty?
             description = li.text
             puts "Description = #{li.text}" if $debug
        end
        $lessons[href] = {}
        $lessons[href]['name'] = name
        $lessons[href]['description'] = description
     end
  end
end

# parse the data
parse_data('tutorials/page/Public/Page/Tutorial/Index')


# create the organisation
org_title = 'Genome 3D'
org_name = 'genome3d'
org_desc = <<EOF
Genome3D provides consensus structural annotations and 3D models for sequences from model organisms, including human.
These data are generated by several UK based resources in the Genome3D consortium: SCOP, CATH, SUPERFAMILY, Gene3D, FUGUE, THREADER, PHYRE.
EOF
org_image_url = 'https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcQwd3d_tBGpERIc1QYAWERLLdesDHr-k41oASnaoNHzLVXVBPtYaQ'
home_page = 'http://genome3d.eu/'
organisation = Organisation.new(org_title,org_name,org_desc,org_image_url, home_page)
Uploader.check_create_organisation(organisation)

# do the uploads
$lessons.each_key do |key|
  course = Tuition::Tutorial.new
  course.url = $root_url + key
  course.owner_org = $owner_org
  course.title = $lessons[key]['name']
  course.set_name($owner_org,$lessons[key]['name'])
  if $lessons[key]['description'].nil?
      course.description = $lessons[key]['name']
      course.notes = "#{$lessons[key]['name']} from #{$root_url + key}, added automatically."
  else
      course.description = $lessons[key]['description']
      course.notes = $lessons[key]['description']

  end
  course.format = 'html'

  # Before attempting to create anything we need to check if the resource/dataset already exists, updating it
  # as and where necessary.
  Uploader.create_or_update(course)
  #print "Course: #{course.dump}"


end
