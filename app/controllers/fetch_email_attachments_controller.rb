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

class FetchEmailAttachmentsController < ApplicationController
  unloadable
  
  helper :attachments
  include AttachmentsHelper
  
  # create set and read methods for class globals
  attr_accessor :gUser, :gJournal, :gIssue, :gProject, :gFeedback_message_area, :gMessageType, :gMessage
  
  # always read project, issue and user from params
  before_filter :pInitialize
  before_filter :pFind_project_issue_user, :except => [:fetch, :reload_hook]
  before_filter :pFind_project_email, :only => [:reload_hook]

##########################################################################################
#                                                                                        #
#  +public+public+public+public+public+public+public+public+public+public+public+public+ #
#                                                                                        #
##########################################################################################

##########################################################################################
#                                                                                        #
#  attach_user_mail_to_issue - fetch  mails for user and attach to issue                 #
#                                                                                        #
##########################################################################################

  def fetch
  
    ###########################################################
    #                                                         #
    #  fetch all attachments from all unread mails            #
    #                                                         #
    ###########################################################
    @file_attachments, msg_count = FetchEmailAttachmentsMailer.check_user_mail(User.current.id)

	@file_attachments.flatten!
	@file_attachments.compact!


    ###########################################################
    #                                                         #
    #  create feedback message                                #
    #                                                         #
    ###########################################################	
	@file_attachments.each do |attachment|
	    @gMessage= @gMessage + "<li>\n" + attachment.filename + "\n"
	end # #do
	
	if @gMessage.length > 0
	  @gMessage= "<br><ul>" + @gMessage + "</ul>"
	end
	
    ###########################################################
    #                                                         #
    #  pass on thumbnail size                                 #
    #                                                         #
    ###########################################################	
    @thumbnail_size = Setting.thumbnails_size
    
	@gMessage= "<div class='flash notice'> #{l(:label_fetch_success, :count => msg_count)}</a>" + @gMessage + "</div>"
    pSet_feedback_params
    
    respond_to do |format|
		format.js do
		     render :action => 'upload', :status => :created
			flash.discard
		end
    end

  rescue Exception => e
     respond_to do |format|
       format.js do
		 @gMessage= "<div class='flash warning'>FetchEmailAttachments fetch Error: #{e.message}</div>"
         pSet_feedback_params
         Rails.logger.error "FetchEmailAttachments fetch Error: #{e.message}" if Rails.logger && Rails.logger.error
         Rails.logger.error "FetchEmailAttachments fetch Error: #{e.backtrace.join("\n")}" if Rails.logger && Rails.logger.error
         flash.discard
       end
       format.html {redirect_to :back}
     end  
  end

##########################################################################################
#                                                                                        #
#  attach_user_mail_to_issue - fetch  mails for user and attach to issue                 #
#                                                                                        #
##########################################################################################

  def reload_hook
  
    @frame_id             = params[:frame_id]
	@content              = render_to_string :partial => "fetch_for_project_emails"
	
	respond_to do |format|
	  format.js do
		  # will render reload_hook
		  flash.discard
	  end
	end
  
  end #def

##########################################################################################
#                                                                                        #
#  attach_user_mail_to_issue - fetch  mails for user and attach to issue                 #
#                                                                                        #
##########################################################################################

  def reattach

	@file_attachments = []
	
    ###########################################################
    #                                                         #
    #  fetch all attachments from issue and make a copy!      #
    #                                                         #
    ###########################################################

    @gIssue.attachments.each do |attachment|
		@gMessage= @gMessage + "<li>\n" + attachment.filename + "\n"
		
		new_attachment = Attachment.new
		new_attachment.attributes = attachment.attributes.dup.except("id", "downloads", "container_id", "container_type")
		new_attachment.assign_attributes(:author_id => @gUser.id)

		new_attachment.save!
		@file_attachments << new_attachment
     end
    
	if @gMessage.length > 0
	  @gMessage= "<br><ul>" + @gMessage + "</ul>"
	end

	@file_attachments.flatten!
	@file_attachments.compact!

    ###########################################################
    #                                                         #
    #  pass on thumbnail size                                 #
    #                                                         #
    ###########################################################	
    @thumbnail_size = Setting.thumbnails_size

    ###########################################################
    #                                                         #
    #  give feedback about attachments                        #
    #                                                         #
    ###########################################################	
    
	@gMessage= "<div class='flash notice'> #{l(:label_issue_attachments_success, :count => @file_attachments.count)}</a>" + @gMessage + "</div>"
    pSet_feedback_params

    respond_to do |format|
		format.js do
		    render :action => 'upload', :status => :created
			flash.discard
		end
    end

  rescue Exception => e
     respond_to do |format|
       format.js do
		 @gMessage= "<div class='flash warning'>Reattach IssueAttachments Error: #{e.message}</div>"
         pSet_feedback_params
         Rails.logger.error "Reattach IssueAttachments Error: #{e.message}" if Rails.logger && Rails.logger.error
         Rails.logger.error "Reattach IssueAttachments Error: #{e.backtrace.join("\n")}" if Rails.logger && Rails.logger.error
         flash.discard
       end
       format.html {redirect_to :back}
     end  
  end

##########################################################################################
#                                                                                        #
#  attach_user_mail_to_issue - fetch  mails for user and attach to issue                 #
#                                                                                        #
##########################################################################################

  def reattach_named_attachment

	@file_attachments = []
	
    ###########################################################
    #                                                         #
    #  fetch all attachments from issue and make a copy!      #
    #                                                         #
    ###########################################################

    attachment = Attachment.find_by_id(params[:issue_attachment_id])
    if attachment.present? 
	  @gMessage= @gMessage + "<li>\n" + attachment.filename + "\n"
	
	  new_attachment = Attachment.new
	  new_attachment.attributes = attachment.attributes.dup.except("id", "downloads", "container_id", "container_type")
	  new_attachment.assign_attributes(:author_id => @gUser.id)

	  new_attachment.save!
	  @file_attachments << new_attachment
    end
    
	if @gMessage.length > 0
	  @gMessage= "<br><ul>" + @gMessage + "</ul>"
	end

	@file_attachments.flatten!
	@file_attachments.compact!

    ###########################################################
    #                                                         #
    #  pass on thumbnail size                                 #
    #                                                         #
    ###########################################################	
    @thumbnail_size = Setting.thumbnails_size

    ###########################################################
    #                                                         #
    #  give feedback about attachments                        #
    #                                                         #
    ###########################################################	
    
	@gMessage= "<div class='flash notice'> #{l(:label_issue_attachments_success, :count => @file_attachments.count)}</a>" + @gMessage + "</div>"
    pSet_feedback_params

    respond_to do |format|
		format.js do
		    render :action => 'upload', :status => :created
			flash.discard
		end
    end
    
  rescue Exception => e
     respond_to do |format|
       format.js do
		 @gMessage= "<div class='flash warning'>Reattach IssueAttachments Error: #{e.message}</div>"
         pSet_feedback_params
         Rails.logger.error "Reattach IssueAttachments Error: #{e.message}" if Rails.logger && Rails.logger.error
         Rails.logger.error "Reattach IssueAttachments Error: #{e.backtrace.join("\n")}" if Rails.logger && Rails.logger.error
         flash.discard
       end
       format.html {redirect_to :back}
     end  
  end

##########################################################################################
#                                                                                        #
#  attach_user_mail_to_issue - fetch  mails for user and attach to issue                 #
#                                                                                        #
##########################################################################################

  def reattach_journal

	@file_attachments = []
	
    ###########################################################
    #                                                         #
    #  fetch all attachments from journal and make a copy!      #
    #                                                         #
    ###########################################################

	if Attachment.find_by_id(detail.prop_key)
	  attachment = Attachment.find_by_id(detail.prop_key)
	  
	  @gMessage= @gMessage + "<li>\n" + attachment.filename + "\n"
	
	  new_attachment = Attachment.new
	  new_attachment.attributes = attachment.attributes.dup.except("id", "downloads", "container_id", "container_type")
	  new_attachment.assign_attributes(:author_id => @gUser.id)

	  new_attachment.save!
	  @file_attachments << new_attachment
	end
    
	if @gMessage.length > 0
	  @gMessage= "<br><ul>" + @gMessage + "</ul>"
	end

	@file_attachments.flatten!
	@file_attachments.compact!

    ###########################################################
    #                                                         #
    #  pass on thumbnail size                                 #
    #                                                         #
    ###########################################################	
    @thumbnail_size = Setting.thumbnails_size

    ###########################################################
    #                                                         #
    #  give feedback about attachments                        #
    #                                                         #
    ###########################################################	
    
	@gMessage= "<div class='flash notice'> #{l(:label_journal_attachments_success, :count => @file_attachments.count)}</a>" + @gMessage + "</div>"
    pSet_feedback_params

    respond_to do |format|
		format.js do
		    render :action => 'upload', :status => :created
			flash.discard
		end
    end

  rescue Exception => e
     respond_to do |format|
       format.js do
		 @gMessage= "<div class='flash warning'>Reattach JournalAttachments Error: #{e.message}</div>"
         pSet_feedback_params
         Rails.logger.error "Reattach JournalAttachments Error: #{e.message}" if Rails.logger && Rails.logger.error
         Rails.logger.error "Reattach JournalAttachments Error: #{e.backtrace.join("\n")}" if Rails.logger && Rails.logger.error
         flash.discard
       end
       format.html {redirect_to :back}
     end  
  end

##########################################################################################
#                                                                                        #
#  attach_user_mail_to_issue - fetch  mails for user and attach to issue                 #
#                                                                                        #
##########################################################################################

  def reattach_project_documents

	@file_attachments = []
	
    ###########################################################
    #                                                         #
    #  fetch all attachments from project documents and make  #
    #  a copy!                                                #
    #                                                         #
    ###########################################################

	document = Document.find_by_id(params[:document_id])

    unless document.nil?
	  document.attachments.each do |attachment|
	
		 @gMessage= @gMessage + "<li>\n" + attachment.filename + "\n"
   										 
         new_attachment = Attachment.new
         new_attachment.attributes = attachment.attributes.dup.except("id", "downloads", "container_id", "container_type")
         new_attachment.assign_attributes(:author_id => @gUser.id)

		 new_attachment.save!
		 @file_attachments << new_attachment
	   end
     end
    
	if @gMessage.length > 0
	  @gMessage= "<br><ul>" + @gMessage + "</ul>"
	end

	@file_attachments.flatten!
	@file_attachments.compact!

    ###########################################################
    #                                                         #
    #  pass on thumbnail size                                 #
    #                                                         #
    ###########################################################	
    @thumbnail_size = Setting.thumbnails_size

    ###########################################################
    #                                                         #
    #  give feedback about attachments                        #
    #                                                         #
    ###########################################################	
    
	unless document.nil?
		@gMessage= "<div class='flash notice'> #{l(:label_documents_attachments_success, :count => @file_attachments.count)}</a>" + @gMessage + "</div>"
	else
		@gMessage= "error"
	end
    pSet_feedback_params

    respond_to do |format|
		format.js do
		    render :action => 'upload', :status => :created
			flash.discard
		end
    end

  rescue Exception => e
     respond_to do |format|
       format.js do
		 @gMessage= "<div class='flash warning'>Reattach ProjectDocuments Error: #{e.message}</div>"
         pSet_feedback_params
         Rails.logger.error "Reattach ProjectDocuments Error: #{e.message}" if Rails.logger && Rails.logger.error
         Rails.logger.error "Reattach ProjectDocuments Error: #{e.backtrace.join("\n")}" if Rails.logger && Rails.logger.error
         flash.discard
       end
       format.html {redirect_to :back}
     end  
  end


##########################################################################################
#                                                                                        #
#   +private+private+private+private+private+private+private+private+private+private+    #
#                                                                                        #
##########################################################################################

private

##########################################################################################
#                                                                                        #
#   initialize: set instance variables default values                                    #
#                                                                                        #
##########################################################################################

  def pInitialize
  
    @gFeedback_message_area= (params[:feedback_message_area] && params[:feedback_message_area].blank?) ? "header" : params[:feedback_message_area]
    @gMessageType= "warning"
    @gMessage= ""
  
  end #def

##########################################################################################
#                                                                                        #
#   pFind_project_issue_user: get project, issue and user from params, may fail          #
#                                                                                        #
##########################################################################################

  def pFind_project_issue_user

    issue_id     = params[:issue_id]   || (params[:issue]   && params[:issue][:id])
    project_id   = params[:project_id] || (params[:issue]   && params[:issue][:project_id])
    journal_id   = params[:journal_id] || (params[:journal] && params[:journal][:id])


    @gUser=       User.current
    @gIssue=	  Issue.find_by_id(issue_id)
    @gJournal=    Journal.find_by_id(journal_id)
    @gProject=    Project.find(project_id)
           
  rescue ActiveRecord::RecordNotFound
  
    @gMessage ="<div class='flash error'>find_project_issue_user: could not find issue_id, project_id or journal_id</div>"     
    pSet_feedback_params
   
    respond_to do |format|
      format.js do        
        flash.discard
      end # do
        format.html {render :text => gMessage }
    end #do
  end #rescue

##########################################################################################
#                                                                                        #
#   pFind_project_email:                                                                 #
#                                                                                        #
##########################################################################################

  def pFind_project_email

    project_email_id  = params[ :project_email_id ] 
    @project_email    = ProjectEmail.find( project_email_id ) 
    @project          = @project_email.project
           
  rescue ActiveRecord::RecordNotFound
  
    @gMessage ="<div class='flash error'>find_project_issue_user: could not find project email #{params[:project_email_id]}</div>"     
    pSet_feedback_params
   
    respond_to do |format|
      format.js do        
        flash.discard
      end # do
        format.html {render :text => gMessage }
    end #do
  end #rescue

 
##########################################################################################
#                                                                                        #
#   pSet_feedback_params: set parameters vor javascript feedback                         #
#                                                                                        #
##########################################################################################

  def pSet_feedback_params  
  
    @feedback_message_area= @gFeedback_message_area
    @message_type= 			@gMessageType
    @message= 				@gMessage

  end #def

end # class