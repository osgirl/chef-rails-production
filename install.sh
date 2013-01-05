#!/usr/bin/env ruby

puts "=========== Installing Git"
`apt-get install git-core -y -qq`
puts "=========== Cloning recipes"

`rm -Rf /tmp/chef-cookbooks`
Dir.chdir "/tmp"
`git clone git://github.com/redde/chef-rails-production.git chef-cookbooks -q && cd /tmp/chef-cookbooks && git submodule init -q`

puts "=========== Running wizard"

app_name = ""
while app_name.length <= 3
  print "Enter application name (4 chars min): "
  app_name = gets.strip
end

fqdn = ""
while fqdn.length < 3
  print "Enter domain name (ex. #{app_name}.com): "
  fqdn = gets.strip
end

dbs = {"0" => "MySQL", "1" => "PostgreSQL"}
dbs_values = {"0" => "mysql", "1" => "postgresql"}
db = nil
while !(dbs.keys.include? db)
  puts "Available database types:"
  dbs.each do |key, value|
    puts "    [#{key}] #{value}"
  end
  printf "Choose database type: "
  db = gets.strip
end
db_type = dbs_values[db]

server = nil
while server.nil?
  printf "Do You need to install database server?[y/n]: "
  server_string = gets.strip
  case server_string
  when "y" then server = true
  when "n" then server = false
  end
end
write = ""
write <<  "{\n"
write << "  \"run_list\":[\"role[appserver]\"],\n"
write << "  \"app_name\": \"#{app_name}\",\n"
write << "  \"domain_name\": \"#{fqdn}\",\n"
write << "  \"database\": {\n"
write << "    \"type\": \"#{db_type}\",\n"
write << "    \"server\": \"#{server}\"\n"
write << "  }\n"
write << "}\n"

puts "Generated node.json:"
puts write
Dir.chdir "/tmp/chef-cookbooks"
file = File.open("node.json", "w")
file.write write

sleep 1

puts "=========== Installing chef gem"
`gem install chef --no-ri --no-rdoc`
puts "=========== Starting provisioning"
exec('chef-solo -c /tmp/chef-cookbooks/solo.rb -j /tmp/chef-cookbooks/node.json -l debug')
