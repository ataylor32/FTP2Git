#!/bin/bash

# Most of the custom configuration variables should be self-explanatory, though
# there are some details about the "$sources_and_targets" variable that you
# should be aware of. In order to maximize compatibility, it is not a true
# associative array; it is a pseudo one. The FTP folder path appears to the left
# of the colon and the local folder path appears to the right of the colon.
# Neither path should begin with a slash.

# BEGIN CUSTOM CONFIGURATION

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

# END CUSTOM CONFIGURATION

# The "email_error" function is used to e-mail error messages when errors occur,
# but only if the "$send_email_on_error" custom configuration variable is set to
# "true".

function email_error() {
	echo
	echo "Sending an e-mail to $send_email_to ..."
	echo $1 | mail -s "$email_subject" $send_email_to
}

command -v git >/dev/null 2>&1 || {
	email_body="Git does not appear to be installed."

	echo >&2 $email_body

	if [ $send_email_on_error == true ]; then
		email_error "$email_body"
	fi

	exit 1
}

if [ -d "$path_to_git_repo" ]; then
	cd "$path_to_git_repo"

	if git rev-parse --git-dir > /dev/null 2>&1; then
		if git remote show origin > /dev/null 2>&1; then
			if [ `command -v mount_ftp` ]; then
				ftp_program=mount_ftp
			elif [ `command -v curlftpfs` ]; then
				ftp_program=curlftpfs
			fi

			if [ ! -z $ftp_program ]; then
				if [ `command -v diskutil` ]; then
					unmount_program=diskutil
				elif [ `command -v fusermount` ]; then
					unmount_program=fusermount
				fi

				if [ ! -z $unmount_program ]; then
					if [ ! -d "$ftp_mount_point" ]; then
						echo "Creating the following folder for the mount point:"
						echo
						echo "$ftp_mount_point"
						echo

						mkdir -p "$ftp_mount_point"
					fi

					if [ -d "$ftp_mount_point" ]; then
						echo "Mounting the FTP location ..."
						echo

						$ftp_program ftp://$ftp_username:$ftp_password@$ftp_host "$ftp_mount_point"

						if [ $? == 0 ]; then
							echo "Mount successful!"
							echo
							echo "Beginning synchronization ..."
							echo
							echo " ------------------------------------------------------------------------------"

							for source_and_target in "${sources_and_targets[@]}"; do
								source=${source_and_target%%:*}
								target=${source_and_target##*:}

								if [ -d "$ftp_mount_point/$source" ]; then
									if [ ! -d "$path_to_git_repo/$target" ]; then
										mkdir -p "$path_to_git_repo/$target"
									fi

									rsync -a --delete-after --progress --stats "$ftp_mount_point/$source" "$path_to_git_repo/$target"
								fi
							done

							echo " ------------------------------------------------------------------------------"
							echo
							echo "Unmounting the FTP location ..."
							echo

							if [ $unmount_program == "diskutil" ]; then
								diskutil unmount "$ftp_mount_point"
								echo
							else
								fusermount -u "$ftp_mount_point"
							fi

							if [ -d "$ftp_mount_point" ]; then
								rmdir "$ftp_mount_point"
							fi

							echo "Running Git commands ..."
							echo

							# Stage file additions and modifications.

							git add . && \

							# Stage file deletions.

							git add -u && \

							git commit -m "Committed via Bash script" && \

							git push origin HEAD
						else
							rmdir "$ftp_mount_point"

							echo >&2 "Mount failed!"

							if [ $send_email_on_error == true ]; then
								email_error "An error occurred mounting the FTP location."
							fi

							exit 1
						fi
					else
						echo >&2 "An error occurred creating the following folder:"
						echo >&2
						echo >&2 $ftp_mount_point

						if [ $send_email_on_error == true ]; then
							email_error "An error occurred creating the \"$ftp_mount_point\" folder."
						fi

						exit 1
					fi
				else
					email_body="Unable to find a program to unmount the FTP location."

					echo >&2 $email_body

					if [ $send_email_on_error == true ]; then
						email_error "$email_body"
					fi

					exit 1
				fi
			else
				email_body="Unable to find a program to mount the FTP location."

				echo >&2 $email_body

				if [ $send_email_on_error == true ]; then
					email_error "$email_body"
				fi

				exit 1
			fi
		else
			email_body="The Git repository has no origin."

			echo >&2 $email_body

			if [ $send_email_on_error == true ]; then
				email_error "$email_body"
			fi

			exit 1
		fi
	else
		echo >&2 "It appears that the following folder is not a Git repository or you do not have"
		echo >&2 "permission to access it:"
		echo >&2
		echo >&2 $path_to_git_repo

		if [ $send_email_on_error == true ]; then
			email_error "It appears that the \"$path_to_git_repo\" folder is not a Git repository or you do not have permission to access it."
		fi

		exit 1
	fi
else
	echo >&2 "The following folder does not exist:"
	echo >&2
	echo >&2 $path_to_git_repo

	if [ $send_email_on_error == true ]; then
		email_error "The \"$path_to_git_repo\" folder does not exist."
	fi

	exit 1
fi