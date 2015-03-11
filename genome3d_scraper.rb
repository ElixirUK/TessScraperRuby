#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'tess_uploader'

$root_url = 'http://genome3d.eu/'
$owner_org = 'genome3d'
$lessons = {}
$debug = true


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

end


# parse the data
parse_data('tutorials/page/Public/Page/Tutorial/Index')

__END__

# create the organisation
org_title = 'Genome 3D'
org_name = 'genome3d'
org_desc = <<EOF
Genome3D provides consensus structural annotations and 3D models for sequences from model organisms, including human.
These data are generated by several UK based resources in the Genome3D consortium: SCOP, CATH, SUPERFAMILY, Gene3D, FUGUE, THREADER, PHYRE.
EOF
org_image_url = 'https://pbs.twimg.com/profile_images/2593830125/2b54r4g2041o4vhy96xl_400x400.png'
organisation = Organisation.new(org_title,org_name,org_desc,org_image_url)
Uploader.check_create_organisation(organisation)

# do the uploads
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

  # Before attempting to create anything we need to check if the resource/dataset already exists, updating it
  # as and where necessary.
  #Uploader.create_or_update(course)
  print "Course: "
  pprint.pprint(course)

end
