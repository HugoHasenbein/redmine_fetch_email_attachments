# encoding: utf-8
#
# Redmine plugin to fetch attachments form a user configurable email account
#
# Copyright © 2014-2018 Stephan Wenzel <stephan.wenzel@drwpatent.de>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#

Redmine::Plugin.register :redmine_fetch_email_attachments do
  name 'Redmine Fetch Email Attachments plugin'
  author 'Stephan Wenzel'
  description 'This is a plugin for Redmine to fetch email attachments and attach them to the current issue'
  version '2.0.2'
  url 'https://github.com/HugoHasenbein/redmine_fetch_email_attachments'
  author_url 'https://github.com/HugoHasenbein/redmine_fetch_email_attachments'
end

require 'fetch_email_attachments'

