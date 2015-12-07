#sets: BLOBS(blob base dir), d(real script directory), realprog (real script name)
export TEMP=${TEMP:-/tmp}
BLOBS=${BLOBS:-/home/nlg-01/blobs}
[ -d $BLOBS ] || BLOBS=~/blobs
libg=$BLOBS/libgraehl/latest
mkdir -p $libg
export BLOBS

save1() {
    #pipe stderr to out, saving original out to file arg1, for cmd arg2...argN
    local out="$1"
    shift
    "$@" 2>&1 1>"$out"
}

quietly() {
    if [ "$verbose" -o "$showcmd" ] ; then
        echo +++ "$@"
    fi
    if [ "$verbose" ] ; then
        "$@"
    else
        local TEMP=${TEMP:-/tmp}
        local log=`mktemp $TEMP/quietly.log.XXXXXXX`
        local out=`mktemp $TEMP/quietly.out.XXXXXXX`
        if ! "$@" 2>$log >$out ; then
            local ret=$?
            tail $out $log
            echo $log $out
            return $ret
        else
            rm $out $log
        fi
    fi
}

verbose2() {
    if [ "$verbose" ] ; then
        echo2 "$@"
    fi
}
mapreduce_files() {
    local TEMP=${TEMP:-/tmp}
    local mapper=$1
    local reducer=${2:?usage: mapreduce mapper reducer [fileargs]}
    shift
    shift
    local temps=""
    echo2 "+++ mapreduce_files $mapper $reducer" "$@"
    while [ "$1" ] ; do
     local arg=$1
     shift
     [ -f $arg ] || continue
     local b=`basename --  $arg`
     local temp=`mktemp $TEMP/$b.XXXXXXX`
     temps="$temps $temp"
     verbose2 " +++ $mapper $arg > $temp"
     if ! $mapper $arg > $temp ; then
         local ret=$?
         error "Error during mapreduce_files: failed on '$mapper $arg'"
         [ "$savetmp" ] || rm $temps
         return $ret
     fi
    done
    verbose2 "+++ $reducer $temps"
    $reducer $temps
    local ret=$?
    [ "$savetmp" ] || rm $temps
    return $ret
}

cpdd() {
    if [ "$1" != "$2" ] ; then
        /bin/dd if="$1" of="$2" bs=1M
    fi
}
function filesz
{
    stat -L -c%s "$@"
}
function same_size
{
    [ `filesz "$1"` -eq `filesz "$2"` ]
}
cpdd_skip() {
    if [ -f "$2" ] && same_size "$@" ; then
        echo2 "skipping already copied $1 => $2"
    else
        echo2 "copying $1 => $2"
        cpdd "$1" "$2"
    fi
}
totmp() {
    for f in "$@"; do
        cpdd_skip $f $TMPDIR/`basename $f`
    done
}

clengths() {
    local p
    for f in "$@"; do
        lengths $f > $f.lengths
        p="$p $f.lengths"
        echo $f
    done
   paste $p
echo    paste $p

}

killdag() {
    pushd $1
    if [ -d 1btn0000 ] ; then
        id=`perl -ne 'if (/^\d+ \((\d+)\./) { print "$1\n";exit }' 1btn0000/1button.dag.dagman.log`
        if [ "$id" ] ; then
          echo $id
          condor_q
          condor_rm $id
        fi
    fi
    popd
}

debug() {
    PS4='+${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]}: ' bash -x $*
}
_log() {
    if [ "$DEBUG" = "true" ] ; then
        echo 1>&2 _ "$@"
    fi
}
lexicon_vocab() {
catz "$@" | perl -ne 'split;$c{$_[1]}++;$d{$_[2]}++;END{print scalar keys %c," ",scalar keys %d,"\n"}'
}

vocab() {
  catz "$@" | perl -ne '@l=split;$c{$_}++ for @l;END{print STDERR scalar keys %c,"\n";print $_," " for keys %c;print "\n"}'
}

quotevocab() {
 perl -ne '$t{$1}++ while /"([^" ]+)"/g;END{print "$_\n" for keys %t}' $*
}
invocab() {
    carmel --project-left $* | quotevocab
}
outvocab() {
    carmel --project-right $* | quotevocab
}


maybe_cp() {
    mkdir -p `dirname $2`
    echo cp $1 $2
    if [ ! -f $2 -o $1 -nt $2 ] ; then
    if [ "$backup" ] ; then
      bak=$2.maybecp~
      [ -f $2 ] && mv $2 $bak && echo2 backup at $bak
     fi
     cp $1 $2
     echo2 DONE
    else
     echo2 "NOT copying: $1 => $2 (latter is newer)"
     false
    fi
}

lengths() {
 #perl -ne '$l=(scalar split);print "$l\n"' "$@"
 catz "$@" | awk '{print NF}'
}

sum_lengths() {
    lengths "$@" | summarize_num.pl
}
tab() {
  echo -ne "\t$*"
}

print() {
  echo -ne "$@"
}

print2() {
  echo -ne "$@" 1>&2
}

println() {
  echo -e "$@"
}

header() {
    echo "### $*"
    echo "############"
}


banner() {
   header "$@" "[`basename $0`]"
}

pmem_mb() {
# assume w/o checking that line ends in "kB"
  head -n 1 /proc/meminfo | gawk '{ print int($2/1024) }'
}

pmem_avail() {
    local p=$((`pmem_mb` - 512))
    [ $p -le 256 ] && p=256
    echo $p
}

checkscript() {
    bash -u -n -x "$@"
}

dryrun() {
bash -vn "$@"
}

function seq2
{
 seq -f %02g "$@"
}

function seq3
{
 seq -f %03g "$@"
}

function seq4
{
 seq -f %04g "$@"
}

cygwin() {
 local OS=`/bin/uname`
 [ "${OS#CYGWIN}" != "$OS" ]
}

ulimitsafe() {
local want=${1:-131072}
local type=${2:-s}
local OS=`/bin/uname`
if [ ${OS#CYGWIN} != "$OS" -a "$type" = "s" ] ; then
# error "cygwin doesn't allow stack ulimit change"
 return
fi
# fix stack limits
local soft=`ulimit -S$type`
if [ ! "$soft" = 'unlimited' ]; then
    local hard=`ulimit -H$type`
    if [ "$hard" = 'unlimited' ]; then
        ulimit -S$type $want
    elif [ $hard -gt $want ]; then
        ulimit -S$type $want
    else
        ulimit -S$type $hard
    fi
fi
}

balanced() {
  perl -n -e '$nopen=$nclose=0;++$nopen while (/\(/g);  ++$nclose while (/\)/g); warn("$nopen open and $nclose close parens") unless $nopen == $nclose;$no+=$nopen;$nc+=$nclose; END { print "$no opened, $nc closed parens\n"}' "$@"
}

#USAGE: assert "condition" $LINENO
assert() {
  E_PARAM_ERR=98
  E_ASSERT_FAILED=99
  [ "$2" ] || return $E_PARAM_ERR #must call with $LINENO
  local lineno=$2
  if ! eval [ $1 ] ; then
    echo2 "Assertion failed:  \"$1\" with exit=$?"
    echo2 "File \"$0\", line $lineno"
    exit $E_ASSERT_FAILED
  fi
}

# while getopts ":m:h" options; do
#   case $options in
#     m ) method=$OPTARG;;
#     * ) usage;;
#   esac
# done

 # after getopt, OPTIND is set to the index of the first non-option argument - put remaining positional parameters into "$@" by this:
# shift $(($OPTIND - 1))

parent_dir() {
 local p=${1:-`pwd`}
 local dir=`dirname -- $p`
 basename --  $dir
}

finish_getopt() {
 return 0
}

usage() {
 echo2 USAGE:
 echo2 -e $usage
 local exitcode=$1
 shift
 if [ "$exitcode" ] ; then
  echo2 -e "$@"
  exit $exitcode
 fi
 exit 13
}

function showargs
{
    perl -e 'print "$_\n" while $_=shift' "$@"
}

is_interactive() {
 case "$-" in
 *i*)	 return 0 ;;
 *)	 return 1 ;;
 esac
}

on_err() {
 local exitcode=$?
 echo2
 errorq \(exit code $exitcode\)
 [ "${noexit+set}" = set ] || is_interactive || { echo2 ABORTING. ; exit 1; }
 return 1
}

trapexit() {
  trap "$*" EXIT INT TERM
}

traperr() {
 if [ "$BASH_VERSINFO" -gt 2 ] ; then
  set -o pipefail
  trap 'on_err' ERR
 fi
}

untraperr() {
 if [ "$BASH_VERSINFO" -gt 2 ] ; then
  trap ERR
 fi
}


echo2() {
 echo "$@" 1>&2
}

debug() {
 [ "$DEBUG" ] && echo2 DEBUG: "$@"
 return 0
}

debugv() {
 [ "$DEBUG" ] && echo2 DEBUG: "$*"=`eval echo "$@"`
 return 0
}


warn() {
 echo2 WARNING: "$@"
}

errorq() {
 echo2 ERROR: "$@"
}

die() {
 errorq  "File \"$0\", line $lineno: " "$@"
 exit 19
}

error() {
 errorq "$@"
 return 2
}

usageline() {
 echo2 USAGE: "$@"
 return 2
}

nanotime() {
  date +%s.%N
}

tmpnam() {
  local TEMP=${TEMP:-/tmp}
  local nano=`nanotime`
  local suffix="$$$nano"
  echo $TEMP/$1$suffix
}

checksum() {
    local file=$1
    md5sum $file | cut -d' ' -f1
}

# $noexit (if set, return error code, else exit)
maybe_exit() {
    [ "$*" ] && errorq "$@"
    [ "${noexit+set}" = set ] || exit 1
    return 1
}

cpz_safe() {
    alltodir cpz_safe_one "$@"
}

cpz_safe_one() {
 if [ ${simulate_fail:-0} = 1 ] ; then
   simulate_fail=
   return 3
 fi
 if [ ! "$1" -a "$2" ] ; then
  usageline 'copyz in out[.gz]'
  return 2
 fi
 local infile=$1
 local outfile=$2
 if [ -d $outfile ] ; then
   outfile=$outfile/`basename --  $infile`
 fi
 local same=1
 local outgz
 local ingz
 local outbz2
 local inbz2
 [ "${outfile%.gz}" = "$outfile" ] || outgz=1
 [ "${infile%.gz}" = "$infile" ] || ingz=1
 [ "${outfile%.bz2}" = "$outfile" ] || outbz2=1
 [ "${infile%.bz2}" = "$infile" ] || inbz2=1
 [ "$outgz" = "$ingz" ] || same=0
 [ "$outbz2" = "$inbz2" ] || same=0
 [ "$outgz" -o "$outbz2" ] || same=1
 local checksumfile=`dirname -- $outfile`/.`basename --  $outfile`.md5
 if [ $same = 1 ] ; then
      cp $infile $outfile && [  `checksum $infile | tee $checksumfile` = `checksum $outfile` ]
 else
   if [ "$outbz2" ] ; then
      [ "$ingz" ] && warn not decompressing $infile ... compressing to $outfile
      bzip2 -c $infile > $outfile && [ `bunzip2 -c $outfile | checksum` = `checksum $infile | tee $checksumfile` ]
   else
     [ "$inbz2" ] && warn not decompressing $infile ... compressing to $outfile
     gzip -c  $infile > $outfile && [ `gunzip -f -c $outfile | checksum` = `checksum $infile|  tee $checksumfile` ]
    fi
  fi
}

cpz() {
    alltodir cpz_one "$@"
}

cpz_one() {
  local oldnoexit=$noexit
  noexit=1
  cpz_for_sure_one "$@"
  local ret=$?
  noexit=$oldnoexit
  return $ret
}

cpz_for_sure() {
    alltodir cpz_for_sure_one "$@"
}

# $ncpzretry (default 5)
cpz_for_sure_one() {
  local max=${ncpzretry:-5}
    local TRYCPZ
  for TRYCPZ in `seq 1 $max`; do
    cpz_safe_one "$@" && return 0
  done
}

#
# affected by vars:
# $execstatus (if set, create outfile.FAILED on failure)
# $execstatusok (if set, create outfile.OK on success)
# $TEMP (default /tmp)
# $logerr (2>&1, save stderr to same file)
# $keepbad (delete output on bad exit code unless set)
# $nretry (default 5)
# $emptyok (assumes empty output is an error unless set)
# $simple (simple=1: no shell interpolation, pipelines, etc. are needed - simplifies shell quotation issues if set)
# $teeout : file contents also to stdout if set
# $removeold: if 1, remove old file first
# $mkdir: if 1, mkdir -f `dirname -- outfile`
exec_safe() {
    if [ ! "$1" -a "$2" ] ; then
     usageline 'noexit=1 execstatus=1 TEMP=/tmp logerr=1 keepbad=1 exec_safe output_file{.gz} command -and -arguments'
     return 2
    fi
    local outfile=$1
    shift
    local tmpfile=`tmpnam exec_safe`
    local max=${nretry:-5}
    local outdir=`dirname -- $outfile`
    if [ ! -d "$outdir" ] ; then
     if [ ${mkdir:-0} = 1 ] ; then
        echo2 "creating directory $outdir"
        mkdir -p $outdir || return 4
     else
        error "can't create outfile $outfile since the directory $outdir doesn't exist"
        return 5
     fi
    fi
    [ -L "$outfile" ] && echo2 "removing output $outfile because it is a symlink" && rm -f $outfile
    if [ -d "$outfile" ] ; then
        error "outfile $outfile is a directory"
        return 3
    fi
    [ ${removeold:-0} = 1 ] && rm -f $outfile
    rm -f $outfile.OK $outfile.FAILED
    local i
    touch $outfile.PENDING
  if have_file $outfile.PENDING ; then
    for i in `seq 1 $max`; do
     if [ ${logerr:-0} = 1 ] ; then
      if [ ${simple:-0} = 1 ] ; then
       if [ ${teeout:-0} = 1 ] ; then
        "$@" 2>&1 | tee $tmpfile || continue
       else
        "$@" > $tmpfile 2>&1 || continue
       fi
      else
       if [ ${teeout:-0} = 1 ] ; then
        eval "$@" 2>&1 | tee $tmpfile || continue
       else
        eval "$@" > $tmpfile 2>&1 || continue
       fi
      fi
     else
      if [ ${simple:-0} = 1 ] ; then
       if [ ${teeout:-0} = 1 ] ; then
        "$@"  | tee $tmpfile || continue
       else
        "$@" > $tmpfile  || continue
       fi
      else
       if [ ${teeout:-0} = 1 ] ; then
        eval "$@"  | tee $tmpfile || continue
       else
        eval "$@" > $tmpfile  || continue
       fi
      fi
     fi
     [ -f $tmpfile ] || continue
     [ -s $tmpfile ] || [ ${emptyok:-0} = 1 ] || continue
     cpz_for_sure $tmpfile $outfile || continue
     #echo2 OK
     rm -f $tmpfile
     [ ${execstatusok:-0} = 1 ] && touch $outfile.OK
     rm -f $outfile.PENDING
     return 0
    done
   fi
    [ ${execstatus:-0} = 1 ] && touch $outfile.FAILED
    rm $outfile.PENDING
    rm -f $outfile
    [ ${keepbad:-0} = 1 ] && cpz_safe $tmpfile $outfile
    rm -f $tmpfile
    error gave up after $max tries: exec_safe "$@"
}

is_abspath() {
     [ "${1:0:1}" = / ]
}

#usage: realprog gets real script location, d gets real script dir
getrealprog() {
 realprog=$0
 d=`dirname -- $realprog`
 if [ -L $realprog ] ; then
  if [ -x "`which_quiet readlink`" ] ; then
   while [ -L $realprog ] ; do
      realprog=`readlink $realprog`
   done
     if [ ${realprog:0:1} = / ] ; then #absolute path
      d=`dirname -- $realprog`
     else
      d=$d/`dirname -- $realprog`
     fi
  fi
 fi
}

# if you supply dirname --/basename -- , that's tried first, then just basename --  from path
# default: from PATH; then: from same directory as script; finally: the second argument if supplied
which_default() {
#set -x
 local prog=$1
 if [ -z "$prog" ] ; then
  error "which_default progname defaultfilename - default: from PATH; then: from same directory as script; finally: the second argument if supplied"
  return 1
 fi
 local default=$2
 local ret=`which_quiet $prog 2>/dev/null`
 if [ -x "$ret" ] ; then
  echo $ret
 else
  prog=`basename --  $prog`
  ret=`which_quiet $prog 2>/dev/null`
  if [ -x "$ret" ] ; then
   echo $ret
  else
   getrealprog
   local ret=$d/$prog
   if [ -x "$ret" ] ; then
    echo $ret
   else
    if [ -x "$default" ] ; then
     echo $default
    else
     error No executable $prog found in PATH, $d, or at default $default
    fi
   fi
  fi
 fi
}

#usage: set abspath, call, read abspath
makeabspath() {
 if [ -x "`which readlink`" ] ; then
     abspath=`readlink -nfs $abspath`
#  while [ -L $abspath ] ; do
#     abspath=`readlink $abspath`
#  done
 else
 if [ ${abspath:0:1} != / ] ; then #absolute path
      abspath=`pwd`/$abspath
 fi
 fi
}

abspath() {
 abspath=$1
 makeabspath
 echo $abspath
}

catz() {
  if [ -z "$1" ] ; then
   gunzip -f -c
  else
   while [ "$1" ] ; do
    if [ ! -f "$1" ] ; then
         echo "input file $1 not found" 1>&2
         exit -1
    fi
    if [ "${1%.gz}" != "$1" -o "${1%.tgz}" != "$1" ] ; then
        gunzip -f -c "$1"
    else
        if [ "${1%.bz2}" != "$1" ] ; then
            bunzip2 -c "$1"
        else
            cat "$1"
        fi
    fi
    shift
   done
  fi
 }

catz_to() {
  if [ -z "$1" ] ; then
   cat
  else
    if [ "${1%.gz}" != "$1" -o "${1%.tgz}" != "$1" ] ; then
        gzip -c > "$1"
    else
        if [ "${1%.bz2}" != "$1" ] ; then
            bzip2 -c > "$1"
        else
            cat > "$1"
        fi
    fi
  fi
 }

function dos2unix()
{
 perl -i~ -pe 'y/\r//d' "$@"
}

function isdos()
{
 perl -e 'while(<>) { if (y/\r/\r/) { print $ARGV,"\n"; last; } }' "$@"
}

headz() {
 map_files headz_one_default "$@"
}

headz_one_default() {
 headz_one ${head:-8} "$@"
}

headz_one() {
 local n=$1
 shift
 if [ -z "$1" ] ; then
  catz $n | head
 else
  catz "$@" | head -n $n
 fi
}

first() {
    echo $1
}

tailz() {
 local n=$1
 shift
 if [ -z "$1" ] ; then
  catz $n | tail
 else
  catz "$@" | tail -n $n
 fi
}

wcz() {
 nlinesz "$@"
}

nlines() {
 catz "$@" | wc -l
}

haslines() {
 local n=$1
 shift
 [ `nlines "$@"` -ge $n ]
}

# get nth line from stdin
function getline_stdin
{
 local line=$1
 local text
# head -n $line | tail -n 1
 local n=0
 while [ $n -lt $line ] ; do
  if ! read -r text ; then
   return 1
  fi
  n=$((1+$n))
  if [ $n = $line ] ; then
    echo -E "$text"
  fi
 done
}

function getline_stdin
{
    perl -e 'BEGIN{$l=shift};while(<>){ if (--$l==0) { print; exit; } } exit 1' "$@"
}

# get line number n
get() {
 local line=$1
 shift
  catz "$@" | getline_stdin $line
# if [ ! "$*" ] ; then
 # getline_stdin $line
# else
#  if haslines $line $* ; then
#   catz $* | getline_stdin $line
#  else
#   return 1
#  fi
# fi
}

# get n lines, starting from optional 2nd arg
getn() {
 local n=$1
 shift
 if [ "$1" ] ; then
  local h=$(($1+$n - 1))
  shift
 fi
 headz -$h "$@" | tail -$n
}

#get n bytes, starting from optional 2nd arg
getnbytes() {
 local n=$1
 shift
 local offset=$1
 shift
 catz "$@" | dd bs=1 skip=$offset count=$n
}

getline() {
get "$@"
}

# sort stdin lines with key following first argument.  e.g. sortbynum id= would sort lines by id=N
sortby() {
 perl -e '@l=<>;@w=map {$$_[0]} sort { $$a[1] cmp $$b[1] } map {/\Q'"$1"'\E(\S+)/;[$_,$1]} @l; print @w'
}
sortbynum() {
 perl -e '@l=<>;@w=map {$$_[0]} sort { $$a[1] <=> $$b[1] } map {/\Q'"$1"'\E(\S+)/;[$_,$1]} @l; print @w'
}
getparams() {
    catz "$@" | perl -e 'while(<>) { last if /^COMMAND LINE/; } <>; while(<>) { last if /^>>>* PARAMETERS/; print $_; }'
}
getcmdline() {
    catz "$@" | perl -e 'while(<>) { last if s/.*COMMAND LINE:\s*//; } $_=<> unless /\S+/; print;'
}
getparam() {
 local name=$1
 shift
 getparams "$@" | perl -n -e 'print $1,"\n" if /^\w+ \Q'"$name"'\E=(.*)/'
}
timestamp() {
 date +%Y.%m.%d_%H.%M
}

getlast() {
  ls -t "$@" | head -n 1
}

getlastgrep() {
  local pattern=shift
  ls -t  "$@" | grep "$pattern" | head -n 1
}

getlastegrep() {
  local pattern=shift
  ls -t  "$@" | egrep "$pattern" | head -n 1
}

getlastfgrep() {
  local pattern=shift
  ls -t  "$@" | fgrep "$pattern" | head -n 1
}

getlaststar() {
local f
for f in "$@"; do
  ls -t "$f"* | head -n 1
done
}


safefilename() {
   echo "$@" | perl -pe 's/\W+/./g'
}

sortdiff() {
  [ -f $1 ] || error file 1: $1 not found
  [ -f $2 ] || error file 2: $2 not found
f1=$1
f2=$2
shift
shift
local tmp1=`safefilename $f1`
local tmp1=`tmpnam $tmp1`
local tmp2=`safefilename $f2`
local tmp2=`tmpnam $tmp2`
  catz $f1 | sort "$@" > $tmp1
  catz $f2 | sort "$@" > $tmp2
  diff -u -b $tmp1 $tmp2
  rm $tmp1
  rm $tmp2
}

bwhich() {
        which_quiet
        local syswhich=`/usr/bin/which "$@"`
        [ -f $syswhich ] && ls -l $f 1>&2
}

which_quiet() {
    builtin type "$@" | perl -n -e 'if (m#(?: is (/.*)|aliased to \`(.*)\'\'')$#) { print "$1$2\n";exit 0; }'
#cut -d' ' -f3-
}

where() {
	builtin type -a "$@"
}

# echocsv 1 2 3 => 1, 2, 3
echocsv() {
local a=$1
shift
echo -n $a
while [ "$1" ] ; do
 a=$1
 shift
 echo -n ", $a"
done
echo
}


is_text_file() {
local t=`tmpnam`
file "$@" > $t
grep -q text $t
local ret=$?
rm $t
return $ret
}

##### ENVIRONMENT VARIABLES as SCRIPT OPTIONS:
showvars_required() {
 echo2 $0 RUNNING WITH REQUIRED VARIABLES:
    local k
 for k in "$@"; do
  eval local v=\$$k
  echo2 $k=$v
  if [ -z "$v" ] ; then
    errorq "required (environment or shell) variable $k not defined!"
    return 1
  fi
 done
 echo2
}

showvars() {
 echo2 $0 RUNNING WITH VARIABLES:
    local k
 for k in "$@"; do
  eval local v=\$$k
  echo2 $k=$v
 done
 echo2
}

showvarsq() {
 local k
 for k in "$@"; do
  eval local v=\$$k
  echo -ne "$k=$v " 1>&2
 done
 echo2
}

showvars_optional() {
 echo2 RUNNING WITH OPTIONAL VARIABLES:
    local k
 for k in "$@"; do
  if isset $k ; then
   eval local v=\$$k
   echo2 $k=$v
  else
   echo2 UNSET: $k
   fi
 done
 echo2
}
showvars_files() {
 echo2 $0 RUNNING WITH FILES FROM VARIABLES:
    local k
 for k in "$@"; do
  eval local v=\$$k
  local r=`realpath $v`
  echo2 "$k=$v [$r]"
  require_files $v
 done
 echo2
}

showvars_filedirs() {
 echo2 $0 RUNNING WITH FILES FROM VARIABLES:
    local k
 for k in "$@"; do
  eval local v=\$$k
  local r=`realpath $v`
  echo2 "$k=$v [$r]"
  [ -e "$v" ] || return 1
 done
 echo2
}

showvars_dirs() {
 echo2 $0 RUNNING WITH DIRECTORIES FROM VARIABLES:
    local k
 for k in "$@"; do
  eval local v=\$$k
  local r=`realpath $v`
  echo2 "$k=$v [$r]"
  [ -d "$v" ] || return 1
 done
 echo2
}

greplines() {
 grep -n "$@" | cut -f1 -d:
}

getfield() {
 perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl';&argvz;"'$f=shift;while(<>) {$v=&getfield($f,$_);print "$v\n" if defined $v;}' -- "$@"
}

getfield_blanks() {
 perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl';&argvz;"'$f=shift;while(<>) {$v=&getfield($f,$_);print "$v\n";}' -- "$@"
}

getfields_blanks() {
 perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl';&argvz;"'$IFS="\t";while(defined($l=<STDIN>)) {@v=map {&getfield($_,$l)} @ARGV;print "@v\n"}' -- "$@"
}

getfirstfield_blanks() {
 perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl';&argvz;"'while(defined($l=<STDIN>)) {for (@ARGV) { $f=&getfield($_,$l); last if defined $f; } print "$f\n"}' -- "$@"
}

getfields_blanks_header() {
 perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl';&argvz;"'$IFS="\t";print "@ARGV\n";while(defined($l=<STDIN>)) {@v=map {&getfield($_,$l)} @ARGV;print "@v\n"}' -- "$@"
}

perfs() {
 catz "$@" | grep 'wall seconds'
}

grep_nullchar() {
#    xxd "$@" | (grep -m 1 -e 0x00)
 catz "$@" | perl -w -e 'use strict; while (defined ($_=getc)) { die "NUL READ\n" if $_ eq "\x0"; }'
}

grep_funnychars() {
# grep -m 1 -e '[^ -~]' "$@"
 LC_CTYPE= grep -m 1 '[[:cntrl:]]' "$@"
}

# why do we capture output?  because in bash pre-v3, pipeline exit codes are lost.
validate_nonull() {
    local n=`catz "$@" | grep_nullchar 2>&1`
    local files="$*"
    [ "$files" ] || files="STDIN"
    if [ -z "$n" ] ; then
      return 0
    fi
    warn "NUL (0, aka ^@) CHARACTER DETECTED in $files"
    return 1
}

validate_english() {
    local c=`catz $* | perl -pe chomp | grep_funnychars -c`
    local files="$*"
    [ "$files" ] || files="STDIN"
    if [ "$c" = "1" ] ; then
       warn "FUNNY (non-ASCII-printable) CHARACTERS DETECTED in $files"
       return 1
    fi
    return 0
}

expand_template() {
      perl -e '$t=shift;$i=shift;$mustexist=shift;$nocheck=!$mustexist;$t=~s/\{\}/$i/g;print "$t\n" if ($nocheck  or -f $t)' "$@"
}

#usage: $maxi sets default upper bound
maxi=99
mustexist=1
fileseq() {
#mustexist
    local template=$1
    shift
    local a=${1:-0}
    shift
    local b=${1:-$maxi}
    shift
    local i
    local s=`seq $a $b`
    [ "$nofill" ] || s=`seq -f '%02g' $a $b`
    for i in $s; do
      expand_template $template $i $mustexist
    done
}

ifiles() {
    mustexist=1 fileseq "$@"
}

ofiles() {
    mustexist=0 fileseq "$@"
}

# starts with an initial file, and increments the number part of the filename as long as more files are found, e.g. line1, line2, line3 ... lineN (gaps will end the sequence)
files_from() {
# perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl';"'while(defined ($f=shift)) { while(-f $f) { print "$f\n";$f=inc_numpart($f); } }' "$@"
 perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl'"';@files=files_from(@ARGV);print "$_\n" for (@files);' -- "$@"
}

filename_from() {
# perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl';"'while(defined ($f=shift)) { while(-f $f) { print "$f\n";$f=inc_numpart($f); } }' "$@"
 perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl'"';$"=" ";print filename_from("@ARGV"),"\n"' -- "$@"
}

chmod_notlinks() {
    local mode=$1
    shift
    local dir=${1:-.}
    find $dir \( -type f -o -type d \) -exec chmod -f $mode {} \;
}


sidebyside() {
 local files=''
 local desc='#'
 local f
 for f in "$@"; do
    local t=`mktemp /tmp/sidebyside.XXXXXXXXX`
    files="$files $t"
    desc="$desc $f"
    nl -ba $f > $t
 done
 echo $desc
 paste -d'\n' $files /dev/null
# $cmd
 rm -f $files
}

# optional 2nd arg: 1st file must exist *and* be newer than 2nd.  optional (env) var require_nonempty
have_file() {
    [ "$1" -a -f "$1" -a \( -z "$2" -o "$1" -nt "$2" \)  -a \( -z "$require_nonempty" -o -s "$1" \) ]
}

have_dir() {
    [ "$1" -a -d "$1" ]
}

have_data() {
    [ "$1" -a -s "$1" ]
}

require_files() {
 local f
 [ "$*" ] || error "require_files called with empty args list"
 for f in "$@"; do
    have_file "$f" || error "missing required file: $f" || return 1
 done
 return 0
}

have_files() {
 local f
 [ "$*" ] || error "have_files called with empty args list"
 for f in "$@"; do
    have_file "$f" || return 1
 done
 return 0
}

function show_outputs
{
    [ "$*" ] || error "show_outputs called with empty args list" || return 1
    show_tailn=${show_tailn:-4}
    [ 0$show_tailn -gt 0 ] || return 0
    [ $# = 1 ] && echo '==>' $1 '<=='
    tail -n $show_tailn "$@"
    [ $# = 1 ] && echo
    wc -l "$@"
}


skip_status() {
#  [ "$quiet_skip" ] || echo2 "$@"
#  return 0
 if ! ["$quite_skip" ] ; then
  echo2 "skip_files: start_at=$start_at stop_at=$stop_at r=$*"
 fi
}

not_skipping() {
    working_files="$*"
}

function show_stale_files
{
   if [ "$stale_files" ] ; then
    echo
    header "STALE (skip_files skipped) output files:"
    show_outputs $stale_files
   fi
}

function show_new_files
{
  if [ "$new_files" ] ; then
    echo
    header "NEW (skip_files regenerated) output files:"
    show_outputs $new_files
  fi
}

function working_elapsed
{
    echo $((`date +%s`-$working_start)) s elapsed
}

function skip_done
{
    [ "$working_files" ] && echo2 `working_elapsed` producing $working_files && require_files $working_files && new_files="$new_files $working_files"
    true
}

function new_file
{
 require_files "$@"
 new_files="$new_files $*"
}

function skip_done_bg
{
    [ "$working_files" ] && echo2 backgrounded producing $working_files && new_files="$new_files $working_files"
    true
}

# usage: newer_than=file skip_files 1 out1 ... || something > out1; skip_done; ... show_new_files
# first arg: $start_at must be greater than $1 .  remaining args: files that should exist or else regenerate them all.  returns true (0) if you can skip, false (1) if you can't.
# if first arg is >= stop_at, then don't run (return true) no matter if outputs exist or not
skip_files() {
#    echo2 skip_files "$@"
    working_files=
    working_start=`date +%s`
    local r=$1
    shift
    if ! [ "$*" ]  ; then
     warn "skip_files has empty list of output files as args.  rerunning command always."
     false
    fi
#    echo2 "require $r < $start_at - files: $*"
    if [ -n "$stop_at" -a $r -ge 0$stop_at ] ; then
      stale_files="$stale_files $*"
      skip_status "$r skipping - stop_at=$stop_at is <= $r" && return 0
    fi
    if [ 0$start_at -gt $r ] ; then
# might skip if files are already there:
        local f
        for f in "$@"; do
          if ! have_file $f $newer_than ; then
           skip_status "$r rerunning, for missing output $f"
           not_skipping "$@"
           return 1
          fi
        done
        stale_files="$stale_files $*"
        skip_status "$r skipping - had all files $*" && return 0
    fi
    not_skipping "$@"
    skip_status "$r rerunning to produce $*" && return 1
}

require_dirs() {
 local f
 [ "$*" ] || error "require_dirs called with empty args list"
 for f in "$@"; do
    have_dir $f  || error "missing required dir: $f" || return 1
 done
}

require_dir() {
 require_dirs "$@"
}

require_file() {
 require_files "$@"
}

require_data() {
 [ "$1" ] || error "require_data on empty filename"
 require_file $1
 [ -s "$1" ] || error "required file: $f is EMPTY!"
 # FIXME: check for empty .gz and .bz2?
}

trim_ws() {
    perl -pe 's/^\s+//;s/\s+$//;' "$@"
}

get_fields() {
   perl -ae '$,=" ";while(<STDIN>) {@F=split; print (map {$F[$_-1]} @ARGV);print "\n"}' "$@"
}

alias showargv="perl -e 'print \"======\\n\$_\\n\" while(defined(\$_=shift));'"


#fake qsubrun-depend.sh - only run 1st arg
eval1st() {
  eval $1
}

wildcardfound() {
    [ "$1" ] && [ "$1" = $1 ]
}

sum() {
     perl -ne '$s+=$_;END{print "$s\n"}' "$@"
}

#for smoothing freq of freq lines: (freq #items-with-freq)
sumff() {
 perl -ane '$s+=$F[0]*$F[1];$r+=$F[1];END{print "$s $r\n"}' "$@"
}

realpath() {
#    perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl';"'while($_=shift) {$_=abspath_from(".",$_,1) if -e $_; s|^/auto/|/home/|; print $_,"\n"}' -- "$@"
    readlink -fs "$@"
}

whichreal() {
    local w=`which "$@"`
    if [ -x "$w" ] ; then
       realpath $w
    else
      echo $w
    fi
}

skipfirst() {
   catz | (read;cat)
}

alltodir() {
local allNARGS=$#;
local allLAST=$(($allNARGS-1))
local all_args_arr
declare -a all_args_arr
all_args_arr=($*);
local allcmd=${all_args_arr[0]}
local II=1
local DEST=${all_args_arr[$allLAST]}
if [ $allLAST -lt 3 -o -d $DEST ] ; then
 while [ $II -lt $allLAST ]; do
   echo2 "+++++++++ $allcmd ${all_args_arr[$II]} $DEST/"
   if ! $allcmd ${all_args_arr[$II]} $DEST/ ; then
    error "Error on item $II in 'alltodir $allcmd $*' - failed on '$allcmd ${all_args_arr[$II]} $DEST/'"
    return $?
   fi
   II=$(($II+1))
 done
else
 error "last argument is not a directory - usage: alltodir cmd a b c dir/ => cmd a dir/;cmd b dir/;cmd c dir/"
fi
}

forall() {
    # simpler than map, we don't exit on error
    local cmd=$1
    shift
    local f
    for f in "$@"; do
        $cmd "$f"
    done
}

map() {
 local cmd=$1
 shift
 while [ "$1" ] ; do
  [ "$quiet" ] || echo2 "+ $cmd $1"
   if ! $cmd $1 ; then
    error "Error during map: failed on '$cmd $1'"
    return $?
   fi
   shift
   echo2
 done
}

pipemap() {
 local cmd=$1
 shift
 while [ "$1" ] ; do
  echo2 "+ catz $1 | $cmd"
  eval "catz $1 | $cmd"
   shift
   echo2
 done
}

map_files() {
 local cmd=$1
 shift
 while [ "$1" ] ; do
  local arg=$1
  shift
  [ -f $arg ] || continue
  echo2 "++++++++++ $cmd $arg"
   if ! $cmd $arg ; then
    error "Error during map: failed on '$cmd $arg'"
    return $?
   fi
   echo2
 done
}


stripunk() {
 perl -i -pe 's/\(\S+\s+\@UNKNOWN\@\)//g;s/\@UNKNOWN\@//g;' "$@"
}

basecd() {
 basename --  `pwd`
}

topnode() {
    local node=$1
    shift
    local n=${1:-30}
    ssh $node "top b n 1 | grep -v root | head -n $n"
}

lnreal() {
# echo2 $#
    local forceln
    local multi=2
    if [ "$1" = -f ] ; then
      forceln=-f
      multi=3
    fi
# echo2 $#
    if [ $# = $multi ] ; then
     lnreal_one "$@"
    else
     alltodir lnreal_one "$@"
    fi
}

lnreal_one() {
    local force
    if [ "$1" = -f ] ; then
      force=true
      shift
    fi
    local dest=$2
    [ -d $dest -a ! -L $dest ] && dest=$dest/`basename --  $1`
    [ "$force" ] && [ -f $dest -o -L $dest ] && rm -f $dest
    ln -s `realpath $1` $dest
}

gaps() {
perl -ne '$|=1;print if ( !( $_ || /^0[.]?0?$/) || $last && abs($last-$_)!=1);$last=$_;' "$@"
}

non_finalize() {
perl -pe 's/(finalize\s*\[\d+,\d+\]\.\s*done.\s*)*//' "$@"
}

non_nbest() {
 catz "$@" |  non_finalize | grep -v "^NBEST "
}

preview() {
 tailn=${tailn:-6}
 head -v -n $tailn "$@"
}

preview2() {
 preview "$@" 1>&2
}

diff_filter() {
showvars_required filter || return 1
local b1=`basename --  $1`
local b2=`basename --  $2`
local t1=`mktemp $TEMP/$b1.XXXXXXX`
local t2=`mktemp $TEMP/$b2.XXXXXXX`
 catz $1 | $filter > $t1
 catz $2 | $filter > $t2
echo2 "DIFF: - is only in $1, + is only in $2"
diff -u $t1 $t2
[ "$ediff" ] && ediff $t1 $t2
rm $t1 $t2
}

diffhead() {
local b1=`basename --  $1`
local b2=`basename --  $2`
local t1=`mktemp $TEMP/$b1.XXXXXXX`
local t2=`mktemp $TEMP/$b2.XXXXXXX`
local n=${3:-100}
if [ "$3" ] ; then
 catz $1 | head -n $3 > $t1
 catz $2 | head -n $3 > $t2
else
 catz $1  > $t1
 catz $2  > $t2
fi
echo2 "DIFF: - is only in $1, + is only in $2"
diff -u -b $t1 $t2
rm $t1 $t2
}

diffline() {
local n=$1
shift
[ "$n" -gt 0 ] || return 1
local b1=`basename --  $1`
local b2=`basename --  $2`
local t1=`mktemp $TEMP/$b1.XXXXXXX`
local t2=`mktemp $TEMP/$b2.XXXXXXX`
getline $n $1 > $t1
getline $n $2 > $t2
#echo2 "DIFF: - is only in $1, + is only in $2"
if ! diff -q $t1 $t2 >/dev/null ; then
 echo2 -e "\t$n"
 if [ "$ediff" ] ; then
  echo "DIFF: - was from $1, + was added to $2"
  ediff $t1 $t2
 else
  cat $t1 $t2
 fi
fi
rm $t1 $t2
}

difflines() {
 require_files $1 $2
 local n1=`nlines $1`
 local n2=`nlines $2`
 echo2 different lines from `basename --  $1` to `basename --  $2`:
 for n in `seq 1 $n1`; do
  diffline $n $1 $2
 done
}

diffz() {
diffhead "$@"
}

showlocals() {
local t1=`mktemp $TEMP/set.XXXXXXX`
local t2=`mktemp $TEMP/printenv.XXXXXXX`
set | sort > $t1
printenv | sort > $t2
 diff $t1 $t2 | grep "<" | awk '{ print $2 }' | grep -v '^[{}]'
}

isset() {
  eval local v=\${$1+set}
  [ "$v" = set ]
}

isnull() {
  eval local v=\${$1:-}
 [ -z "$v" ]
}

notnull() {
  eval local v=\${$1:-}
 [ "$v" ]
}

nwords() {
  catz "$@" | perl -ne 'next if /^$/;$n++;$n++ while / /g;END{print "$n\n"}'
}

nlinesz() {
    pipemap 'nlines' "$@"
}

countblanks() {
 catz "$@" | grep -c '^$'
}

skipn_pipe() {
for i in `seq 1 $1`; do
 read
done
cat
}

skipn() {
 local a=$1
 shift
 catz "$@" | skipn_pipe $a
}

wordsperline() {
 catz "$@" | perl -ane '$n=(scalar @F);$s+=$n;++$N;print "$n\n";END{print STDERR "total words $s, lines $N, avg ",$s/$N,"\n"}'
}


wordsplit() {
    perl -ane '$a=shift @F;print "$a\n";print " $_\n" for (@F)' "$@"
}

ediff() {
local b1=`basename --  $1`
local b2=`basename --  $2`
local t1=`mktemp $TEMP/$b1.XXXXXXX`
local t2=`mktemp $TEMP/$b2.XXXXXXX`
catz $1 |  wordsplit > $t1
catz $2 | wordsplit > $t2
diff -y $t1 $t2
rm $t1 $t2
}

escaped_args() {
 while [ $# -ge 1 ]; do
    perl -e "push @INC,'$BLOBS/libgraehl/latest';require 'libgraehl.pl';println(escaped_shell_args_str("@ARGV"));" -- $1
    shift
  done
}

savelog() {
 local logto=$1.`timestamp`.gz
 have_file $1 && catz $1 | gzip -c > $logto
 echo2 saved log to $logto
}

rotatelog() {
 local logto=$1.`timestamp`.gz
 have_file $1 && gzip $1
 have_file $1.gz  && mv $1.gz $1.`timestamp`.gz && echo moved old log to $1.`timestamp`.gz
}


#PBS queue aliases
 qsinodes=${qsinodes:-1}
 qsippn=${qsippn:-1}
 qsiq=${qsiq:-isi}
# anything
qsubi() {
 qsub -q $qsiq -I -l nodes=$qsinodes:ppn=$qsippn,walltime=150:00:00,pmem=3000mb "$@"
}
# big 64bit
qsi() {
 qsub -q $qsiq -I -l nodes=$qsinodes:ppn=$qsippn,walltime=150:00:00,pmem=15000mb,arch=x86_64 "$@"
}

qjobid() {
 echo "$@" | sed 's/^\(\d+\).*/\1/'
}

grep_running() {
  grep "$PBSQUEUE" | grep " R "
}

qrunning() {
# local PBSQUEUE=${1:-isi}
 PBSQUEUE=${PBSQUEUE:-isi}
 local j=`qjobid`
 local n=`qstat -a $j | grep_running | wc -l`
 echo "$n jobs running on $PBSQUEUE"
}

qusage() {
 PBSQUEUE=${PBSQUEUE:-isi}
 qstat -a | grep_running
 qrunning
}

qls() {
 PBSQUEUE=${PBSQUEUE:-isi}
  if [ "$*" ] ; then
   qstat -an `qjobid "$@"`
  else
   qstat -an1  | grep "$PBSQUEUE"
  fi
  qrunning
}

my_jobids() {
    local me=`whoami`
    qstat -u $me | grep $me | cut -d. -f1
}

myjobs() {
    local me=`whoami`
    local which=${1:-.}

    qstat -an1 -u $me | grep $me | egrep -i " $which "
}

forall_jobs() {
    local cmd=$1
    shift
#    local jobs=`my_jobids`
    local id
    for id in `my_jobids`; do
      echo $cmd "$@" $id
      $cmd "$@" $id
    done
}

logname() {
 echo ${log:-log.`filename_from "$@"`}
}

watch() {
    disown
    echo "$@"
    while ! [ -f "$@" ] ; do
        echo waiting for "$@"
        sleep 1
    done
    tail -f "$@"
}
log() {
    local log=`logname "$@"`
    nohup "$@" > $log &
    watch $log
}
loge() {
    local log=`logname "$@"`
    nohup env "$@" > $log 2>&1 &
    watch $log
}
ncpus() {
    cat /proc/cpuinfo | /bin/grep 'physical id' | sort | uniq -c || /bin/grep ^processor /proc/cpuinfo
}
ncores() {
    ncpus | nlines
}
traperr
getrealprog
[ -f $libg/libgraehl.pl ] || lnreal ~/t/utilities/libgraehl.pl $libg/

true
