#!/bin/bash
# @Description: zippyshare.com file download script
# @Author: Juni Yadi
# @URL: https://github.com/JuniYadi/zippyshare
# @Version: 201906112027
# @Date: 2019-06-11
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

        filename="$( grep "getElementById..dlbutton...href" "${infofile}" | cut -d"/" -f5 | sed "s/\";//g" )"
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

        dlbutton=$( grep 'getElementById..dlbutton...href' "${infofile}" | grep -oE '\([0-9].*\)' )

        if [ ! -n "${dlbutton}" ]
        then
            VALUEA=$( grep 'var a = ' "${infofile}" | tail -1 | cut -d" " -f8 | cut -d";" -f1 )
            VALUEB=$( grep 'var b = ' "${infofile}" | tail -1 | cut -d" " -f8 | cut -d";" -f1 )

            MATH=$(( ${VALUEA} / 3))

            READFILE=$( grep 'getElementById..dlbutton...href' "${infofile}" | grep -oE '\([a-zA-Z0-9].*\)' > "$fetchpath" )
            CHANGEA=$(sed -i "s/a/$MATH/g;" "$fetchpath")
            CHANGEA=$(sed -i "s/b/$VALUEB/g;" "$fetchpath")

            dlbutton=$( cat "$fetchpath" | tr -d '\n' | tr -d '\r')
        fi

        if [ -n "${dlbutton}" ]
        then
            algorithm="$( echo $(( ${dlbutton} )) )"
        else
           echo "could not get zippyshare url algorithm"
           exit 1
        fi


        
        # Get ref, server, id
        ref="$( cat "${infofile}" | grep 'property="og:url"' | cut -d'"' -f4 | grep -o "[^ ]\+\(\+[^ ]\+\)*" )"

        server="$( echo "${ref}" | cut -d'/' -f3 )"

        id="$( echo "${ref}" | cut -d'/' -f5 )"
    else
        echo "can't find info file for ${prefix}"
        exit 1
    fi

    # Build download url
    dl="https://${server}/d/${id}/${algorithm}/${filename}"

    # Set browser agent
    agent="Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36"

    if [ -f "$filename" ]; then
        echo "[ERROR] File  Exist : $filename - ${url}"
    else
        echo "[INFO] Download File : $filename - ${url}"

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