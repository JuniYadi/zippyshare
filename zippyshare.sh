#!/bin/bash
# @Description: zippyshare.com file download script
# @Author: Juni Yadi
# @URL: https://github.com/JuniYadi/zippyshare
# @Version: 201811261036
# @Date: 2018-11-26
# @Usage: ./zippyshare.sh url

if [ -z "${1}" ]
then
    echo "usage: ${0} url"
    echo "batch usage: ${0} url-list.txt"
    echo "url-list.txt is a file that contains one zippyshare.com url per line"
    exit
fi

function zippydownload()
{
    prefix="$( echo -n "${url}" | cut -c "11,12,31-38" | sed -e 's/[^a-zA-Z0-9]//g' )"
    cookiefile="/tmp/${prefix}-cookie.tmp"
    infofile="/tmp/${prefix}-info.tmp"
    fetchpath="/tmp/zippy-dl.txt"
    fetchdlmet="/tmp/dlmet.txt"

    # loop that makes sure the script actually finds a filename
    filename=""
    retry=0
    while [ -z "${filename}" -a ${retry} -lt 10 ]
    do
        let retry+=1
        rm -f "${cookiefile}" 2> /dev/null
        rm -f "${infofile}" 2> /dev/null
        curl -s -c "${cookiefile}" -o "${infofile}" -L "${url}"

        filenamecheck=$( cat "${infofile}" | grep '<span id="omg" class="2" style="display:none;"></span>' )

        if [ "$filenamecheck" ]; then
            filename="$( cat "${infofile}" | grep "/d/" | cut -d'/' -f6 | cut -d'"' -f1 | grep -o "[^ ]\+\(\+[^ ]\+\)*" )"
            echo "new" > "$fetchdlmet"
        else
            filename="$( cat "${infofile}" | grep "/d/" | cut -d'/' -f5 | cut -d'"' -f1 | grep -o "[^ ]\+\(\+[^ ]\+\)*" )"
            echo "old" > "$fetchdlmet"
        fi
    done

    if [ "${retry}" -ge 10 ]
    then
        echo "could not download file"
        exit 1
    fi

    # Get cookie
    if [ -f "${cookiefile}" ]
    then 
        jsessionid="$( cat "${cookiefile}" | grep "JSESSIONID" | cut -f7)"
    else
        echo "can't find cookie file for ${prefix}"
        exit 1
    fi

    if [ -f "${infofile}" ]
    then
        #Get url algorithm (new methode 26/11/2018)        
        dlfetch=$( grep 'getElementById..dlbutton...href' "${infofile}" | grep -oE '\([0-9].*\)' > "$fetchpath" )

        if [ $( cat "$fetchdlmet" ) == "new" ]; then
            refetcha=$(sed -i "s/a()/1/g;" "$fetchpath")
            refetchb=$(sed -i "s/b()/2/g;" "$fetchpath")
            refetchc=$(sed -i "s/c()/3/g;" "$fetchpath")
            refetchd=$(sed -i "s/ d / 4 /g;" "$fetchpath")
        fi


        dlbutton="$( cat "$fetchpath" )"
        

        if [ -n "${dlbutton}" ]
        then
           algorithm="${dlbutton}"
        else
           echo "could not get zippyshare url algorithm"
           exit 1
        fi

        
        a="$( echo $(( ${algorithm} )) )"
        # Get ref, server, id
        ref="$( cat "${infofile}" | grep 'property="og:url"' | cut -d'"' -f4 | grep -o "[^ ]\+\(\+[^ ]\+\)*" )"

        server="$( echo "${ref}" | cut -d'/' -f3 )"

        id="$( echo "${ref}" | cut -d'/' -f5 )"
    else
        echo "can't find info file for ${prefix}"
        exit 1
    fi

    # Build download url
    dl="https://${server}/d/${id}/${a}/${filename}"

    # Set browser agent
    agent="Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36"

    if [ -f "$filename" ]; then
        echo "[ERROR] File  Exist : $filename"
    else
        echo "[INFO] Download File : $filename"

        # Start download file
        curl -# -A "${agent}" -e "${ref}" -H "Cookie: JSESSIONID=${jsessionid}" -C - "${dl}" -o "${filename}"
    fi

    rm -f "${cookiefile}" 2> /dev/null
    rm -f "${infofile}" 2> /dev/null
}

if [ -f "${1}" ]
then
    for url in $( cat "${1}" | grep -i 'zippyshare.com' )
    do
        zippydownload "${url}"
    done
else
    url="${1}"
    zippydownload "${url}"
fi