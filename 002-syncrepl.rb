#
# Cookbook Name::
# Resource:: syncrepl
#
# Copyright (c) 2016 Threat Stack, Inc.
# Author:: Patrick T. Cable II <pat.cable@threatstack.com>
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

resource_name :syncrepl
default_action :create

property :name, String, name_property: true, desired_state: false
property :server, String, desired_state: false
property :targetdb, String, desired_state: false
property :binddn, String, desired_state: false, default: 'cn=admin,cn=config'
property :bindpw, String, desired_state: false
property :rid, String
property :syncprovider, String, desired_state: false
property :bindmethod, String, default: 'sasl'
property :saslmech, String, default: 'EXTERNAL'
property :tls_cert, String
property :tls_key, String
property :tls_cacert, String
property :tls_reqcert, String, default: 'demand'
property :timeout, String, default: '1'
property :network_timeout, String, default: '1'
property :starttls, String, default: 'critical'
property :filter, String, default: '"(objectclass=*)"'
property :searchbase, String
property :logfilter, String, default: '"(&(objectClass=auditWriteObject)(reqResult=0))"'
property :logbase, String, default: 'cn=accesslog'
property :scope, String, default: 'sub'
property :schemachecking, String, default: 'off'
property :type, String, default: 'refreshAndPersist'
property :lretry, String, default: '"60 +"'
property :keepalive, String, default: '240:10:30'

load_current_value do
  require 'net/ldap'
  ldap = init_ldap(server, 'cn=config', binddn, bindpw)
  # We need to get the current olcSyncrepl tags, and match with the
  # current one we're trying to grab.
  entry = get_entry(ldap, syncprovider)
  if entry == false
    current_value_does_not_exist!
  else
    # get_entry only returns one thing: a successful record.
    rid entry[:rid]
    syncprovider entry[:provider]
    bindmethod entry[:bindmethod]
    saslmech entry[:saslmech]
    tls_cert entry[:tls_cert]
    tls_key entry[:tls_key]
    tls_cacert entry[:tls_cacert]
    network_timeout entry[:'network-timeout']
    starttls entry[:starttls]
    filter entry[:filter]
    searchbase entry[:searchbase]
    logfilter entry[:logfilter]
    logbase entry[:logbase]
    scope entry[:scope]
    schemachecking entry[:schemachecking]
    type entry[:type]
    lretry entry[:retry]
    keepalive entry[:keepalive]
  end
end

action :create do
  converge_if_changed do
    unless current_resource
      require 'net/ldap'
      entry = "rid=#{rid} provider=#{syncprovider} bindmethod=#{bindmethod} " \
              "saslmech=#{saslmech} tls_cert=#{tls_cert} tls_key=#{tls_key} " \
              "tls_cacert=#{tls_cacert} tls_reqcert=#{tls_reqcert} " \
              "timeout=#{timeout} network-timeout=#{network_timeout} " \
              "starttls=#{starttls} filter=#{filter} searchbase=#{searchbase} " \
              "logfilter=#{logfilter} logbase=#{logbase} scope=#{scope} " \
              "schemachecking=#{schemachecking} type=#{type} retry=#{lretry} " \
              "keepalive=#{keepalive}"
      ldap = init_ldap(server, 'cn=config', binddn, bindpw)
      ops = [[:add, :olcSyncrepl, entry]]
      raise "Could not bind to #{server} as #{binddn}" unless ldap.bind
      raise "Could not add Syncrepl entry to #{targetdb}" unless ldap.modify(:dn => targetdb, :operations => ops)
    end
  end
end

action :remove do
  require 'net/ldap'
  # We need to get the actual entry as defined by the provider
  ldap = init_ldap(server, 'cn=config', binddn, bindpw)
  e = get_entry(ldap, syncprovider)
  # now we get to rebuild it!
  entry = "rid=#{e[:rid]} provider=#{syncprovider} bindmethod=#{e[:bindmethod]} " \
          "saslmech=#{e[:saslmech]} tls_cert=#{e[:tls_cert]} tls_key=#{e[:tls_key]} " \
          "tls_cacert=#{e[:tls_cacert]} tls_reqcert=#{e[:tls_reqcert]} " \
          "timeout=#{e[:timeout]} network-timeout=#{e[:'network-timeout']} " \
          "starttls=#{e[:starttls]} filter=#{e[:filter]} searchbase=#{e[:searchbase]} " \
          "logfilter=#{e[:logfilter]} logbase=#{e[:logbase]} scope=#{e[:scope]} " \
          "schemachecking=#{e[:schemachecking]} type=#{e[:type]} retry=#{e[:retry]} " \
          "keepalive=#{e[:keepalive]}"
  ops = [[:delete, :olcSyncrepl, entry]]
  raise "Could not bind to #{server} as #{binddn}" unless ldap.bind
  raise "Could not delete Syncrepl entry to #{targetdb}" unless ldap.modify(:dn => targetdb, :operations => ops)
end
