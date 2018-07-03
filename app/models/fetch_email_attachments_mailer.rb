# encoding: utf-8
#
# Redmine plugin for quick attribute setting of redmine issues
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

require 'net/imap'
require 'net/pop'

class FetchEmailAttachmentsMailer < MailHandler

  include AbstractController::Callbacks


##########################################################################################
#                                                                                        #
#  +public+public+public+public+public+public+public+public+public+public+public+public+ #
#                                                                                        #
##########################################################################################

##########################################################################################
#                                                                                        #
#  check_user_mail - check this project's email                                          #
#                                                                                        #
##########################################################################################

  def self.check_user_mail(user_id)

    msg_count = 0

    unless User.find_by_id(user_id).blank? || User.find_by_id(user_id).pref.fetchEmailAttachments_protocol.blank?

      mail_options, options = self.pGet_user_mail_options(user_id)

	  Rails.logger.info "...............mail_options: #{mail_options[:username]}" 

      case mail_options[:protocol]
      when "pop3" then
        file_attachments, msg_count = pFetch_pop3(mail_options, options)
      when "imap" then
        file_attachments, msg_count = pFetch_imap(mail_options, options)        
      end
    else
        raise ArgumentError.new( "cannot pick up email: no protocol defined in fetchEmailAttachments user settings" )
    end

   [file_attachments, msg_count]
  end

  

##########################################################################################
#                                                                                        #
#  pGet_user_mail_options - collect user preferences                                     #
#                                                                                        #
##########################################################################################

  def self.pGet_user_mail_options(user_id)
  	
  	if (currentuser = User.find_by_id(user_id) )
  	
		case currentuser.pref.fetchEmailAttachments_protocol
		when "gmail"
		  protocol = "imap"
		  host = "imap.gmail.com"
		  port = "993"
		  ssl = "1"
		  ssl_verify = "peer" 
		when "yahoo"
		  protocol = "imap"
		  host = "imap.mail.yahoo.com"
		  port = "993"
		  ssl = "1"
		  ssl_verify = "peer" 
		else
		  protocol 		= currentuser.pref.fetchEmailAttachments_protocol.blank? ? nil : currentuser.pref.fetchEmailAttachments_protocol
		  host 			= currentuser.pref.fetchEmailAttachments_host.blank? ? nil : currentuser.pref.fetchEmailAttachments_host
		  port 			= currentuser.pref.fetchEmailAttachments_port.blank? ? nil : currentuser.pref.fetchEmailAttachments_port
		  ssl 			= currentuser.pref.fetchEmailAttachments_use_ssl.to_i > 0 ? "1" : nil
		  ssl_verify	= currentuser.pref.fetchEmailAttachments_ssl_verify.to_i > 0 ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
		end

		mail_options  = {:protocol 				=> protocol,
						:host 					=> host,
						:port 					=> port,
						:ssl 					=> ssl,
						:openssl_verify_mode  	=> ssl_verify,
						:apop 					=> currentuser.pref.fetchEmailAttachments_apop.blank? ? nil : currentuser.pref.fetchEmailAttachments_apop,
						:username 				=> currentuser.pref.fetchEmailAttachments_username.blank? ? nil : currentuser.pref.fetchEmailAttachments_username,
						:password 				=> currentuser.pref.fetchEmailAttachments_password.blank? ? nil : currentuser.pref.fetchEmailAttachments_password,
						:folder 				=> currentuser.pref.fetchEmailAttachments_imap_folder.blank? ? nil : currentuser.pref.fetchEmailAttachments_imap_folder,
						:move_on_success 		=> currentuser.pref.fetchEmailAttachments_move_on_success.blank? ? nil : currentuser.pref.fetchEmailAttachments_move_on_success,
						:move_on_failure 		=> currentuser.pref.fetchEmailAttachments_move_on_failure.blank? ? nil : currentuser.pref.fetchEmailAttachments_move_on_failure,
						:delete_unprocessed 	=> currentuser.pref.fetchEmailAttachments_delete_unprocessed.to_i > 0
						}
		options = {:user => {}}
		options[:user][:id]					= user_id

        [mail_options, options]
    else

        raise ArgumentError.new( "cannot find user #{user_id}" )
        [nil, nil]
        
    end #else
  end #def
  
  
##########################################################################################
#                                                                                        #
#  pFetch_imap - check this project's email via imap protocol                            #
#                                                                                        #
##########################################################################################

  def self.pFetch_imap(imap_options={}, options={})

    ###########################################################
    #                                                         #
    #  set standards if we have only got user and password    #
    #                                                         #
    ###########################################################
	host 	=  imap_options[:host] || '127.0.0.1'
	port 	=  imap_options[:port] || '143'
	ssl 	= !imap_options[:ssl].nil?
	verify 	=  imap_options[:openssl_verify_mode] == OpenSSL::SSL::VERIFY_NONE ? false : true
	folder  =  imap_options[:folder] || 'INBOX'

    ###########################################################
    #                                                         #
    #  try to connect to imap server - else throw exception   #
    #                                                         #
    ###########################################################
	Timeout::timeout(15) do
	  @imap = Net::IMAP.new(host, port, ssl, nil, verify)
	  @imap.login(imap_options[:username], imap_options[:password]) unless imap_options[:username].nil?
	end

    ###########################################################
    #                                                         #
    #  at sucessful login choose imap folder                  #
    #                                                         #
    ###########################################################
	@imap.select(folder)

    ###########################################################
    #                                                         #
    #  set message counter to zero                            #
    #                                                         #
    ###########################################################
	msg_count = 0
	file_attachments = []

    ###########################################################
    #                                                         #
    #  now loop through each unseen email                     #
    #                                                         #
    ###########################################################
	@imap.uid_search(['NOT', 'SEEN']).each do |uid|
	  msg = @imap.uid_fetch(uid,'RFC822')[0].attr['RFC822']
	  Rails.logger.info "FetchEmailAttachments: Receiving message #{uid}" 
	  msg_count += 1

    ###########################################################
    #                                                         #
    #  extract attachments of each unseen email               #
    #                                                         #
    ###########################################################
	  if file_attachments << self.pExtract_Attachments(msg, options)
		Rails.logger.info "FetchEmailAttachments: Message #{uid} successfully received" 

    ###########################################################
    #                                                         #
    #  on sucessful extraction log success and move email     #
    #                                                         #
    ###########################################################
		if imap_options[:move_on_success] && imap_options[:move_on_success] != folder
			@imap.uid_copy(uid, imap_options[:move_on_success])
		end #if

    ###########################################################
    #                                                         #
    #  mark received email as read                            #
    #                                                         #
    ###########################################################
		@imap.uid_store(uid, "+FLAGS", [:Seen])

	  else
	  
    ###########################################################
    #                                                         #
    #  on failed extraction log failure                       #
    #                                                         #
    ###########################################################
		Rails.logger.info "FetchEmailAttachments: Message #{uid} can not be processed" 

    ###########################################################
    #                                                         #
    #  on failed extraction log failure and move email        #
    #                                                         #
    ###########################################################
		@imap.uid_store(uid, "+FLAGS", [:Seen])
		if imap_options[:move_on_failure]
		  @imap.uid_copy(uid, imap_options[:move_on_failure])
		  @imap.uid_store(uid, "+FLAGS", [:Deleted])
		end #if
	  end #else
	end #do
	
    ###########################################################
    #                                                         #
    #  eventually execute deletion of emails marked "delete"  #
    #                                                         #
    ###########################################################
	@imap.expunge

    ###########################################################
    #                                                         #
    #  eventually return number of messages                   #
    #                                                         #
    ###########################################################
	[file_attachments.flatten.compact, msg_count]

    ###########################################################
    #                                                         #
    #  if login failed, ensure, we logoff                     #
    #                                                         #
    ###########################################################
  ensure
	if defined?(@imap) && @imap && !@imap.disconnected?
	  @imap.disconnect
	end #if
	
  end #def

##########################################################################################
#                                                                                        #
#  pFetch_pop3 - check this project's email vias pop protocol                            #
#                                                                                        #
##########################################################################################

  def self.pFetch_pop3(pop_options={}, options={})

    ###########################################################
    #                                                         #
    #  set standards if we have only got user and password    #
    #                                                         #
    ###########################################################
	host = pop_options[:host] || '127.0.0.1'
	port = pop_options[:port] || '110'
	apop = (pop_options[:apop].to_s == '1')
	delete_unprocessed = (pop_options[:delete_unprocessed].to_s == '1')

    ###########################################################
    #                                                         #
    #  try to connect to pop server - else throw exception    #
    #                                                         #
    ###########################################################
	pop = Net::POP3.APOP(apop).new(host,port)
	pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if pop_options[:ssl]
	Rails.logger.info "FetchEmailAttachments: Connecting to #{host}..." 

    ###########################################################
    #                                                         #
    #  set message counter to zero                            #
    #                                                         #
    ###########################################################
	msg_count = 0
	file_attachments = []

    ###########################################################
    #                                                         #
    #  now loop through each pop session                      #
    #                                                         #
    ###########################################################
	pop.start(pop_options[:username], pop_options[:password]) do |pop_session|

    ###########################################################
    #                                                         #
    #  any emails available? if none log "no email"           #
    #                                                         #
    ###########################################################
	  if pop_session.mails.empty?
		Rails.logger.info "FetchEmailAttachments: No email to process" 
	  else
	  
    ###########################################################
    #                                                         #
    #  else log email to process                              #
    #                                                         #
    ###########################################################
		Rails.logger.info "FetchEmailAttachments: #{pop_session.mails.size} email(s) to process..." 

    ###########################################################
    #                                                         #
    #  now loop through each email in pop session             #
    #                                                         #
    ###########################################################
		pop_session.each_mail do |msg|

		  msg_count += 1
		  message = msg.pop

    ###########################################################
    #                                                         #
    #  fetch mail id                                          #
    #                                                         #
    ###########################################################
		  uid = (message =~ /^Message-ID: (.*)/ ? $1 : '').strip


    ###########################################################
    #                                                         #
    #  extract attachments of each unseen email               #
    #                                                         #
    ###########################################################
		  if file_attachments << self.pExtract_Attachments(message, options)
			msg.delete
			Rails.logger.info "--> FetchEmailAttachments: Message #{uid} processed and deleted from the server" 
		  else
		  
    ###########################################################
    #                                                         #
    #  on failed extraction log failure and move email        #
    #                                                         #
    ###########################################################
			if delete_unprocessed
			  msg.delete
			  Rails.logger.info "--> FetchEmailAttachments: Message #{uid} NOT processed and deleted from the server" 
			else
			  Rails.logger.info "--> FetchEmailAttachments: Message #{uid} NOT processed and left on the server" 
			end #else
		  end #else
		end #do
	  end #else
	end #do
	
    ###########################################################
    #                                                         #
    #  eventually return number of messages                   #
    #                                                         #
    ###########################################################
	[file_attachments.flatten.compact, msg_count]

    ###########################################################
    #                                                         #
    #  if login failed, ensure, we logoff                     #
    #                                                         #
    ###########################################################
  ensure
	if defined?(pop) && pop && pop.started?
	  pop.finish
	end #if
  end #def

##########################################################################################
#                                                                                        #
#  pExtract_Attachments - extract                                                        #
#                                                                                        #
##########################################################################################

  def self.pExtract_Attachments(msg, options)

    ###########################################################
    #                                                         #
    #  find the user                                          #
    #                                                         #
    ###########################################################
      if( user = User.find_by_id(options[:user][:id]))      
   		email_attachments = self.pParse_attachment(Mail.new(msg))
      
		unless email_attachments.length == 0
		
		  file_attachments = []
		  email_attachments.each do |email_attachment|
		  
    ###########################################################
    #                                                         #
    #  get file name from email attachment                    #
    #                                                         #
    ###########################################################
			if RUBY_VERSION < '1.9'
			  attachment_filename = (email_attachment[:content_type].filename rescue nil) ||
									(email_attachment[:content_disposition].filename rescue nil) ||
									(email_attachment[:content_location].location rescue nil) ||
									"attachment"
			  attachment_filename = Mail::Encodings.unquote_and_convert_to(attachment_filename, 'utf-8') rescue 'unprocessable_filename'
			else
			  attachment_filename = self.fetch_to_utf8(email_attachment.filename, 'binary')
			end
		
			new_attachment = Attachment.new(:file => (email_attachment.decoded rescue nil) || (email_attachment.decode_body rescue nil) || email_attachment.raw_source,
											:filename => attachment_filename,
											:author => user,
											:content_type => email_attachment.mime_type) 
	
			new_attachment.save!
			file_attachments << new_attachment
			
		  end #do
		end #unless  
	  end #if              						

    file_attachments

  end #def


##########################################################################################
#                                                                                        #
#    parse nested attachments                                                            #
#                                                                                        #
##########################################################################################

def self.pParse_attachment(mail, attachments=[])
  mail.all_parts.each do |part|
    
    if    part.content_type =~ /message\//
    
    	    attachments << part # this is a nested mail - i want to keep it
            parse_attachment(Mail.new(part.body), attachments) # now parse the content of the nested mail

    elsif  part.content_disposition =~ /attachment/
      		attachments << part # this is any file attachment - i want to keep it

    elsif  part.content_type =~ /image\//
      		attachments << part # this is an image mail - i want to keep it
 
    elsif  part.content_type =~ /audio\//
      		attachments << part # this is an image mail - i want to keep it
 
    elsif  part.content_type =~ /video\//
      		attachments << part # this is an image mail - i want to keep it
 
    elsif  part.content_type =~ /application\//
    		attachments << part # this is an attachment file - i want to keep it		

    elsif  part.content_type =~ /text\/calendar/
    		attachments << part # this is an attachment file - i want to keep it		

	else
		# nothing - this will be text/ or other, which is kept in the message
    end
  end
  return attachments.flatten.compact
end

##########################################################################################
#                                                                                        #
#    fetch_to_utf8 - try to decode string                                                #
#                                                                                        #
##########################################################################################

  def self.fetch_to_utf8(str, encoding="UTF-8")
    return str if str.nil?
    if str.respond_to?(:force_encoding)
      begin
        cleaned = str.force_encoding('UTF-8')
        unless cleaned.valid_encoding?
          cleaned = str.encode('UTF-8', encoding, :invalid => :replace, :undef => :replace, :replace => '').chars.select{|i| i.valid_encoding?}.join
        end
        str = cleaned
      rescue EncodingError
        str.encode!( 'UTF-8', :invalid => :replace, :undef => :replace )
      end
    elsif RUBY_PLATFORM == 'java'
      begin
        ic = Iconv.new('UTF-8', encoding + '//IGNORE')
        str = ic.iconv(str)
      rescue
        str = str.gsub(%r{[^\r\n\t\x20-\x7e]}, '?')
      end
    else
      ic = Iconv.new('UTF-8', encoding + '//IGNORE')
      txtar = ""
      begin
        txtar += ic.iconv(str)
      rescue Iconv::IllegalSequence
        txtar += $!.success
        str = '?' + $!.failed[1,$!.failed.length]
        retry
      rescue
        txtar += $!.success
      end
      str = txtar
    end
    str
  end

end # class