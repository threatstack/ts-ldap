#
# Cookbook Name::
# Libraries:: helper
#
# Copyright (c) 2016-2022 F5, Inc.
# Author:: Patrick Cable <p.cable@f5.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

def init_ldap(hostname, basedn, admindn, adminpw)
  require 'net-ldap'
  ldap = Net::LDAP.new  :host => hostname,
                        :port => 636,
                        :encryption => {
                          :method => :simple_tls,
                          :tls_options => {
                            :ca_file => '/etc/ssl/certs/tsldap.pem'
                          }
                        },
                        :base => basedn,
                        :auth => {
                          :method => :simple,
                          :username => admindn,
                          :password => adminpw
                        }
  return ldap
end

def get_entry(ldap, syncprovider)
  filter = Net::LDAP::Filter.eq('olcSyncrepl', '*')
  search = ldap.search(:filter => filter, :attributes => ['olcSyncrepl']).map { |k| k[:olcSyncrepl] }.flatten
  return false unless search.count >= 1
  search.each do |s|
    entry = s.split(/\s(?=(?:[^"]|"[^"]*")*$)/).map { |k|
      m = k.to_s.split('=',2);
      m[0] = 'rid' if m[0].include?('rid')
      m[0] = m[0].to_sym
      m
    }.to_h
    return entry if entry[:provider].include?(syncprovider)
    next
  end
  return false
end

def get_syncrepls(ldap)
  filter = Net::LDAP::Filter.eq('olcSyncrepl', '*')
  search = ldap.search(:filter => filter, :attributes => ['olcSyncrepl']).map { |k| k[:olcSyncrepl] }.flatten
  entries = []
  search.each do |s|
    entries.push(s.split(/\s(?=(?:[^"]|"[^"]*")*$)/).map { |k|
      m = k.to_s.split('=',2);
      m[0] = 'rid' if m[0].include?('rid')
      m[0] = m[0].to_sym
      m
    }.to_h)
  end
  return entries
end

def remove_old_syncrepls(ldaphosts)
  require 'net/ldap'
  require 'uri'
  ldappws = Chef::EncryptedDataBagItem.load('credentials', 'ldap-pws')[node.environment]
  current_hosts = ldaphosts.map { |k| k['name'] unless k['name'] == node.name }
  ldap = init_ldap("#{node.name}.#{node.environment}.contoso.local",
                   'cn=config', 'cn=admin,cn=config', ldappws['configpw'])
  slapd_hosts = get_syncrepls(ldap).map { |k| URI(k[:provider]).host.split('.')[0] }
  to_remove = slapd_hosts - current_hosts
  return to_remove
end
