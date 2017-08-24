default[:consul][:bin_dir] = '/usr/local/bin'
default[:consul][:version] = '0.9.2'
default[:consul][:zip_file] = "consul_#{node[:consul][:version]}_linux_amd64.zip"
default[:consul][:download_url] = "https://releases.hashicorp.com/consul/#{node[:consul][:version]}/#{node[:consul][:zip_file]}"
default[:consul][:cluster_size] = '1'
