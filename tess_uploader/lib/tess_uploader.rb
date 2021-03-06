

class TessUploader
  # Placeholder class.
  require 'inifile'
  require 'net/http'
  require 'net/https'
  require 'organisation'
  require 'tuition'
  require 'node'
  require 'package'
end


module Uploader
  # The config file is a standard format of .ini file, which only has one
  # section ('Main') at present.
  def self.get_config
    host, port, protocol, auth = nil
    myini = IniFile.load('uploader_config.txt')

    unless myini
      puts "Can't open config file!"
      return nil
    end

    myini.each_section do |section|
      if section == 'Main'
        host = myini[section]['host']
        port = myini[section]['port']
        protocol = myini[section]['protocol']
        auth = myini[section]['auth']
      end
    end

    return {
        'host' => host,
        'port' => port,
        'protocol' => protocol,
        'auth' => auth
    }

  end

  # This method is used by several futher ones below, each of which have varying URLs depending
  # on whether they create packages, datasets &c.
  def self.do_upload(data,url,conf)
    # process data to json for uploading
    puts "Trying URL: #{url}"

    auth = conf['auth']
    if auth.nil?
      puts 'API string missing!'
      return
    end

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if url =~ /https/
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    req = Net::HTTP::Post.new(uri.request_uri, initheader = { 'Content-Type' =>'application/json' })
    req.body = data.to_json
    req.add_field('Authorization', auth)
    req.add_field('X-CKAN-API-Key', auth)

    req.body = data.to_json
    if data.class == Hash
      if url =~ /resource/
        req.body = data.delete_if {|key,value| key == 'tags'}.to_json
      else
        req.body = data.to_json
      end
      #puts "BODY(1): #{req.body}"
    else
      body = data.dump
      if url =~ /resource/
        req.body = body.delete_if {|key,value| key == 'tags'}.to_json
      else
        req.body = body.to_json
      end
      #puts "BODY(2): #{req.body}"
    end
    req.add_field('Authorization', auth)
    res = http.request(req)

    unless res.code == '200'
      puts "Upload failed: #{res.code}"
      puts "ERROR: #{res.body}"
      return {}
    end

    # package_create returns the created package as its result.
    created_package = JSON.parse(res.body)['result']
    return created_package
  end

  def self.create_dataset(data)
    conf = self.get_config
    action = '/api/3/action/package_create'
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action
    return self.do_upload(data,url,conf)
  end

  def self.create_resource(data)
    conf = self.get_config
    action = '/api/3/action/resource_create'
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action
    return self.do_upload(data,url,conf)
  end

  def self.create_organisation(data)
    conf = self.get_config
    action = '/api/3/action/organization_create'
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action
    return self.do_upload(data,url,conf)
  end

  def self.create_package(data)
    conf = self.get_config
    action = '/api/3/action/group_create'
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action
    return self.do_upload(data,url,conf)
  end

  def self.create_or_update_node(data)
       tess_node = Uploader.check_node(data)
       if tess_node.nil? || tess_node.empty?
            Uploader.create_node(data)
       else
            data.update_id(tess_node['id'])
            Uploader.update_node(data)
       end
  end

  def self.create_node(data)
    conf = self.get_config
    action = '/api/3/action/group_create'
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action
    return self.do_upload(data,url,conf)
  end

  def self.check_node(data)
    conf = self.get_config
    action = '/api/3/action/group_show?id='
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action + data['name']
    return self.do_check(data,url,conf)
  end

  def self.update_node(data)
    conf = self.get_config
    action = '/api/3/action/group_update?id='
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action + data['id']
    return self.do_upload(data,url,conf)
  end
  
  def self.create_group(data)
    conf = self.get_config
    action = '/api/3/action/group_create'
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action
    return self.do_upload(data,url,conf)
  end

  def self.check_dataset(data)
    conf = self.get_config
    action = '/api/3/action/package_show?id='
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action + data['name']
    return self.do_check(data,url,conf)
  end

  def self.check_organistion(data)
    conf = self.get_config
    action = '/api/3/action/organization_show?id='
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action + data['name']
    return self.do_check(data,url,conf)
  end

  def self.do_check(data,url,conf)
    puts "Trying URL: #{url}"
    auth = conf['auth']
    if auth.nil?
      return {}
    end
    uri = URI(url)

    http = Net::HTTP.new(uri.host, uri.port)
    if url =~ /https/
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    req = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
    req.body = data.to_json
    req.add_field('Authorization', auth)
    req.add_field('X-CKAN-API-Key', auth)

    res = http.request(req)

    unless res.code == '200'
      puts "Check returned: #{res.code}"
      return {}
    end
    checked_result = JSON.parse(res.body)['result']
    #puts "CHECKED: #{checked_result}"
    if checked_result
      return checked_result
    else
      return {}
    end
  end

  def self.update_dataset(data)
    conf = self.get_config
    action = '/api/3/action/package_update?id='
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action + data['id']
    return self.do_upload(data,url,conf)
  end

  def self.update_resource(data)
    conf = self.get_config
    action = '/api/3/action/resource_update?id='
    url = conf['protocol'] + '://' + conf['host'] + ':' + conf['port'].to_s + action + data['id']
    return self.do_upload(data,url,conf)
  end

  def self.create_or_update(data)
    data_exists = self.check_dataset(data)
    #puts "EXISTS: #{data_exists}"
    if !data_exists.empty?
      # This has already been added to TeSS.
      resources = data_exists['resources']
      #puts "RESOURCES: #{resources}"
      changes = Tuition.compare(data,data_exists)
      if !changes.empty?
        # There has been some change to the data and an update may be required.
        puts 'DATASET: Something has changed.'
        update = self.update_dataset(changes)
        if !update.empty?
          puts 'Dataset updated.'
        end
      else
        puts 'DATASET: No change.'
      end
    else
      # This is not present on TeSS and should be added.
      puts 'Creating dataset.'
      dataset = self.create_dataset(data)
      if !dataset.nil?
        puts "Dataset created!"
      else
        puts 'Could not create dataset!'
      end
    end

  end

  def self.check_create_organisation(data)
    if self.check_organistion(data).empty?
      if self.create_organisation(data).empty?
        puts "Failed to create organisation #{data.name}."
      else
        puts "Created organisation #{data.name}."
      end
    else
      puts "Organisation #{data.name} already exists."
    end
  end

end
