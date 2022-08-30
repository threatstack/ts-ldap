# ts-ldap
Some bits we used to help us deploy OpenLDAP.

Please see each respective file for its license and copyright information.
Content developed by Threat Stack, Inc. in this repository is under the MIT
license.

Files include:
  * 001-zmldapenable-mmr.pl (No longer in this repo, view in the [zm-core-utils](https://github.com/Zimbra/zm-core-utils/blob/8.8.12/src/libexec/zmldapenable-mmr) repository)
  * 002-syncrepl.rb [MIT] - The Syncrepl resource we made for updating syncrepl
    information using Chef.
  * 003-helpers.rb [MIT] - Helpers used in communicating with LDAP.
  * 004-ldapmodify.rb [MIT] - Another resource used for making quick changes to
    LDAP. Works like an exec block.

## Important

To use this, you'll need to make sure the `net-ldap` chef gem is installed.

## Sample use of the Chef resource

```ruby
chef_gem 'net-ldap' do
  compile_time true
  version '0.15.0'
end

# ldap_pws should point to a databag with LDAP passwords
# ldaphosts should be an array of your LDAP hosts in role:ldap
syncreplrid = Hash[search(:node, 'role:ldap', :filter_result => { :name => ['name'], 'id' => ['openldap', 'serverid'] }).map { |k| [k['name'], k['id']] }]

ldaphosts.each do |e|
  syncrepl "sr-#{e['name']}" do
    server "#{node.name}.#{node.environment}.contoso.local"
    targetdb 'olcDatabase={1}mdb,cn=config'
    bindpw ldap_pws['configpw']
    rid syncreplrid[e['name']].to_s
    syncprovider "ldap://#{e['name']}.#{node.environment}.contoso.local"
    tls_cert '/etc/ldap/tls/replication.pem'
    tls_key '/etc/ldap/tls/replication-key.pem'
    tls_cacert '/etc/ssl/certs/tsldap.pem'
    searchbase base_dn
    not_if { node.name == e['name'] }
  end
end

if ldaphosts.count > 1
  ruby_block 'clean out old syncrepls' do
    block do
      hosts = remove_old_syncrepls(ldaphosts)
      hosts.each do |e|
        syncrepl "sr-#{e}" do
          action :remove
          server "#{node.name}.#{node.environment}.contoso.local"
          targetdb 'olcDatabase={1}mdb,cn=config'
          bindpw ldap_pws['configpw']
          syncprovider "ldap://#{e}.#{node.environment}.contoso.local"
          tls_cert '/etc/ldap/tls/replication.pem'
          tls_key '/etc/ldap/tls/replication-key.pem'
          tls_cacert '/etc/ssl/certs/tsldap.pem'
          searchbase base_dn
        end
      end
    end
  end
  ldapmodify 'enable mirrormode' do
    server "#{node.name}.#{node.environment}.contoso.local"
    basedn 'cn=config'
    targetdn 'olcDatabase={1}mdb,cn=config'
    binddn 'cn=admin,cn=config'
    bindpw ldap_pws['configpw']
    changes [[:add, :olcMirrorMode, 'TRUE']]
    notifies :create, 'ruby_block[openldap-setmirrormode-done]', :immediately
    not_if { node.attribute?('openldap-setmirrormode-done') }
  end

  ruby_block 'openldap-setmirrormode-done' do
    block do
      node.normal['openldap-setmirrormode-done'] = true
      node.save
    end
    action :nothing
  end
end
```

# Contributing
We do not accept contributions for this repository.