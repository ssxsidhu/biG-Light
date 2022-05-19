#!/bin/bash


help()
 {
   echo "This program simply generates text banners"
   echo
   echo "Syntax: ./bigLight.sh [-f 'Font File'] 'Text to print'"
   echo "options:"
   echo "-h     Print this Help."
   echo "-f     Font used to print the text , requires an argument"
   echo "-s     option used to add space between letters"
   echo "-V     Print software version and exit."
   echo
   echo "Goodbye!"
}

version()
{
echo "bigLight v1.0"
}


row()
{
    local COL
    local ROW
    IFS=';' read -sdR -p $'\E[6n' ROW COL
    echo "${ROW#*[}"
}

printer() 
{
for i in $(seq 0 $numLines); do
if [[ "$i" != "$numLines" ]]; then
echo -e "${result[$i]}"
else
echo -en "${result[$i]}"
fi
done

}

update()
{
if [[ "$2" == "newline" ]]; then
result[0]="\n"
for i in $(seq 1 $1); do
result[$i]=""
done
else
# echo hello
for i in $(seq 0 $1); do
result[$i]+="${name[$i]}"
done
fi
}


checker()
{
returnVal=$(sed -n '1,50p' "$fontFile" | grep -q "$1" ; echo $?)
echo $returnVal
}


breakPoint()
{
check1=$(checker '$@@')
check2=$(checker "##")
if ((!$check1)) ; then
breakCh='$@'
elif ((!$check2)); then
breakCh="#"
else
breakCh="@"
fi

}




main ()
{
breakPoint
breakList=($(cat "$fontFile" | grep -n "$breakCh$breakCh" | cut -d ":" -f 1)) 
argList=( $(echo "$1" | sed '{s/ /:,/g; s/./& /g}') )
# declare -A tarray

printf -v start "%d" "' '"
printf -v end "%d" "'~'"

i=$start
lastLine=$(grep -n -o "$breakCh" $fontFile | head -n1 | cut -d":" -f1)
for lineBreak in "${breakList[@]}"; do

# if (("$i" <= $end)); then
# char=$(echo "$i" | awk '{printf "%c",$1}')
# fi

readarray -t figList$i< <(sed -n "$lastLine,$lineBreak{$space s/\\\$/ /g ; s/\(.*\)$breakCh$breakCh/\1/p; s/\(.*\)$breakCh/\1/p; }" "$fontFile")

len=$(($lineBreak-$lastLine+1))
read length[$i] <<< $len

# tarray["$char"]=figList$i[@]

lastLine=$(("$lineBreak"+1))
i=$(("$i" + 1))

done

# printf "%s\n" "${!tarray[,]}"

result=()
count=0
track=0

for i in ${argList[@]}; do
if [[ "$count" -lt $((${#argList[@]}-1)) ]] && [[ "$count" != "0" ]]; then
nextChar=${argList[$((count+1))]}
lastChar=${argList[$((count-1))]}
fi

if [ "$i$nextChar" == ":," ] || [ "$lastChar$i" == ":," ]; then
i=" "
fi

((count+=1))

printf -v num "%d" "'$i'"
typeset -n name=figList$num
((track+=1))

columns=$(tput cols)
limit=$(($columns/7))
currentRow=$(row)
numLines="${length[$num]}"

if [[ "$track" -gt "$limit" ]]; then
printer 
update $numLines newline
track=0
update $numLines
else
update $numLines
fi

done
printer 
}


modifyFont(){

cat $1 | tr '\r' '\n' | sed '/^$/d' >> $1t
rm $1 && cat $1t >> $1 && rm $1t

}




my_dir=$(dirname "$(readlink -f "$0")")
fontFile="$my_dir/standard.flf"
space='s/ //;'

while getopts ":f:hVs" opt ;do
case $opt in
h)
help
exit 
;;
V)
version
exit
;;
f)
modifyFont "$OPTARG" 
fontFile="$my_dir/$OPTARG"
shift $((OPTIND-=1))
;;
s)
space=''
shift $((OPTIND-=1))
;;
\?)
echo "invalid option: -$OPTARG " >&2
help
exit 1
;;
:)
echo "Option -$OPTARG requires an argument." >&2
help
exit 1
;;
esac
done

toPrint="$@"
if [ "$#" == "0" ]; then
while IFS= read -r toPrint; do
main "$toPrint"
done 
else
main "$toPrint"
fi
