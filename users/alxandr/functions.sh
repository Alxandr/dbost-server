# shellcheck shell=sh

# Path aliases
path_remove() {
	PATH=$(echo -n "$PATH" | awk -v RS=: -v ORS=: "\$0 != \"$1\"" | sed 's/:$//')
}

path_append() {
	path_remove "$1"
	PATH="${PATH:+"$PATH:"}$1"
}

path_prepend() {
	path_remove "$1"
	PATH="$1${PATH:+":$PATH"}"
}

# Create a directory and cd into it
mcd() {
	mkdir "${1}" && cd "${1}"
}

# Go up [n] directories
up() {
	local cdir="$(pwd)"
	if [[ "${1}" == "" ]]; then
		cdir="$(dirname "${cdir}")"
	elif ! [[ "${1}" =~ ^[0-9]+$ ]]; then
		echo "Error: argument must be a number"
	elif ! [[ "${1}" -gt "0" ]]; then
		echo "Error: argument must be positive"
	else
		for ((i = 0; i < ${1}; i++)); do
			local ncdir="$(dirname "${cdir}")"
			if [[ "${cdir}" == "${ncdir}" ]]; then
				break
			else
				cdir="${ncdir}"
			fi
		done
	fi
	cd "${cdir}"
}
