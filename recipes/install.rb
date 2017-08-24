package 'unzip' do
  action :install
end

zip_file = File.join(Chef::Config[:file_cache_path], node[:consul][:zip_file])
remote_file zip_file do
  source node[:consul][:download_url]
  notifies :run, 'execute[install consul]', :immediately
end

execute 'install consul' do
  cwd Chef::Config[:file_cache_path]
  command "unzip -o #{zip_file} -d #{node[:consul][:bin_dir]}"
  action :nothing
end

user 'consul'

group 'consul' do
  action :modify
  members 'consul'
  append true
end

file "#{node[:consul][:bin_dir]}/consul" do
  mode '0755'
  owner 'consul'
  group 'consul'
end

%w( /etc/consul.d /opt/consul/data ).each do |dir|
  directory dir do
    mode '0755'
    owner 'consul'
    group 'consul'
    recursive true
  end
end

template '/etc/consul.d/consul-server.json' do
  owner 'consul'
  group 'consul'
  mode '0644'
  notifies :reload, 'systemd_unit[consul.service]'
  notifies :restart, 'systemd_unit[consul.service]'
end

package 'dnsmasq'

file '/etc/dnsmasq.d/consul' do
  content 'server=/consul/127.0.0.1#8600'
end

service 'dnsmasq' do
  action [ :enable, :start ]
  provider Chef::Provider::Service::Systemd
end

systemd_unit 'consul.service' do
  content <<-EOU.gsub(/^\s+/, '')
  [Unit]
  Description=Consul Agent
  Requires=network-online.target
  After=network-online.target

  [Service]
  Restart=on-failure
  ExecStart=/usr/local/bin/consul agent -config-dir /etc/consul.d
  ExecReload=/bin/kill -HUP $MAINPID
  KillSignal=SIGTERM
  User=consul
  Group=consul

  [Install]
  WantedBy=multi-user.target
  EOU

  action [:create, :enable, :start]
  notifies :run, 'execute[join cluster]'
end

execute 'join cluster' do
  command "#{node[:consul][:bin_dir]}/consul join #{node[:consul][:join_ip]}"
  action :run
end
