#!/bin/bash

###############################################################################
#
# Simple console frontend for ssh.
#
# This small bash script helps you to manage several ssh connections at the
# bash. Therefore it uses normal ssh command as underlying prgramm.
#
# author  : Daniel Kröger <dane0542@googlemail.com>
# version : 12.07.2013
#
###############################################################################

## BEGIN ENVIRONMENT VARIABLES ################################################

DATA_DIRECTORY="/home/`whoami`/.ssh_manager"
HOSTS=""

## END ENVIRONMENT VARIABLES ##################################################

## BEGIN INTERFACE FUNCTIONS ##################################################

# $1 - text to echo.
# $2 - color of text. (green, yellow, red, none)
# $3 - (optional) don't newline after text.
function print_text()
{       
    case $2 in
	    "green" ) tput setaf 10;;
	    "yellow") tput setaf 11;;
	    "red"   ) tput setaf 9;;
    esac
    
    if [ "$3" == "true" ]; then
        echo -e -n "$1"
    else
        echo -e "$1"
    fi   

    tput sgr0
}

# $1 - character to print.
# $2 - (optional) color (green, yellow, red, none).
function print_seperator()
{
    WIDTH="`tput cols`"
    TEXT=""

    while [ $WIDTH -gt 0 ]; do
	    TEXT+="$1"
	    WIDTH="$(( $WIDTH - 1 ))"
    done

    print_text "$TEXT" "$2"
}

# $1 - offset to start (number of echoed letters).
# $2 - character for lineend.
# $3 - (optional) color (green, yellow, red, none).
function print_lineend()
{  
    WIDTH="`tput cols`"
    WIDTH="$(( $WIDTH - $1 ))"
    WHITESPACE=""

    while [ $WIDTH -gt 1 ]; do
        WHITESPACE="${WHITESPACE} "        
	    WIDTH="$(( $WIDTH - 1 ))"
    done

    echo -n "$WHITESPACE"

    if [ "$2" == "" ]; then
	    print_text " " "" "true"
    else
        print_text "$2" "$3" "true"
    fi
}

# $1 - text to echo.
# $2 - color of text (green, yellow, red, none).
# $3 - offset for current position.
function print_centered_text()
{    
    WIDTH="`tput cols`"
    WIDTH="$(( $WIDTH - $3 ))"
    MIDDLE="$(( $WIDTH - ${#1} ))"
    MIDDLE="$(( $MIDDLE / 2 ))"
    TEXT=""    

    CURRENT="0"
    while [ $CURRENT -lt $MIDDLE ]; do
        TEXT="${TEXT} "	        
        CURRENT="$(( $CURRENT + 1 ))"
    done
    
    TEXT="${TEXT}${1}"

    if [ "$(( ($WIDTH - ${#1}) % 2 ))" == "1" ]; then
	    CURRENT="$(( $CURRENT + 1 ))"
    fi

    while [ $CURRENT -gt 0 ]; do
        TEXT="${TEXT} "
        CURRENT="$(( $CURRENT - 1 ))"
    done    

    print_text "$TEXT" "$2" "true"    
}

# $1 - String array with menu entries.
# $2 - if "true", print with stars at line begin and end.
function print_options()
{
    MENU="$1"
    COUNTER=0

    while [ $COUNTER -lt ${#MENU[*]} ]; do
        ENTRY="${MENU[$COUNTER]}"
        if [ "$2" == "true" ]; then
            print_text "*  " "green" "true"
	        print_text "$ENTRY" "yellow" "true"
            print_lineend "$(( ${#ENTRY} + 3 ))" "*" "green"
        else 
	        print_text "   $ENTRY" "yellow"
	    fi
	    COUNTER="$(( $COUNTER + 1 ))"       
    done
}

function print_menu()
{
    # fancy header and menu bar ...
    print_text "" ""
    print_seperator "*" "green"
    print_text "*" "green" "true"
    print_centered_text "SSH MANAGER - With great power comes great \
		responsibility !" "yellow" "2"
    print_text "*" "green" "true"
    print_seperator "*" "green"
    print_text "*" "green" "true"
    print_lineend "1" "*" "green"
    
    MENU[0]="[show    | s ] - Show a list of all available hosts to connect\
		to."
    MENU[1]="[connect | c ] - Connect to host by a number from list\
		(show command)."
    MENU[2]="[add     | a ] - Add host to list by setting up connection\
		information."
    MENU[3]="[delete  | d ] - Delete connection information of host from list."
    MENU[4]="[reset   | r ] - Reset all stored information, including public\
		and private keys."
    MENU[5]="[clear   | cl] - Clear the screen."
    MENU[6]="[help    | h ] - Print this help again and show available\
		commands."
    MENU[7]="[quit    | q ] - Quit ssh_manager script."

    # print available commands ...
    print_options "$MENU" "true"

    # fancy menu end ...
    print_text "*" "green" "true"
    print_lineend "1" "*" "green"
    print_seperator "*" "green"
    print_text "" ""
}

## END INTERFACE FUNCTIONS ####################################################

## BEGIN MAIN HELPER FUNCTIONS ################################################

function read_hosts()
{
    unset HOSTS
    COUNTER="1"

    while read HOST ; do
	    if [ "$HOST" != "" ]; then
	        HOSTS[$COUNTER]="$HOST"	
	        COUNTER="$(( $COUNTER + 1 ))"
	    fi
    done < "${DATA_DIRECTORY}/hosts"
}

function save_hosts()
{
    COUNTER="1"
    
    if [ -e "${DATA_DIRECTORY}/hosts" ]; then
        rm "${DATA_DIRECTORY}/hosts"
    fi

    while [ $COUNTER -le ${#HOSTS[*]} ]; do
	    echo "${HOSTS[$COUNTER]}" >> "${DATA_DIRECTORY}/hosts"
	    COUNTER="$(( $COUNTER + 1 ))"
    done
}

function bootstrap()
{
    # check if working directory exists, if not create it ...
    if [ -d "$DATA_DIRECTORY" ] && [ -w "$DATA_DIRECTORY" ]; then
	    read_hosts
    else
	    if [ -w "/home/`whoami`/" ]; then
	        mkdir "$DATA_DIRECTORY"
	        chmod 700 "$DATA_DIRECTORY"
	        touch "${DATA_DIRECTORY}/hosts"
	        chmod 600 "${DATA_DIRECTORY}/hosts"
	        bootstrap
	    else
	        print_text "Cannot create necessary directory ${DATA_DIRECTORY}\
				and files in it. Please check permissions and retry !" "red"
            print_text "Execution failed with errors - Quitting now !" "red"
            exit 1
	    fi
    fi
}

function list_hosts()
{
    if [ ${#HOSTS[1]} -gt 0 ]; then
	    COUNTER="1"

	    while [ $COUNTER -le ${#HOSTS[*]} ]; do
	        if [ "${HOSTS[$COUNTER]}" != "" ]; then
		        print_text "   $COUNTER ${HOSTS[$COUNTER]}" "yellow"
	        fi
	        COUNTER="$(( $COUNTER + 1 ))"
	    done
    else
	    print_text "No connections setup yet !" "red"
	    print_text "Please setup at least one connection to use 'show' mode !"\
			"red"	
    fi	
}

function reset()
{
    ANSWER=""

    print_text "Enter 'yes' if you really want to delete all saved\
		configurations and keys : " "yellow" "true"
    read ANSWER

    print_text "" ""
    if [ "$ANSWER" == "yes" ]; then
	    rm -rf "${DATA_DIRECTORY}"
	    print_text "It'll look like we've never been at this place !" "green" 
	    print_text "Quitting now !" "green"
	    print_text "" ""		
	    exit 0
    else
	    print_text "Aborting ! You're now at main menu again." "red"	
    fi
}

function connect()
{
    ANSWER=""

    if [ ${#HOSTS[1]} -gt 0 ]; then
	    print_text "Please enter number of host to connect to (1-${#HOSTS[*]})\
			: " "yellow" "true"
	    read ANSWER
	    print_text "" ""                        

	    if [[ $ANSWER = [[:digit:]]* ]] && [ $ANSWER -gt 0 ] &&\
			[ $ANSWER -le ${#HOSTS[*]} ]; then
	        print_text "[`date '+%d.%m.%Y %H:%M:%S'`] " "" "true" 
	        print_text "Executing command ${HOSTS[$ANSWER]}" "yellow"

	        print_text "[`date '+%d.%m.%Y %H:%M:%S'`] " "" "true" 
	        print_text "Establishing connection ..." "green"

	        print_text "" ""
	        eval "${HOSTS[$ANSWER]}"
	        print_text "" ""

	        if [ $? != 0 ]; then	
	            print_text "[`date '+%d.%m.%Y %H:%M:%S'`] " "" "true" 
		        print_text "Ups ! Something went wrongi, aborting ..." "red"
	        else	
	            print_text "[`date '+%d.%m.%Y %H:%M:%S'`] " "" "true" 
		    print_text "Connection closed." "green"
	        fi
	    else
	        print_text "Invalid number $ANSWER ! Aborting ..." "red"
	    fi
    else
	    print_text "No connections setup yet !" "red"
	    print_text "Please setup at least one connection to use 'connect' mode\
			!" "red"
    fi
}

function add_host()
{
    HOST=""
    USER=""
    PORT=""
    COMMAND=""

    print_text "Please enter hostname or ip of target (e.g. google.de) : "\
		"yellow" "true"
    read HOST

    print_text "Please enter username to login with (e.g. otto) : "\
		"yellow" "true"
    read USER

    print_text "Please enter port number of target host (e.g. 20) : "\
		"yellow" "true"
    read PORT

    COMMAND="ssh -p $PORT ${USER}@${HOST}"
    print_text "" ""
    print_text "This is my guess for ssh command '${COMMAND}' ! Does this look\
		correct (yes|no) ? : " "yellow" "true"
    read ANSWER
    print_text "" ""

    if [ "$ANSWER" == "yes" ]; then
	    if [ ${#HOSTS[*]} -eq 0 ]; then
	        HOSTS[1]="$COMMAND"        
    	else
	        HOSTS[$(( ${#HOSTS[*]} + 1 ))]="$COMMAND"
        fi	

    	save_hosts
        read_hosts
        print_text "Saved host to connection list." "green"	
	    print_text "" ""	    
    else
	    print_text "Reenter connection information (yes|no) ? : " "yellow"\
			"true"
	    read ANSWER
	    print_text "" ""
	    if [ "$ANSWER" == "yes" ]; then
	        add_host
	    else
	        print_text "Aborting !" "red"
	    fi
    fi         
}

function delete_host
{    
    ANSWER=""

    if [ ${#HOSTS[1]} -gt 0 ]; then
	    print_text "Please enter number of host to delete (1-${#HOSTS[*]}) : "\
			"yellow" "true"
	    read ANSWER
	    print_text "" ""                        

	    if [[ $ANSWER = [[:digit:]]* ]] && [ $ANSWER -gt 0 ] &&\
			[ $ANSWER -le ${#HOSTS[*]} ]; then
            HOSTS_NEW=""
            COUNTER="1"
            POSITION="1"

            while [[ $COUNTER -le ${#HOSTS[*]} ]]; do
                if [ $COUNTER != $ANSWER ]; then
                    HOSTS_NEW[${POSITION}]=${HOSTS[${COUNTER}]}
                    POSITION="$(( $POSITION + 1 ))"
                fi
                COUNTER="$(( $COUNTER + 1 ))"
            done

            unset HOSTS

            COUNTER="1"
            while [[ $COUNTER -le ${#HOSTS_NEW[*]} ]]; do
                HOSTS[${COUNTER}]=${HOSTS_NEW[${COUNTER}]}
                COUNTER="$(( $COUNTER + 1 ))"
            done

            unset HOSTS_NEW
            save_hosts
            read_hosts

            print_text "Successfully deleted host !" "green"
        else
            print_text "Invalid number - aborting !" "red"
        fi
    else
	    print_text "No connections setup yet !" "red"
	    print_text "Please setup at least one connection to use 'delete'\
			mode !" "red"
    fi
}

## END MAIN HELPER FUNCTION ###################################################

## BEGIN MAIN PROGRAM EXECUTION CODE ##########################################

bootstrap
print_menu

ANSWER=""
while [ "$ANSWER" != "quit" ] || [ "$ANSWER" != "q" ]; do

    print_text "> " "yellow" "true"
    read ANSWER

    case "$ANSWER" in 
	"show"    ) print_text "" ""; list_hosts; print_text "" "";;
	"s"       ) print_text "" ""; list_hosts; print_text "" "";;
	"connect" ) print_text "" ""; connect; print_text "" "";;
	"c"	      ) print_text "" ""; connect; print_text "" "";;
	"add"	  ) print_text "" ""; add_host; print_text "" "";;
	"a"	      ) print_text "" ""; add_host; print_text "" "";;
	"delete"  ) print_text "" ""; delete_host; print_text "" "";;
	"d"	      ) print_text "" ""; delete_host; print_text "" "";;
	"reset"   ) print_text "" ""; reset; print_text "" "";;
	"r"       ) print_text "" ""; reset; print_text "" "";;
	"clear"   ) clear; print_menu;;
	"cl"      ) clear; print_menu;;
	"help"    ) print_options; print_text "" "";;
	"h"       ) print_options; print_text "" "";;
	"quit"    ) print_text "" ""; print_text "Quitting now !" "green";\
		print_text "" ""; exit 0;;
	"q"       ) print_text "" ""; print_text "Quitting now !" "green";\
		print_text "" ""; exit 0;;
	*         ) print_text "" ""; print_text "Unknown command, please\
		enter a valid. You can type 'help' to get a list of valid commands."\
			"red"; print_text "" "";;
    esac
done