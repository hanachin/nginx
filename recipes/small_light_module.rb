slm_src_filename = ::File.basename(node['nginx']['small_light']['url'])
slm_src_filepath = "#{Chef::Config['file_cache_path']}/#{slm_src_filename}"
slm_extract_path = "#{Chef::Config['file_cache_path']}/ngix_small_light/#{node['nginx']['small_light']['checksum']}"

remote_file slm_src_filepath do
  source node['nginx']['small_light']['url']
  checksum node['nginx']['small_light']['checksum']
  owner "root"
  group "root"
  mode 00644
end

bash "extract_small_light_module" do
  cwd ::File.dirname(slm_src_filepath)
  code <<-EOH
    mkdir -p #{slm_extract_path}
    tar xzf #{slm_src_filename} -C #{slm_extract_path}
    mv #{slm_extract_path}/*/* #{slm_extract_path}/
  EOH

  not_if { ::File.exists?(slm_extract_path) }
end

bash "setup_small_light_module" do
  cwd slm_extract_path
  code <<-EOH
    ./setup #{node['nginx']['small_light']['setup_option']}
  EOH

  not_if { ::File.exists?(slm_extract_path) }
end

node.run_state['nginx_configure_flags'] =
  node.run_state['nginx_configure_flags'] | ["--with-pcre", "--add-module=#{slm_extract_path}"]
