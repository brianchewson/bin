#!/bin/sh -e

#============================================FUNCTIONS==============================================
usage()
{
  err_echo "$0 is a tool to create an html page with google charts showing the growth of disk usage by version
-----------------------------------------------------------------------bch
USAGE: $0 -o [OPTIONAL]
  -o     # this is what -o does
"
  err_echo $*
  exit 1
}

err_echo()
{
  echo "$@" 1>&2
}

add_html_footer()
{
    echo "    var options = {
        hAxis: {
          title: 'build date'
        },
        vAxis: {
          title: 'bytes'
        },
        series: {
          1: {curveType: 'function'}
        }
      };

      var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
      chart.draw(data, options);
    }
</script>
</body>
</html>" >> ${OUTFILE}

}

add_html_header()
{
echo "<html><body>
<script type=\"text/javascript\" src=\"https://www.gstatic.com/charts/loader.js\"></script>
<div id=\"chart_div\"></div>
<script type=\"text/javascript\">
  google.charts.load('current', {packages: ['corechart', 'line']});
  google.charts.setOnLoadCallback(drawCurveTypes);
function drawCurveTypes() {
    var data = new google.visualization.DataTable();
    dateFormatter = new google.visualization.DateFormat({formatType: 'short'});
    data.addColumn('string', 'epoch');" >> ${OUTFILE}
}

clean_source_data()
{
    #Looks like some data was garbled in history...
    for GARBAGE in 8.1G lo6.2G t2.2G star13G; do
        sed -i "/\/${GARBAGE} /d" source_data.txt
    done
}

get_size()
{
    IN_SIZE=$1
    RET_VAL=""
    case "${IN_SIZE}" in
        *K)
            RET_VAL=$(bc <<< "${IN_SIZE%?}*1024")
        ;;
        *M)
            RET_VAL=$(bc <<< "${IN_SIZE%?}*1024*1024")
        ;;
        *G)
            RET_VAL=$(bc <<< "${IN_SIZE%?}*1024*1024*1024")
        ;;
        *T)
            RET_VAL=$(bc <<< "${IN_SIZE%?}*1024*1024*1024*1024")
        ;;
    esac
    echo ${RET_VAL}
}

verify_dependencies()
{	
  for REQUIRED_FILE in ${REQUIRED_FILES}; do
    if [ ! -f ${WORKSPACE}/${REQUIRED_FILE} ]; then
      usage "${0##*/} requires a missing file, ${REQUIRED_FILE}, to run,
Please add ${REQUIRED_FILE} to ${WORKSPACE} to continue"
    fi
  done
}

process_arguments()
{
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
      ;;
      -o|-O)
        if [ -z "$2" ]; then
          usage "Improper number of arguments supplied for OPTIONAL flag (-o)"
        fi
        DO_O=$2
        shift
      ;;
    esac
    shift
  done
  if [ -z "$DO_O" ]; then
    usage "NO DIR specified"
  fi
  if [ ! -d "$DO_O" ]; then
    usage "DIR $DO_O doesn't exist"
  fi

  REQUIRED_FILES=""
  if [ -n "${REQUIRED_FILES}" ]; then
    verify_dependencies 
  fi
}
#==========================================END FUNCTIONS============================================
if [ -z "${WORKSPACE}" ]; then
  WORKSPACE=$(pwd)
fi

EP_DIR=${WORKSPACE}/epochs
EPOCHS=${EP_DIR}/epochs.txt
OUTFILE=${WORKSPACE}/disk_growth-$(date +%s).html
SOURCE_DATA=${WORKSPACE}/source_data.txt
VERSIONS=${WORKSPACE}/versions.txt

#if [ $# -lt 1 ]; then
#  usage "No arguments specified"
#fi
#
#process_arguments "$@"

# get source data
##curl -s -o ${SOURCE_DATA} http://starci.lebanon.cd-adapco.com/job/dev_check_published_results/lastSuccessfulBuild/artifact/version_only_with_size.txt

# clean source data
##clean_source_data

# get versions from source data
##cut -d '/' -f 7 ${SOURCE_DATA} | cut -d ' ' -f 1 | sort -u > ${VERSIONS}

# get epochs from source data
##mkdir ${EP_DIR}
##cut -d ' ' -f 1 ${SOURCE_DATA} | sort -u  > ${EPOCHS}

# break source data into epoch data
##while read EPOCH; do 
##    grep ${EPOCH} ${SOURCE_DATA} > ${EP_DIR}/${EPOCH}
##done < ${EPOCHS}

# create html header
add_html_header

# create column data
while read VERSION; do 
    echo "    data.addColumn('number', '${VERSION}');" >> ${OUTFILE}
done < ${VERSIONS}

# create row data
echo "" >> ${OUTFILE}
echo "    data.addRows([" >> ${OUTFILE}
while read EPOCH; do 
    echo ${EPOCH}
    # do start of data row
    OUT_ROW="        [dateFormatter.formatValue(new Date(${EPOCH}000))"

    #do each version
    while read VERSION; do  
        if grep -q ${VERSION} ${EP_DIR}/${EPOCH}; then 
            SIZE=$(grep ${VERSION} ${EP_DIR}/${EPOCH})
            SIZE=$(get_size ${SIZE##* })
        else 
            SIZE=null
        fi
        OUT_ROW="${OUT_ROW},${SIZE}"
    done < ${VERSIONS}

    # do end of data row
    OUT_ROW="${OUT_ROW}],"
    echo "${OUT_ROW}" >> ${OUTFILE}
done < ${EPOCHS}
# get rid of the last row comma
sed -i '$ s/.$//' ${OUTFILE}
echo "    ]);" >> ${OUTFILE}

# create html footer
add_html_footer
