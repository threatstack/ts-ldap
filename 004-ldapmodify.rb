#
# Cookbook Name::
# Resource:: ldapmodify
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

resource_name :ldapmodify

property :name, String, name_property: true
property :server, String
property :basedn, String
property :targetdn, String
property :binddn, String
property :bindpw, String
property :changes, Array

default_action :update

action :update do
  require 'net/ldap'
  ldap = init_ldap(server, targetdn, binddn, bindpw)
  raise "Could not bind to #{server} as #{binddn}" unless ldap.bind
  raise "Could not update #{targetdn}" unless ldap.modify :dn => targetdn, :operations => changes
  new_resource.updated_by_last_action(true)
end
