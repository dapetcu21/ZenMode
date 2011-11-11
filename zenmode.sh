#!/bin/bash

target=""
add="127.0.0.1	"
scriptname=$(readlink "$0")
base="$(cd -P "$(dirname "$scriptname")" && pwd)" 
stop_zen()	{
	echo "Stopping zen mode ..."

	target=$(read_file /etc/.hosts "\n")
	sudo rm /etc/.hosts
	
	aux=$(echo -e $target | sudo tee /etc/hosts)
}
start_zen()	{
	echo "Starting zen mode ..."
	
	script="$base/denials"
	add="$add$(crawl $script) "
	target=$(read_file /etc/hosts "\n")

	aux=$(echo -e $target | sudo tee /etc/.hosts)
	target="$target\n$add"
	aux=$(echo -e $target | sudo tee /etc/hosts)
}
read_file()	{
	c=""
	while read line
	do
		c="$c$line$2"
	done < $1
	l=$((${#c} - 2))
	echo ${c:0:l}
}
crawl()	 {
	script=$1
	add=""
	if [ -a $script ]; then
		script="$script/*"
		for file in $script
		do
			add="$add${file##*\/} "
		done
	fi
	echo $add
}
case "$1" in
	start|-s)
		if [[ -a /etc/.hosts ]]; then
			echo "Zen mode already started"
		else
			start_zen
		fi
		;;
	stop|-k)
		if [[ -a /etc/.hosts ]]; then
			stop_zen
		else
			echo "Zen mode already stopped"
		fi
		;;
	restart|reload|-r)
		[[ -a /etc/.hosts ]] && stop_zen
		start_zen
		;;
	allow|-a)
		if [ -a "$base/denials/$2" ]; then 
			rm "$base/denials/$2"
		else 
			echo "Website not denied!"
			exit 1
		fi
		[[ -a /etc/.hosts ]] && stop_zen && start_zen
		;;
	deny|-d)
		if [ -a "$base/denials/$2" ]; then
			echo "Website already denied!"
			exit 1
		else
			touch "$base/denials/$2"
		fi
		[[ -a /etc/.hosts ]] && stop_zen && start_zen
		;;
	list|-l)	
		list="\n"$(crawl "$base/denials")
		list=${list//\ /"\n"}"\n"
		echo -e $list
		;;
	install)
		target="/usr/local/bin"
		if [ -a "$target/zm" ] || [ -h "$target/zm" ];
		then
			sudo rm "$target/zm"
		fi
		if [ -a "$target/zenmode" ] || [ -h "$target/zenmode" ]; then
		       	sudo rm "$target/zenmode"
		fi
		if [ "$2" = "--short" ];
		then
			target="$target/zm"
		else
			target="$target/zenmode"
		fi
		file=$(readlink "$0")
		if [ "$scriptname" == "" ]; then
			file=$0
		else 
			file=$scriptname
		fi
		file=${file##*/}
		sudo ln -s "$base/$file" $target
		;;
	*)
		echo "Usage: zenmode [options]"
	    echo "  Options available:"
		echo "    start   (-s)           : Start Zen Mode"
		echo "    stop    (-k)           : Stop Zen Mode"
		echo "    restart (-r) reload    : Restart Zen Mode"
		echo "    allow   (-a) <website> : Enable access to the specified website domain"
		echo "    deny    (-d) <website> : Deny access to the specified website domain"
		echo "    list    (-l)           : Print the denial list"	
		echo "    install (--short)      : Install ZenMode (--short installs under the name \"zm\")"
		echo
		exit 1
		;;
esac
