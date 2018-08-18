# redmine_fetch_email_attachments

This is a plugin for redmine to fetch email attachments from a user individual email account. The user email account can be configured in "My Account" for each individual user.

![animated GIF that represents a quick overview](/doc/Overview.gif)

### Use case
* download scans from a scanner directly into the issue edit dialog


### Install 

1. download plugin and copy plugin folder redmine_fetch_email_attachments go to Redmine's plugins folder 

2. install gems

go to Redmine root folder

`bundle install`

3. restart Redmine, f.i.

`/etc/init.d/apache2 restart`

### Uninstall

1. go to your plugins folder, delete plugin folder redmine_fetch_email_attachments

`rm -r redmine_fetch_email_attachments`

2. restart Redmine, f.i.

`/etc/init.d/apache2 restart`

### Use

Go to "My Account" and configure your email account credentials. Aside from email you can enable to attach project documents from the project documents module or reattach journal attachments. The latter is for a redmine email client, wich edits emails inline an issue.

**Have fun!**

### Localisations

* English
* German

### Change.Log

* **2.0.2** July 3rd commit
