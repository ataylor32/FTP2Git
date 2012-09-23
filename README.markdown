FTP 2 Git
=========

A Bash script that performs a one-way synchronization between one or more FTP folders and a Git repository. It is intended to be automatically run on a schedule.

What This Script Does
---------------------

0. Mounts the FTP location.

1. Performs a one-way synchronization between the FTP folder(s) and the Git repository.

2. Unmounts the FTP location.

3. Commits and pushes any changes that took place.

4. Optionally sends an e-mail if an error occurs along the way.

Purpose
-------

For various reasons, web developers sometimes find themselves in a situation where they are forced to work with a web host that only allows FTP access. I, myself, am in that situation with one of my clients. One of the features of this client's website is that users can upload files. Now, what if the server the website is hosted on fails and loses one or more of the files that the users uploaded? Do I trust that the web host will have a recent backup? And how long would it take for them to restore their most recent backup? I asked myself these questions and decided that I needed to keep a backup of user uploads myself. As we all know, the best kinds of backups are the kinds that are automated. So I wrote this Bash script, which now automatically runs on my computer every night. And thanks to Git, I can restore a file that was deleted months ago if the need arises.

Requirements
------------

**Note:** This script has only been tested on Mac OS 10.7.4 and Ubuntu 12.04.1.

* A Git repository that has an origin

* Ubuntu: The "curlftpfs" program (sudo apt-get install curlftpfs)

* Ubuntu: The "mail" program (sudo apt-get install mailutils) if you want an e-mail to be sent if an error occurs

Usage
-----

**Step 1:** Modify the parameters at the top of the script to your liking:

    path_to_git_repo="$HOME/Documents/ftp_backup"
    ftp_host=example.com
    ftp_username=johndoe
    ftp_password=hunter2
    ftp_mount_point=/Volumes/mount_ftp
    send_email_on_error=true
    send_email_to=example@gmail.com
    email_subject="Error Backing Up FTP Folders"

    sources_and_targets=(
    	"www/user_uploads:www"
    	"www/more_user_uploads:www"
    )

**Step 2:** Create a scheduled task to run the script as often as you would like.

Contact
-------

If you have any questions or comments, feel free to contact me here:

ataylor32@gmail.com