#!/bin/bash

# This script generates the hash table (size_overflow_hash.h) for the size_overflow gcc plugin (size_overflow_plugin.c).

header1="size_overflow_hash.h"
database="size_overflow_hash.data"
n=65536

usage() {
cat <<EOF
usage: $0 options
OPTIONS:
        -h|--help               help
	-o			header file
	-d			database file
	-n			hash array size
EOF
    return 0
}

while true
do
    case "$1" in
    -h|--help)	usage && exit 0;;
    -n)		n=$2; shift 2;;
    -o)		header1="$2"; shift 2;;
    -d)		database="$2"; shift 2;;
    --)		shift 1; break ;;
     *)		break ;;
    esac
done

create_defines() {
	for i in `seq 1 10`
	do
		echo -e "#define PARAM"$i" (1U << "$i")" >> "$header1"
	done
	echo >> "$header1"
}

create_structs () {
	rm -f "$header1"

	create_defines

	cat "$database" | while read data
	do
		data_array=($data)
		struct_hash_name="${data_array[0]}"
		funcn="${data_array[1]}"
		params="${data_array[2]}"
		next="${data_array[5]}"

		echo "struct size_overflow_hash $struct_hash_name = {" >> "$header1"

		echo -e "\t.next\t= $next,\n\t.name\t= \"$funcn\"," >> "$header1"
		echo -en "\t.param\t= " >> "$header1"
		line=
		for param_num in ${params//-/ };
		do
			line="${line}PARAM"$param_num"|"
		done

		echo -e "${line%?},\n};\n" >> "$header1"
	done
}

create_headers () {
	echo "struct size_overflow_hash *size_overflow_hash[$n] = {" >> "$header1"
}

create_array_elements () {
	index=0
	grep -v "nohasharray" $database | sort -n -k 4 | while read data
	do
		data_array=($data)
		i="${data_array[3]}"
		hash="${data_array[4]}"
		while [[ $index -lt $i ]]
		do
			echo -e "\t["$index"]\t= NULL," >> "$header1"
			index=$(($index + 1))
		done
		index=$(($index + 1))
		echo -e "\t["$i"]\t= &"$hash"," >> "$header1"
	done
	echo '};' >> $header1
}

create_structs
create_headers
create_array_elements

exit 0
