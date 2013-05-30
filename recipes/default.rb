#
# Cookbook Name::       cloudwatch_monitoring
# Description::         Base configuration for cloudwatch_monitoring
# Recipe::              default
# Author::              Neill Turner
#
# Copyright 2013, Neill Turner
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe 'apt'
include_recipe 'zip'

apt_package "libwww-perl" do
  action :install
end

apt_package "libcrypt-ssleay-perl" do
  action :install
end

remote_file "#{node[:cw_mon][:home_dir]}/CloudWatchMonitoringScripts-v#{node[:cw_mon][:version]}.zip" do
  source "#{node[:cw_mon][:release_url]}"
  owner "#{node[:cw_mon][:user]}"
  group "#{node[:cw_mon][:group]}"
  mode 0755 
  not_if { ::File.exists?("#{node[:cw_mon][:home_dir]}/CloudWatchMonitoringScripts-v#{node[:cw_mon][:version]}.zip")}
end

execute "unzip cloud watch monitoring scripts" do
    command "unzip #{node[:cw_mon][:home_dir]}/CloudWatchMonitoringScripts-v#{node[:cw_mon][:version]}.zip"
    cwd "#{node[:cw_mon][:home_dir]}"
    user "#{node[:cw_mon][:user]}"
    group "#{node[:cw_mon][:group]}"
    not_if { ::File.exists?("#{node[:cw_mon][:home_dir]}/aws-scripts-mon")}
end

file "#{node[:cw_mon][:home_dir]}/CloudWatchMonitoringScripts-v#{node[:cw_mon][:version]}.zip" do
  action :delete    
  not_if { ::File.exists?("#{node[:cw_mon][:home_dir]}/CloudWatchMonitoringScripts-v#{node[:cw_mon][:version]}.zip")== false }
end

template "#{node[:cw_mon][:home_dir]}/aws-scripts-mon/awscreds.conf" do
  owner "#{node[:cw_mon][:user]}"
  group "#{node[:cw_mon][:group]}"
  mode 0644
  source "awscreds.conf.erb"
  variables     :cw_mon => node[:cw_mon]
end

cron "cloudwatch_schedule_metrics" do
  action :create 
  minute "*/5"
  user "#{node[:cw_mon][:user]}"
  home "#{node[:cw_mon][:home_dir]}/aws-scripts-mon"
  command "#{node[:cw_mon][:home_dir]}/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --aws-credential-file #{node[:cw_mon][:home_dir]}/aws-scripts-mon/awscreds.conf --disk-path=/ --from-cron"
end

