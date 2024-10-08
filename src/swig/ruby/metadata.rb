#!/usr/bin/env ruby
require 'erb'
require 'yaml'
require './mlt'

$folder = 'markdown'
$repo = Mlt::Factory::init

$optional_params = [
  'minimum',
  'maximum',
  'default',
  'unit',
  'scale',
  'format',
  'widget'
]
template = %q{---
layout: standard
title: Documentation
wrap_title: "<%= type_title %>: <%= yml['identifier'] %>"
category: plugin
---
* TOC
{:toc}

## Plugin Information

title: <%= yml['title'] %>  
% if yml['tags']
media types:
%   yml['tags'].each do |x|
<%= x + "  " %>
%   end
<%= "\n" %>
% end
description: <%= ERB::Util.h(yml['description']) %>  
version: <%= yml['version'] %>  
creator: <%= yml['creator'] %>  
% yml['contributor'] and yml['contributor'].each do |x|
contributor: <%= x %>  
% end 
<%= "copyright: #{yml['copyright']}  \n" if yml['copyright'] %>
<%= "license: #{yml['license']}  \n" if yml['license'] %>
<%= "URL: [#{yml['url']}](#{yml['url']})  \n" if yml['url'] %>
% if yml['notes']

## Notes

<%= ERB::Util.h(yml['notes']) %>

% end
% if yml['bugs']

## Bugs

%   yml['bugs'].each do |x|
* <%= x %>
%   end

% end
% if yml['parameters']

## Parameters

%   yml['parameters'].each do |param|
### <%= param['identifier'] %>

<%= "title: #{param['title']}  " if param['title'] %>  
%     if param['description']
description:
%       if param['description'].include? "\n"
```
<%= param['description'] %>
```
%       else
<%= "#{ERB::Util.h(param['description'])}  \n" %>
%       end
%     end
type: <%= param['type'] %>  
readonly: <%= param['readonly'] and 'yes' or 'no' %>  
required: <%= param['required'] and 'yes' or 'no' %>  
<%= "animation: yes  \n" if param['animation'] %>
%     $optional_params.each do |key|
<%= "#{key}: #{param[key].to_s.gsub('](', ']\(')}  \n" if param[key] %>
%     end
%     if param['values']
values:  

%       param['values'].each do |value|
* <%= value %>
%       end
%     end

%   end
% end
}

$processor = ERB.new(template, 0, "%<>")


def output(mlt_type, services, type_title)
  filename = File.join($folder, "Plugins#{type_title}s.md")
  index = File.open(filename, 'w')
  index.puts '---'
  index.puts 'title: Documentation'
  index.puts "wrap_title: #{type_title} Plugins"
  index.puts '---'
  unsorted = []
  (0..(services.count - 1)).each do |i|
    unsorted << services.get_name(i)
  end
  unsorted.sort().each do |name|
    meta = $repo.metadata(mlt_type, name)
    if meta.is_valid
      if !meta.get_data('parameters')
        puts "No parameters for #{name} #{type_title}"
      end
      filename = File.join($folder, type_title + name.capitalize.gsub('.', '-'))
#      puts "Processing #{filename}"
      begin
        yml = YAML.load(meta.serialise_yaml)
        if yml
          File.open(filename + '.md', 'w') do |f|
            f.puts $processor.result(binding)
          end
        else
          puts "Failed to write file for #{filename}"
        end
        filename = type_title + name.capitalize.gsub('.', '-')
        index.puts "* [#{name}](../#{filename}/): #{meta.get('title')}\n"
      rescue SyntaxError
          puts "Failed to parse YAML for #{filename}"
      end
    else
      puts "No metadata for #{name} #{type_title}"
    end unless name.start_with?('lv2.', 'vst2.')
  end 
  index.close
end

Dir.mkdir($folder) if not Dir.exists?($folder)

[
  [Mlt::Mlt_service_consumer_type, $repo.consumers, 'Consumer'],
  [Mlt::Mlt_service_filter_type, $repo.filters, 'Filter'],
  [Mlt::Mlt_service_link_type, $repo.links, 'Link'],
  [Mlt::Mlt_service_producer_type, $repo.producers, 'Producer'],
  [Mlt::Mlt_service_transition_type, $repo.transitions, 'Transition']
].each {|x| output *x}
