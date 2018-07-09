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

module FetchEmailAttachments
  module Patches    
    
    module UserPreferencePatch
      def self.included(base) # :nodoc: 
        base.send(:include, InstanceMethods)
        
        base.class_eval do
        
          if self.included_modules.include?(Redmine::SafeAttributes)
            safe_attributes 'fetchEmailAttachments_protocol',
                            'fetchEmailAttachments_host',
                            'fetchEmailAttachments_port',
                            'fetchEmailAttachments_username',
                            'fetchEmailAttachments_use_ssl',
                            'fetchEmailAttachments_ssl_verify',
                            'fetchEmailAttachments_imap_folder',
                            'fetchEmailAttachments_move_on_success',
                            'fetchEmailAttachments_move_on_failure',
                            'fetchEmailAttachments_apop',
                            'fetchEmailAttachments_delete_unprocessed',
                            'fetchEmailAttachments_password',
                            'fetchEmailAttachments_ticket_attachments',
                            'fetchEmailAttachments_project_documents'
          end

        end
      end

      module InstanceMethods
      
        def fetchEmailAttachments_protocol; self[:fetchEmailAttachments_protocol] end
        def fetchEmailAttachments_protocol=(value); self[:fetchEmailAttachments_protocol]=value end

        def fetchEmailAttachments_host; self[:fetchEmailAttachments_host] end
        def fetchEmailAttachments_host=(value); self[:fetchEmailAttachments_host]=value end

        def fetchEmailAttachments_port; self[:fetchEmailAttachments_port] end
        def fetchEmailAttachments_port=(value); self[:fetchEmailAttachments_port]=value end

        def fetchEmailAttachments_username; self[:fetchEmailAttachments_username] end
        def fetchEmailAttachments_username=(value); self[:fetchEmailAttachments_username]=value end

        def fetchEmailAttachments_use_ssl; self[:fetchEmailAttachments_use_ssl] end
        def fetchEmailAttachments_use_ssl=(value); self[:fetchEmailAttachments_use_ssl]=value end

        def fetchEmailAttachments_ssl_verify; self[:fetchEmailAttachments_ssl_verify] end
        def fetchEmailAttachments_ssl_verify=(value); self[:fetchEmailAttachments_ssl_verify]=value end

        def fetchEmailAttachments_imap_folder; self[:fetchEmailAttachments_imap_folder] end
        def fetchEmailAttachments_imap_folder=(value); self[:fetchEmailAttachments_imap_folder]=value end

        def fetchEmailAttachments_move_on_success; self[:fetchEmailAttachments_move_on_success] end
        def fetchEmailAttachments_move_on_success=(value); self[:fetchEmailAttachments_move_on_success]=value end

        def fetchEmailAttachments_move_on_failure; self[:fetchEmailAttachments_move_on_failure] end
        def fetchEmailAttachments_move_on_failure=(value); self[:fetchEmailAttachments_move_on_failure]=value end

        def fetchEmailAttachments_apop; self[:fetchEmailAttachments_apop] end
        def fetchEmailAttachments_apop=(value); self[:fetchEmailAttachments_apop]=value end

        def fetchEmailAttachments_delete_unprocessed; self[:fetchEmailAttachments_delete_unprocessed] end
        def fetchEmailAttachments_delete_unprocessed=(value); self[:fetchEmailAttachments_delete_unprocessed]=value end

        def fetchEmailAttachments_password; self[:fetchEmailAttachments_password] end
        def fetchEmailAttachments_password=(value); self[:fetchEmailAttachments_password]=value end

        def fetchEmailAttachments_ticket_attachments; self[:fetchEmailAttachments_ticket_attachments] end
        def fetchEmailAttachments_ticket_attachments=(value); self[:fetchEmailAttachments_ticket_attachments]=value end

        def fetchEmailAttachments_project_documents; self[:fetchEmailAttachments_project_documents] end
        def fetchEmailAttachments_project_documents=(value); self[:fetchEmailAttachments_project_documents]=value end

      end
    end
  end
end  

unless UserPreference.included_modules.include?(FetchEmailAttachments::Patches::UserPreferencePatch)
  UserPreference.send(:include, FetchEmailAttachments::Patches::UserPreferencePatch)
end
