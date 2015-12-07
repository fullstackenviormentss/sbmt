commt()
{
    (set -e
        pushd $racer/xmt/graehl/shared
        gsh=~/t/graehl/shared
        for f in *.?pp; do
            rm -f $gsh/$f
            cp $f $gsh/$f
        done
        pushd ~/t
        svn commit -m "$*"
        popd
        popd
    )
}
branchthis() {
    [[ $1 ]] && git checkout -b "$1"
}
linuxfonts() {
    (set -e
        sudo=sudo
        fontdir=/usr/local/share/fonts
        local t=`mktemp /tmp/fc-list.XXXXXX`
        local u=`mktemp /tmp/fc-list.XXXXXX`
        fc-list > $t
        $sudo mkdir -p $fontdir
        $sudo cp "$@" $fontdir
        $sudo fc-cache $fontdir
        fc-list > $u
        echo change in fc-list
        diff -u $t $u
    )
}
gstat() {
    git status
}
rebasec() {
    git add "$@"
    git rebase --continue
}
reamend() {
    pushd ~/x
    git commit -a --amend --no-edit
    popd
}
yreg() {
    (set -e;
        cd ~/x/RegressionTests
        set -x
        ./runYaml.py -b $racer/${BUILD:-Debug} -n -v -y \*$1\*
        set +x
    )
}
fastreg() {
    (set -e;
        cd ~/x/RegressionTests
        for f in *; do
            [ -d $f ] && [ $f != BasicShell ] && [ $f != xmt ] && [ -x $f/run.pl ] && regressp $f
        done
    )
}
rencd() {
    local pre="$*"
    showvars_required pre
    local prein=
    local postin=" Audio Track.wav"
    local postout=".wav"
    local out=renamed
    mkdir -p $out
    echo "rencd $pre" > $out/rencd.sh
    local pfile=$out/rencd.prompt
    rm -f $pfile
    for i in `seq -f '%02g' 1 ${ntracks:-20}`; do
        local t="$pre - [$i] "
        read -e -p "$t"
        echo $REPLY >> $pfile
        cp "$prein$i$postin" "$out/$t$REPLY$postout"
    done
}
gitgc() {
    git gc --aggressive
}
branchmv() {
    git branch -m "$@"
}
gitrecase() {
    local to=${2:-$1}
    git mv $1 $1.tmp && git mv $1.tmp $to
    git commit -a -m "fix case => $to"
}
install_ccache() {
    for f in gcc g++ cc c++ ; do ln -s ccache /usr/local/bin/$f; done
}
gitclean() {
    local dry="-n"
    if [[ $1 ]] ; then
        dry="-f"
    fi
    git clean -d -x $dry
}
git_dirty() {
    if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] ; then
        echo -n "*"
    fi
}
git_untracked() {
    n=$(expr `git status --porcelain 2>/dev/null| grep "^??" | wc -l`)
    if [[ $n -gt 0 ]] ; then
        echo -n "($n)"
    fi
}
clonefreshxmt() {
    git clone ssh://graehl@git02.languageweaver.com:29418/xmt
    scp -p -P 29418 git02.languageweaver.com:hooks/commit-msg xmt/.git/hooks
}
forcebranch() {
    local branch=$(git_branch)
    local forceb=$1
    if [[ $forceb ]] ; then
        git branch -D $forceb || echo new branch $forceb of $branch
        echo from $branch to $forceb
        git checkout -b $forceb
    fi
}
upre() {
    (set -e
        up
        git rebase master
    )
}
breview() {
    local branch=$(git_branch)
    local rev=$branch-review
    git commit -a --amend # in case you forgot something
    (set -e
        set -x
        if [[ $force ]] ; then
            forcebranch $rev
        else
            git checkout -b $rev
        fi
        up
        #git fetch origin
        #git rebase -i origin/master
        git rebase master
        git push origin HEAD:refs/for/master
        echo "git branch -D $rev # do this after gerrit merges it only"
    )
    echo ""
    git checkout $branch
    echo "git checkout $branch ; git fetch origin; git rebase origin/master # and this after gerrit merge"
}

gitdiff() {
    PAGER= git diff "$@"
    PAGER= git diff --submodule "$@"
}
drypull() {
    git fetch
    git diff ...origin
}
git_branch() {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}
rebase() {
    local branch=$(git_branch)
    set -x
    git stash
    (set -e
        remaster
        co $branch
        git rebase master
    )
    git stash pop
    set +x
}
gd2() {
    echo branch \($1\) has these commits and \($2\) does not
    git log $2..$1 --no-merges --format='%h | Author:%an | Date:%ad | %s' --date=local
}
grin() {
    git fetch origin master
    gd2 FETCH_HEAD $(git_branch)
}
grout() {
    git fetch origin master
    gd2 $(git_branch) FETCH_HEAD
}
gitlog() {
    if [ $# -gt 0 ]; then
        git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short --branches -p -$1
    else
        git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=short --branches  -n ${ncommits:-30}
        echo
    fi
}
gitreview() {
    git review "$@"
}
gerritorigin="ssh://graehl@git02.languageweaver.com:29418/xmt"
gerrit() {
    echo git push $gerritorigin HEAD:refs/for/master
    git push $gerritorigin HEAD:refs/for/master
}
gerritext() {
    local gerritorigin=origin
    echo git push $gerritorigin HEAD:refs/for/master
    git push $gerritorigin HEAD:refs/for/master
}
review() {
    git commit -a
    gerrit
}

push2() {
    local l=$1
    if [[ $2 ]] ; then
        l+=":$2"
    fi
    git push origin $l
}
status() {
    git status
    git branch -a
}
#branch.<branch>.remote and branch.<branch>.merge
#git config branch.master.remote yourGitHubRepo.git
config() {
    git config "$@"
}
remotes() {
    git remote -v
    git remote show origin
}
tracking() {
    git config --get-regexp ^br.*
}
gitkall() {
    gitk --all
}
co() {
    if [[ "$*" ]] ; then
        git checkout "$@"
    else
        git branch -a
    fi
}
up() {
    local branch=`git_branch`
    (set -e;
        git fetch origin
        co master
        git pull --stat
        git rebase
    )
    co $branch
}
remaster() {
    (set -e
        co master
        git fetch origin
        git pull --stat
        git rebase
        [[ $1 ]] && git checkout $1
    )
}
squash() {
    local branch=$(git_branch)
    (set -e
        remaster $branch
        git rebase -i master
    )
}
squashmaster() {
    git reset --soft $(git merge-base master HEAD)
}
branch() {
    if [[ "$*" ]] ; then
        co master
        git checkout -b "$@"
    else
        git branch -a
    fi
}
gamend() {
    if [[ "$*" ]] ; then
        local marg=
        local arg=--no-edit
# since git 1.7.9 only.
        if [[ "$*" ]] ; then
            marg="-m"
            arg="$*"
        fi
        git commit -a --amend $marg "$arg"
    else
        git commit -C HEAD --amend
    fi
}
amend() {
    git commit -a --amend
}
xmtclone() {
    git clone ssh://graehl@git02.languageweaver.com:29418/xmt "$@"
}
findc() {
    find . -name '*.hpp' -o -name '*.cpp' -o -name '*.ipp' -o -name '*.cc' -o -name '*.hh' -o -name '*.c' -o -name '*.h'
}

tea() {
    local time=${1:-200}
    shift
    local msg="$*"
    [[ $msg ]] || msg="TEA TIME!"
    (date;sleep $time;growlnotify -m "$msg ($time sec)";date) &
}

linxreg() {
    ssh $chost ". ~/a; BUILD=${BUILD:-Debug} fregress $*"
}

export PYTHONIOENCODING=utf_8
if [[ $HOST = graehl.local ]] ; then
    GCC_PREFIX=/usr/local/gcc-4.7.1
    GCC_BIN=$GCC_PREFIX/bin
fi
gcc47() {
    if [[ $HOST = graehl.local ]] ; then
        prepend_path $GCC_PREFIX
        add_ldpath $GCC_PREFIX/lib
        export CC=$GCC_BIN/gcc
        export CXX=$GCC_BIN/g++
    fi
}
maketest() {
    (set -x
        cd ~/x/${BUILD:-Debug}
        make Test$1 && */Test$1
    )
}
makerun() {
    local exe=$1
    shift
    (set -e
        set -x
        cd ~/x/${BUILD:-Debug}
        make $exe
        set +x
        local f=$(echo */$exe)
        if [[ -x $f ]] ; then
            if ! [[ $pathrun ]] ; then
                if ! [[ $norun ]] ; then
                    $f "$@"
                fi
            else
                $exe "$@"
            fi
        fi
    )
}
makejust() {
    norun=1 makerun "$@"
}
makeh() {
    makerun $1 --help
}
hncomment() {
    fold -w 77 -s | sed "s/^/   /" | pbcopy
}
forcet() {
    for f in "$@"; do
        cp ~/x/xmt/graehl/shared/$f ~/t/graehl/shared
        lnshared1 $f
    done
}
no2() {
    echo cat $TEMP/no2.txt
    "$@" 2>$TEMP/no2.txt
}
fregress() {
    racer=$(echo ~/c/fresh/xmt) BUILD=${BUILD:-Debug} regress1 "$@"
}
regressdirs() {
    (
        cd $1
        for f in RegressionTests/*/run.pl ;do
            if [[ -f $f ]] ; then
                f=${f%/run.pl}
                f=${f#RegressionTests/}
                echo $f
            fi
        done
    )
}
regress1p() {
    local dir
    (
        cd ${racer:-~/x/}
        set -e
        for dir in "$@"; do
            set -x
            BUILD=${BUILD:-Debug} ./RegressionTests/$dir/run.pl --verbose --no-cleanup
            set +x
        done
    )
}
regressp() {
    r="$*"
    [[ $* ]] || r=$(regressdirs ~/c/fresh/xmt)
    echo racer=$(echo ~/c/fresh/xmt) BUILD=${BUILD:-Debug} regress1p $r
    regress1p $r
}

fregressp() {
    racer=$(echo ~/c/fresh/xmt) regressp "$@"
}

regress1() {
    local dir
    for dir in "$@"; do
        (
            cd ${racer:-~/x}/RegressionTests/$dir
            BUILD=${BUILD:-Debug} ./run.pl --verbose --no-cleanup
        )
    done
}
regress2() {
    regress1 Hypergraph2
}
lwlmcat() {
    out=${2:-${1%.lwlm}.arpa}
    [[ -f $out ]] || LangModel -sa2text -lm-in $1 -lm-out "$out" -tmp ${TMPDIR:-/tmp}
    cat $out
}
pyprof() {
#easy_install -U memory_profiler
    python -m memory_profiler -l -v "$@"
}
macpageoff() {
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist
}
macpageon() {
    sudo launchctl load -wF /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist
}

#file arg comes first! then cmd, then args
javaperf="-XX:+UseNUMA -XX:+TieredCompilation -server -XX:+DoEscapeAnalysis"
rrpath() {
    (set -e
        f=$(whichreal "$1")
        r=${2:-'$ORIGIN'}
        echo adding rpath "$r" to $f
        [ -f "$f" ]
        set -x
        addrpathb "$f" "$r" "$f".rpath && mv "$f"{,.rpath.orig} && mv "$f"{.rpath,}
    )
}
svnchmodx() {
    chmod +x "$@"
    svn propset svn:executable '' "$@"
    svn propset eol-style native "$@"
}
lc() {
    catz "$@" | tr A-Z a-z
}
lnxmtlib() {
    d=${1?arg1: dest dir}
    mkdir -p $d
    for f in `find $racerext/libraries -name libd -prune -o -name '*.so'`; do
        echo $f
        force=1 lnreal $f $d/
    done
}
countvocab() {
    catz "$@" | tr -s ' \t' '\n' | sort | uniq -c
}
nsincludes() {
    perl -ne '
$ns=1 if /namespace/;
if (/^\s*#\s*include/ && $ns) {
print;
print $ARGV,"\n";
exit;
}
' "$1"
}
nsinclude() {
    for f in "$@"; do
        nsincludes "$f"
    done
}
gitsubpulls() {
#-q
    git submodule foreach git pull -q origin master
}
sitelisp() {
    cd ~/.emacs.d
    git submodule add git://github.com/${2:-emacsmirror}/$1.git site-lisp/$1
}
emcom() {
    cd ~/.emacs.d
    git add -v *.el defuns/*.el site-lisp/*.el
    git add -v snippets/*/*.yasnippet
    gcom "$@"
}
emsubcom() {
    cd ~/.emacs.d
    git pull
    cd site-lisp
    gitsubpush *
}
empull() {
    (
        set -x
        cd ~/.emacs.d
        git pull
        cd site-lisp
        gitsubpull *
        set +x
    )
}
uext() {
    cd $racerext
    svn update
}
comdocs() {
    cd ~/x/docs
    svn change=md *.md
    change=md commit=1 revx "$@"
    makedocs
    svn commit *.pdf -m 'docs: pandoc to pdf'
}
makedocs() {
    cd ~/x/docs
    . make.sh
}
roundshared() {
    cp ~/x/xmt/graehl/shared/* ~/t/graehl/shared/; relnshared
}
tagtracks() {
    for i in `seq -w 1 99`; do echo $i; id3tag --album='Top 100 Best Techno Vol.1' --track=$i $i-*.mp3 ; done
}
tagalbum() {
    for f in *.mp3; do echo $i; id3tag --album="$*" "$f" ; done
}
svnmime() {
    local type=$1
    shift
    svn propset svn:mime-type $type "$@"
}
svnpdf() {
    svnmime application/pdf *.pdf
}
xhostc() {
    xhost +192.168.131.135
}
showdefines() {
    ${CC:-g++} -dM -E "${1:--}" < /dev/null
}
showcpp() {
    local o=${outcpp:-~/tmp/t.cpp}
    for f in "$@"; do
        rm $o
        f=$(realpath $f)
        set -x
        pushd /Users/graehl/x/Debug/Hypergraph && /usr/bin/g++ -DGRAEHL_G1_MAIN -DHAVE_CXX_STDHEADERS -DBOOST_ALL_NO_LIB -DTIXML_USE_TICPP -DBOOST_TEST_DYN_LINK -DHAVE_SRILM -DHAVE_KENLM -DHAVE_OPENFST -O0 -g -Wall -Wno-unused-variable -Wno-parentheses -Wno-sign-compare -Wno-reorder -Wreturn-type -Wno-strict-aliasing -g -I/Users/graehl/x/xmt -I/Users/graehl/c/xmt-externals/libraries/utf8 -I/Users/graehl/c/xmt-externals/libraries/boost_1_45_0/include -I/Users/graehl/x/xmt/.. -I/Users/graehl/c/xmt-externals/libraries/BerkeleyDB.4.3/include -I/usr/local/include -I/Users/graehl/c/xmt-externals/libraries/openfst-1.2.10/src -I/Users/graehl/c/xmt-externals/libraries/openfst-1.2.10/src/include -I/users/graehl/t/ -E -x c++ -o $o -c "$f" && emacs $o
        popd
    done
}
pdfsettings() {
# MS fonts - distributed with the free Powerpoint 2007 Viewer or the Microsoft Office Compatibility Pack
#    mainfont=Cambria

#no effect?
    margin=2cm
    hmargin=2cm
    vmargin=2cm

#effect:
    paper=letter
    fontsize=11pt
    mainfont=${mainfont:-Constantia}
    sansfont=Corbel
    monofont=Consolas
    documentclass=scrartcl
    paper=letter

}
pand() {
    local t=$1
    shift
    local os=$t
    [[ $os = html ]] && t=html5
    local pdfargs=
    if [[ $os = pdf ]] ; then
        t=latex
        pdfsettings
    fi
    local f
    for f in "$@"; do
        local g=${f%.txt}
        g=${g%.md}
        g=${g%.}
        local o=$g.$os
        (
            texpath
            set -x
            set -e
# --read=markdown
            if [[ $os = pdf ]] ; then
                latextemplate=${latextemplate:-$(echo ~/.pandoc/template/xetex.template)}
                pandoc --webtex $f -w $t -o $o --latex-engine=xelatex --self-contained --template=$latextemplate --listings -V mainfont="${mainfont:-Constantia}" -V sansfont="${sansfont:-Corbel}" -V monofont="${monofont:-Consolas}"  -V fontsize=${fontsize:-11pt} -V documentclass=${documentclass:-article} -V geometry=${paper:-letter}paper -V geometry=margin=${margin:-2cm} -V geometry=${orientation:-portrait} -V geometry=footskip=${footskip:-20pt}
            else
                pandoc --webtex $f -w $t -o $o --latex-engine=xelatex --self-contained
            fi
            if [[ "$open" ]] ; then open $o; fi
        )
        echo $o
    done
}
pandall() {
    local o=`pand html "$@"`
    pand latex "$@"
    #pand epub "$@"
    #pand mediawiki "$@"
    pand pdf "$@"
    local f
    for f in $o; do
        open $f
    done
}
texpath() {
    export PATH=/usr/local/texlive/2011/bin/x86_64-darwin/:/usr/local/texlive/2011/bin/universal-darwin/:$PATH
}
sshut() {
    local dnsarg=
    if [ "$dns "] ; then
        dnsarg="--dns"
    fi
    ~/sshuttle/sshuttle $dnsarg -vvr graehl@ceto.languageweaver.com 0/0
}
dotshow() {
    local f=${1:-o}
    dot $f -Tpng -o $f.png && open $f.png
}
fsmshow() {
    local f=$1
    require_file $f
    local g=$f.dot
    set -x
    HgFsmDraw "$f" > $g
    dotshow $g
}
sceto() {
    ssh -p 4640 ceto.languageweaver.com "$@"
}
bsceto() {
    homer Hypergraph
    bceto
}
bceto() {
    sceto ". a;linx Debug"
}
homer() {
    for p in "$@"; do
        scp -P 4640 -r ~/c/xmt/$p/*pp graehl@ceto.languageweaver.com:c/xmt/xmt/$p
    done
}
homers() {
    homer Hypergraph
    homer LWUtil
}
racer=~/x
racerext=~/c/xmt-externals
racerlib=~/c/xmt-externals/libraries
#racer=$racer/xmt
#racer=$racer
#racers=$racer/xmt
view() {
    if [[ $lwarch = Apple ]] ; then
        open "$@"
    else
        xzgv "$@"
    fi
}
realgit=`which git`
substi() {
    (set -e
        local tr=$1
        shift
        subst.pl "$@" --dryrun --inplace --tr "$tr"
        echo
        cat $tr
        echo
        echo ctrl-c to abort
        sleep 5
        subst.pl "$@" --inplace --tr "$tr"
    )
}
substrac() {
    (
        pushd $racer/xmt
        substi "$@" $(ack --cpp -f)
    )
}
substcpp() {
    (
        substi "$@" $(ack --cpp -f)
    )
}
substcmake() {
    (
        substi "$@" $(ack --cmake -f)
    )
}
git() {
    if [[ $INSIDE_EMACS ]] ; then
        $realgit --no-pager "$@" | head -80
    else
        $realgit "$@"
    fi
}
gitchange() {
    git --no-pager log --format="%ai %aN %n%n%x09* %s%d%n"
}
mflist() {
    perl -e 'while(<>) { if (/<td align="left">([^<]+)</td>/) { $n=$1; $l=1; } else { $l=0; } }'
}
showlib() {
    (
        export DYLD_PRINT_LIBRARIES=1
        "$@"
    )
}
otoollibs() {
    perl -e '
$f=shift;
$_=`otool -L $f`;
while (m|^\s*(\S+) |gm) {
print "$1 " unless $1 =~ m|^/usr/lib/|;
}
print "\n";
' $1
}
libmn() {
    local m=${1:-48}
    local n=${2:-1}
    local s=$m.$n.dylib
    for f in *.$s; do local g=${f%.$s};
        local ss="$g.dylib $g.$m.dylib"
        svn rm $ss
        ln -sf $f $g.dylib
        ln -sf $f $g.$m.dylib
        svn add $ss
    done
}

hgrep() {
    history | grep "$@"
}
brewgdb() {
    brew install https://github.com/adamv/homebrew-alt/raw/master/duplicates/gdb.rb
}
gdbtool () {
    emacsc --eval "(gud-gdb \"gdb --annotate=3; --args $*\")"
}
svnrespecial() {
    for f in "$@"; do
        rm $f
        svn update $f
    done
}
fontsmooth() {
    defaults -currentHost write -globalDomain AppleFontSmoothing -int "${1:-2}"
}
locp=${locp:9922}
tun1() {
    local p=${3:-$port}
    if ! [[ $p ]] ; then
        p=$locp
        locp=$((locp+1))
    fi
# ssh -L9922:svn.languageweaver.com:443 -N -t -x pontus.languageweaver.com -p 4640 &
    set -x
    ssh -L$p:${1:-c-jgraehl.languageweaver.com}:${2:-22} -N -t -x ${4:-ceto}.languageweaver.com -p 4640
    set +x
    lp=localhost:$p
    echo lp
    echo $lp
}
revboardp=9921
rxsvnp=9922
tunrev() {
    tun1 revboard 80 $revboardp
}
tunsvn() {
    tun1 svn 80 $rxsvnp
}
tuns() {
    if ! [[ $nokill ]]; then
        for i in `seq 1 10`; do
            kill %$i
        done
        killall $revboardp
        killall $rxsvnp
    fi
    if ! [[ $nostart ]] ; then
        tunrev &
        tunsvn &
    fi
}
lwsvnhost=svn.languageweaver.com
localsvnhost=localhost:$rxsvnp
rxsvn="http://svn.languageweaver.com/svn/repos2"
rxlocal="http://localhost:$rxsvnp/svn/repos2"
cmerepo="http://svn.languageweaver.com/svn/repos2"
cmelocal="http://localhost:$rxsvnp/svn/repos2"
rblocal="http://localhost:$revboardp/"
rblw="http://revboard/"

revboardrc() {
    local rb=$rblw
    if [[ $local ]] ; then
        rb=$rblocal
    fi
    (echo "REPOSITORY = \"$cmerepo\""; echo "REVIEWBOARD_URL = \"$rb\"") > .reviewboardrc
}
svnroot() {
    svn info | grep ^Repository\ Root | cut -f 3 -d ' '
}
svnswitchurl() {
    svnroot | sed "s/$1/$2/"
}
svnswitchhost() {
    local r=$(svnroot)
    local u=$(svnswitchurl "$@")
    echo "$r => $u"
    set -x
    if [[ $svnpass ]] ; then
        local sparg="--password $svnpass"
    fi
    if [[ $svnuser ]] ; then
        local suarg="--username graehl"
    fi
    svn relocate $suarg $sparg "$r" "$u"
}
svnswitchlocal() {
    if [[ $local ]] ; then
        svnswitchhost $lwsvnhost $localsvnhost
    else
        svnswitchhost $localsvnhost $lwsvnhost
    fi
}
rxtun() {
    (
        cd $racer
        set -x
        svn relocate $rxsvn $rxlocal
        revboardrc
    )
}
#switch --relocate
rxlw() {
    (
        cd $racer
        set -x
        svn relocate $rxlocal $rxsvn
        revboardrc
    )
}
tokdot() {
    local t=${1:-2}
    shift
    local s=${1:-9}
    shift
    pushd ~/x/xmt/FsTokenizer
    stopw=$s tokw=$t draw=1 ./test.sh tiny.{vcb,untok}
    hgdot ~/r/FsTokenizer/work/s=$s,t=$t/tiny.vcb.trie.gz
    popd
}
tokt() {
    pushd ~/x/xmt/FsTokenizer
    ./test.sh "$@"
}
revx() {
    local dr=
#p
    local sum=$1
    shift
    if [[ $dryrun ]] ; then
        dr="n"
    fi
    pushd $racer
    set -x
    local dry=1
    local carg=
    if [[ $change ]] ; then carg="--svn-changelist=$change"; fi
    if [[ $commit ]] ; then dry=; fi
    if [ "$sum" ] ; then
        post-review -do$dr $carg --summary="$sum" --description="$*" --username=graehl --password=cheese --target-groups=ScienceCoreModels
        dryrun=$dry crac "$sum: $*"
        echo "crac '$sum: $*'" > ~/x/commit.sh
        chmod +x ~/x/commit.sh
    fi
    set +x
    popd
}
rerevx() {
    revxcmd -r "$@"
}
revxcmd() {
    pushd $racer
    if [[ $change ]] ; then carg="--svn-changelist=$change"; fi
    post-review "$@" $carg --username=graehl --password=cheese
    set +x
    popd
}
revr() {
    local dr=p
    local sum=$1
    shift
    if [[ $dryrun ]] ; then
        dr="n"
    fi
    pushd $racer
    set -x
    if [ "$sum" ] ; then
        (set -e
    # rxlw
            set -x
            post-review -do$dr --summary="$sum" --description="$*" --username=graehl --password=cheese --target-groups=ScienceCoreModels
     # rxtun
            svn commit -m "$sum: $*"
        )
    fi
    set +x
    popd
}
withdbg() {
    local d=$1
    shift
    local gdbc=
    if [ "$gdb" ] ; then
        gdbc="gdb --args"
    fi
# TUHG_DBG=$d
    TUHG_DBG=$d HYPERGRAPH_DBG=$d LAZYF_DBG=$d HGBEST_DBG=$d $gdbc "$@"
}
rmstashx() {
    rm -rf ~/c/stash.*
}
stashx() {
    cd ~/c
    local s=~/c/stash.`timestamp`
    mkdir -p $s
    cp -pr ~/c/xmt/{3rdParty/graehl,racerx/Hypergraph} $s
}
rcompile() {
    local s=$1
    shift
    local flags="-I$BOOST_INCLUDE -I$HOME/x/3rdparty -I$HOME/x -O0 -ggdb"
    g++ $flags -x c++ -DGRAEHL__SINGLE_MAIN -DHYPERGRAPH_MAIN "$s" "$@"
}
brewrehead() {
    brew remove "$@"
    safebrew install -d --force -v --use-gcc --HEAD "$@"
}
brewhead() {
    safebrew install -d --force -v --use-gcc --HEAD "$@"
}
nonbrew() {
    find "$1" \! -type l \! -type d -depth 1 | grep -v brew
}
rebrew() {
    brew remove "$@"
    safebrew install "$@"
}
safebrew() {
    local log=/tmp/safebrew.log
    (
        saves=$(echo /usr/local/{bin,lib,lib/pkgconfig})
        set +e
        for f in $saves; do
            echo mkdir -p $f/unbrew
            mkdir -p $f/unbrew
            set +x
            mv `nonbrew $f` $f/unbrew/
            set -x
        done
        mv /usr/local/bin/auto* $savebin
        export LDFLAGS+=" -L/usr/local/Cellar/libffi/3.0.9/lib"
        export CPPFLAGS+="-I/usr/local/Cellar/libffi/3.0.9/include"
        export PATH=/usr/local/bin:$PATH
        export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
#by default it looks there already. just in case!
        unset DYLD_LIBRARY_PATH
        set -x
        brew "$@" || brew doctor
        set +x
        savedirs=
        for f in $saves; do
            savedirs+=" $f/unbrew"
            mv -n $f/unbrew/* $f/
        done
        echo $savedirs should be empty:
        ls -l $savedirs
        echo empty, i hoope
    ) 2>&1 | tee $log
    echo cat $log
}
awksub() {
    local s=$1
    shift
    local r=$1
    shift
    awk '{gsub(/'"$s"'/,"'"$r"'")};1' "$@"
}
awki() {
    local f=$1
    shift
    cmdi "$f" awk "$@"
}
cmdi() {
    local f=$1
    shift
    local cmd=$1
    shift
    ( mv $f $f~ && $cmd "$@" > $f) < $f
    diff -b -B -- $f~ $f
}

gitsubuntracked() {
    awki .gitmodules ' {print}; /^.submodule / { print "\tignore = untracked" }'
}

gitsubpush1() {
    local p=$1
    shift
    local msg="$*"
    local sub=$(basename $p)
    echo git submodule push $p ...
    if ! [[ -d $p ]] ; then
        echo gitsubpush skipping non-directory $p ...
    else
        sub=${sub%/}
        (set -e
            pushd $p
            gcom "$msg"
            cd ..
            git commit $sub -m "$msg"
            git push $sub -m "$msg"
        )
    fi
}
gitsubpush() {
    forall gitsubpush1 "$@"
}
gitsubpull1() {
    local p=$1
    shift
    local msg="$*"
    echo git submodule push-pull $p ...
    if ! [[ -d $p ]] ; then
        echo gitsubpull skipping non-directory $p ...
    else
        (
            set -e
            pushd $p
            local sub=$(basename $p)
            sub=${sub%/}
            local gitbranch=${gitbranch:-${2:-master}}
            banner pulling submodule $p ....
            showvars_required sub gitbranch
            ! grep graehl .git/config || gcom "$msg"
            git checkout $gitbranch
            git pull
            cd ..
            git add `basename $p`
            git commit $sub -m "pulled $p - $msg"
            [[ $nopush ]] || git push
            banner DONE pulling submodule $p.
        )
    fi
}
gitsubpull() {
    forall gitsubpull1 "$@"
}
dbgemacs() {
    ${emacs:-appemacs} --debug-init
}
freshemacs() {
    git clone --recursive git@github.com:graehl/.emacs.d.git
}
urlup() {
#destroys hostname if you go to far
    perl -e '$_=shift;s|/[^/]+/?$||;print "$_";' "$*"
}
svnurl() {
    svn info | awk '/^URL: / {print $2}'
}
svngetrev() {
    svn ls -v "$@" | awk '{print $1}'
}
svnprev() {
    #co named revision of file in current dir
    local f=${1?-arg1: file in cdir}
    local r=$2
    [[ $r ]] || r=PREV
    local svnu=`svnurl`
    #local svnp=`urlup $svnu`
    local svnp="$svnu"
    local d=`basename $svnu`
    local dco="co-$d-r$r"
    set -e
    showvars_required svnp dco f r
    require_file $f
    local rev=`svngetrev -r "$r" $f`
    echo ""$f at revision $rev - latest as of requested $r:""
    ! [[ -d $dco ]] || rm -rf $dco/
    svn checkout -r "$rev" $svnp $dco --depth empty || error "svn checkout -r '$rev' '$svnp' $dco --depth empty" || return
    pushd $dco
    svn update -r "$rev" $f || error "svn update $f" || return
    popd
    local dest="$f@$r"
    ln -sf $dco/$f $dest
    diff -s -u "$dest" "$f"
    echo diff -s -u "$dest" "$f"
    echo
    echo $dest
}
svnprevs() {
    local rev=$1
    shift
    for f in "$@"; do
        (svnprev $f $rev)
    done
}
pids() {
    grep=${grep:-/usr/bin/grep}
    ps -ax | awk '/'$1'/ && !/awk/ {print $1}'
}
gituntrack() {
    git update-index --assume-unchanged "$@"
}
svntaglog() {
    local proj=${1:-carmel}
    local spath=${2:-"https://nlg0.isi.edu/svn/sbmt/tags/$proj"}
    showvars_required proj spath
    svn log -v -q --stop-on-copy $spath
}

svntagr() {
    svntaglog "$@" | grep " A"
}

gitsub() {
    git pull
    git submodule update --init --recursive "$@"
    git pull
}
gitrmsub() {
    git rm --cached $1
    git config -f .git/config --remove-section submodule.$1
    git config -f .gitmodules --remove-section submodule.$1
}
gitco() {
    git clone --recursive "$@"
}
gitchanged() {
    git status -uno
}
gcom() {
    gitchanged
    git commit -a -m "$*"
    git push -v
}
scom() {
    svn commit -m "$*"
}
gscom() {
    gcom "$@"
    scom "$@"
}
acksed() {
    echo going to replace $1 by $2 - ctrl-c fast!
    (set -e
        ack -l $1
        sleep 3
        ack -l --print0 --text $1 | xargs -0 -n 1 sed -i -e "s/$1/$2/g"
        ack $1l

    )
}
retok() {
    cd ~/x/xmt/Tokenizer
    ./test.sh "$@"
}
hgdot() {
    local m=${3:-${1%.gz}}
    HgDraw $1 > $m.dot
    doto $m.dot $2
}
doto() {
    local t=${2:-pdf}
    local o=${3:-${1%.dot}}
    dot -Tpdf -o$o.$t $1 && open $o.$t
}

dbgemacs() {
    cd ~/bin/Emacs.contents
    MacOS/Emacs --debug-init "$@"
}
lnshared() {
    forall lnshared1 "$@"
}
lnshared1() {
    local s=~/t/graehl/shared
    local f=$s/$1
    local d=$racer/xmt/graehl/shared
    local g=$d/$1

    if ! [ -r $f ] ; then
        cp $g $f
    fi
    if [ -r $f ] ; then
        if ! [ -r $g ] ; then
            ln $f $g
        fi
        if diff -u $g $f || [[ $force ]] ; then
            rm -f $g
            ln $f $g
        fi
    fi

    (cd $s; svn add "$1")
    #(cd $d; svn add "$1")
}
racershared1() {
    local s=~/t/graehl/shared
    local f=$s/$1
    local d=$racer/xmt/graehl/shared
    local g=$d/$1
    if [ -f $g ] ; then
        if [ "$force" ] ; then
            diff -u -w $f $g
            rm -f $f
        fi
        ln $g $f
    fi
}
usedshared() {
    (cd $racer/xmt/graehl/shared/;ls *.?pp)
}
diffshared1() {
    local s=~/t/graehl/shared/
    local f=$s/"$1"
    local d=$racer/xmt/graehl/shared/
    diff -u -w $f $d/$1
}
diffshared() {
    forall diffshared1 $(usedshared)
}
relnshared() {
    lnshared $(usedshared)
}
lnhg1() {
    local d=$1
    shift
    local pre=$1
    shift
    rpathsh=$racerlib/rpath.sh
    echo "$d" > ~/bin/racerbuild.dirname
    for f in $d/$pre*; do
        $rpathsh $f 1
        if [[ ${f%.log} = $f ]] ; then
            basename $f
            local b=`basename $f`
            for t in $b egdb$b gdb$b vg$b; do
                echo $t
                ln -sf $racer/run.sh ~/bin/$t
            done
        fi
    done
}
rpathhg() {
    rpathsh=$racer/3rdParty/Apple/rpath.sh
    local b=${1:-Debug}
    find $racer/$b -type f -exec $rpathsh {} \;
}
lnhg() {
    local b=${1:-Debug}
    lnhg1 $racer/$b Utf8Normalize/Utf8Normalize
    lnhg1 $racer/$b BasicShell/xmt
    lnhg1 $racer/$b OCRC/OCRC
    lnhg1 $racer/$b AutoRule/Test
    lnhg1 $racer/$b RuleSerializer/Test
    lnhg1 $racer/$b Hypergraph/Test
    lnhg1 $racer/$b Config/Test
    lnhg1 $racer/$b Hypergraph/Hg
    lnhg1 $racer/$b StatisticalTokenizer/StatisticalTokenizer
    lnhg1 $racer/$b LmCapitalize/LmCapitalize
    lnhg1 $racer/$b ValidateConfig/ValidateConfig
}
rebuildc() {
    (set -e
        s2c
        ssh $chost ". ~/a;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose} tests=${tests:-Hypergraph/Empty} racm Debug"
    )
}
ackc() {
    ack --ignore-dir=3rdParty --pager="less -R" --cpp "$@"
}
freshx() {
    (set -e; set -x; racer=~/c/fresh/xmt; cd $racer ; [ "$noup" ] || svn update; raccm ${1:-Debug}; cd $racer; RegressionTests/run.pl)
}
linx() {
    ssh $chost ". ~/.e;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose}_LEVEL test=$test tests=$tests freshx $*"
}
linxx() {
    (cd;sync2 $chost x/xmt x/RegressionTests x/docs)
    ssh $chost ". ~/.e;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose}_LEVEL test=$test tests=$tests raccm $*"
}

cmehost=cme01.languageweaver.com
cmex() {
    ssh $cmehost ". ~/a;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose}_LEVEL test=$test tests=$tests freshx $*"
}
cmexx() {
    (cd;sync2 $cmehost x/xmt x/RegressionTests x/docs)
    ssh $cmehost ". ~/a;HYPERGRAPH_DBG=${HYPERGRAPH_DBG:-$verbose}_LEVEL test=$test tests=$tests raccm $*"
}

chost=c-jgraehl.languageweaver.com
phost=pontus.languageweaver.com
horse=~/c/horse
horsem() {
    (
        export LW64=1
        export LWB_JOBS=5
        cd $horse
        perl GenerateSolution.pl
        make
    )
}
sa2c() {
    s2c
    (cd
        for d in x/xmt/ ; do
            sync2 $chost $d
        done
    )
}
s2c() {
    #elisp x/3rdParty
    (cd
        for d in u bugs t .emacs.d ; do
            sync2 $chost $d
        done
    )
}
syncc() {
    sync2 $chost "$@"
}
svndry() {
    svn merge --dry-run -r BASE:HEAD ${1:-.}
}
cregress() {
    find ~/x/RegressionTests -name '*.log' -exec rm {} \;
}
sconsd() {
    scons -Q --debug=presub "$@"
}
#sudo gem install git_remote_branch --include-dependencies - gives the nice 'grb' git remote branch cmd
#see aliases in .gitconfig #git what st ci co br df dc lg lol lola ls info ign


case $(uname) in
    Darwin)
        lwarch=Apple ;;
    Linux)
        lwarch=Linux ;;
    *)
        lwarch=Windows ;;
esac
ncpus() {
    if [[ $lwarch = Apple ]] ; then
        if [[ $usecpus ]] ; then
            echo $usecpus
        else
            echo 2
        fi
    else
        grep ^processor /proc/cpuinfo | wc -l
    fi
}
MAKEPROC=${MAKEPROC:-$(ncpus)}

lsld() {
    echo $DYLD_LIBRARY_PATH
}
addld() {
    if [[ $lwarch = Apple ]] ; then
        if ! fgrep -q "$1" <<< "$DYLD_LIBRARY_PATH" ; then
            export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$1
        else
            true || echo "$1 already in DYLD_LIBRARY_PATH"
        fi
    else
        if ! fgrep -q "$1" <<< "$LD_LIBRARY_PATH" ; then
            export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$1
        else
            true || echo "$1 already in LD_LIBRARY_PATH"
        fi
    fi
}
dylds() {

    for f in $racerlib/*; do
        if [ -d $f/lib ] ; then #[[ ${f%log4cxx-10.0.0} == $f ]] &&
            #echo $f
            addld $f/lib
        fi
    done
}
dylds

failed() {
    racb
    testlogs $(find . -type d -maxdepth 2)
}
testlogs() {
    for f in "$@"; do
        local g=$f/Testing/Temporary/LastTestsFailed.log
        if [ -f $g ] ; then
            tailn=30 preview $g
        fi
    done
}
corac() {
    svn co http://svn.languageweaver.com/svn/repos2/cme/trunk/xmt
    cd racerx
}
export XMT_EXTERNALS_PATH=$racerext
racb() {
    build=${build:-Release}
    if [[ $debug = 1 ]] ; then
        build=Debug
    fi
    build=${1:-$build}
    racerbuild=$racer/$build
    racer3=$racer/3rdParty
    export XMT_EXTERNALS_PATH=$racerext
    mkdir -p $racerbuild
    cd $racerbuild
    local fa=
    if [ "$*" ] ; then
        fa="-DCMAKE_CXX_FLAGS='$*'"
    fi
    local buildtyped=Release
    if [[ $build != Release ]] ; then
        buildtyped=Debug
    fi

    cmarg="-DLOG4CXX_ROOT=/usr/local -DCMAKE_BUILD_TYPE=${buildtype:-$buildtyped}"
}
racd() {
    cd $racer
    svn diff -b
}
urac() {
    (
        cd $racer
        if ! [ "$noup" ] ; then svn update ; fi
    )
}
crac() {
    pushd $racer
    local dryc=
    if [[ $dryrun ]] ; then
        dryc=echo
    fi
    local carg=
    if [[ $change ]] ; then carg="--changelist $change"; fi
    $dryc svn commit $carg -m "$*"
    popd
}
commx() {
    crac "$@"
}
svndifflines()
{
    diffcontext=0
    echo changed wc -l:
    svndiff | wc -l
}
svndiff()
{
    local diffcontext=${diffcontext:-8}
    svn diff --diff-cmd diff --extensions "-U $diffcontext -b"
}
svndifflog() {
    local lastlog=${1:-5}
    shift
    svn log -l $lastlog --incremental "$@"
    svndiff
}
drac() {
    cd $racer/3rdparty
    banner 3rdparty svn
    svndifflog 2 "$@"
    echo;echo
    banner racerx svn
    cd $racer
    svndifflog 5 "$@"
}
racm() {
    (
        set -e
        racb ${1:-Debug}
        shift || true
        cd $racerbuild
        set -x
        local prog=$1
        local maketar=
        if [ "$prog" ] ; then
            shift
            rm -f {Autorule,Hypergraph,FsTokenize,LmCapitalize}/CMakeFiles/$prog.dir/{src,test}/$prog.cpp.o
            if [[ ${prog#Test} = $prog ]] ; then
                test=
                tests=
            else
                maketar=$prog
                prog=
            fi
        fi
        if [[ $prog ]] && [[ "$*" ]]; then
            make -j$MAKEPROC $prog && $prog "$@"
        else
            make -j$MAKEPROC $maketar VERBOSE=1
        fi
        set +x
        if [[ $test ]] ; then make check ; fi
        for t in $tests; do
            ( set -e;
                echo $t
                td=$(dirname $t)
                tn=$(basename $t)
                testexe=$td/Test$tn
                [[ -x $testexe ]] || testexe=$t/Test$t
                $testgdb $testexe ${testarg:---catch_system_errors=no} 2>&1 | tee $td/$tn.log
            )
        done
    )
}
racc() {
    racb ${1:-Debug}
    shift || true
    cd $racerbuild
    ccmake ../xmt $cmarg
}
raccm() {
    racc ${1:-Debug}
    racm "$@"
}
ccmake() {
    local d=${1:-..}
    shift
    rm -f CMakeCache.txt $d/CMakeCache.txt
    local cxx=${CXX:-g++}
    local gccpre=g
    local cxxf=$cxxflags
    if [[ $clang ]] || [[ ${build#clang} != $build ]] ; then
        cxx=c++
        gccpre=c
        cxxf=-fmacro-backtrace-limit=100
    fi
    set -x

    CXX=$cxx CFLAGS= CXXFLAGS=$cxxf CPPFLAGS= LDFLAGS=-v cmake $d "$@"
    set +x
}
runc() {
    ssh $chost "$*"
}
enutf8=en_US.UTF-8
sc() {
    if [[ $term != xterm-256color ]] ; then
        ssh $chost "$@"
    else
        LANG=$enutf8 mosh --server="LANG=$enutf8 mosh-server" $chost "$@"
    fi
}
tocabs() {
    tohost $chost "$@"
}
toc() {
    tohostp $chost "$@"
}
topon() {
    thostp $phost "$@"
}
fromc() {
    fromhost $chost "$@"
}
clocal() {
    (
        set -e
        if [ "$1" ] ; then cd $1* ; fi
        ./configure --prefix=/usr/local "$@" && make -j && sudo make install
    )
}
msudo() {
    make -j 4 && sudo make install
}
cgnu() {
    for f in "$@"; do
        g=$f-${ver:-latest}.tar.${bzip:-bz2}
        (set -e
            curl -O http://ftp.gnu.org/gnu/$f/$g
            tarxzf $g
        )
    done
}
emacsapp=/Applications/Emacs.app/Contents/MacOS/
emacssrv=$emacsapp/Emacs
emacsc() {
    if [ "$*" ] ; then
        $emacsapp/bin/emacsclient -a $emacssrv "$@"
    else
        $emacssrv &
    fi
}

svnln() {
    forall svnln1 "$@"
}
svnln1() {
    ln -s $1 .
    svn add $(basename $1)
}


hemacs() {
    nohup ssh -X hpc-login2.usc.edu 'bash --login -c emacs' &
}
to3() {
    #-f ws_comma
    2to3 -f all -f idioms -f set_literal "$@"
}
to2() {
    #-f set_literal #python 2.7
    2to3 -f idioms -f apply -f except -f ne -f paren -f raise -f sys_exc -f tuple_params -f xreadlines -f types "$@"
}

ehpc() {
    local cdir=`pwd`
    local lodir=`relhome $cdir`
    ssh $HPCHOST -l graehl ". .bashrc;. t/graehl/util/bashlib.sh . t/graehl/util/aliases.sh;cd $lodir && $*"
}
reltohpc() {
    local cdir=`pwd`
    local lodir=`relhome $cdir`
    ssh $HPCHOST -l graehl "mkdir -p $lodir"
    scp "$@" graehl@$HPCHOST:$lodir
}

splitcomma() {
    clines "$@"
}

getwt()
{
    local f="$1"
    shift
    clines "$@" | fgrep -- "$f"
}
imira() {
    local hm=$HOME/hiero-mira
    local m=$HOME/mira
    rm -rf $hm
    mkdir -p $hm
    local b=/home/nlg-03/mt-apps/hiero-mira/20110804
    set -x
    cp -pR $b/* $hm/
    qmira
}
qmira()
{
    local hm=$HOME/hiero-mira
    local m=$HOME/mira
    for f in $m/{genhyps,log,trainer,sbmt_decoder}.py; do
        cp -p $f $hm/
    done
    (
        cd
        cd $hm
        pycheckers {genhyps,log,trainer,sbmt_decoder}.py
    )

}
vgnorm() {
    perl -i~ -pe 's|^==\d+== ?||;s|\b0x[0-9A-F]+||g' "$@"
}

pycheckers() {
    (
        pycheckerarg=${pycheckerarg:- --stdlib --limit=1000}
        [ -f setup.sh ] && . setup.sh
        for f in "$@" ; do
            pychecker $pycheckerarg $f 2>&1 | tee $f.check
        done
    )
}
#simpler than pychecker
pycheck() {
    python -c "import ${1%.py}"
}

cmpy() {
    python setup.py ${target:-install} --home $FIRST_PREFIX
}
cmpyh() {
    python setup.py ${target:-install} --home ~
}
backupsbmt() {
    mkdir -p $1
    #--exclude Makefile\* --exclude auto\* --exclude config\*
    #--size-only
    rsync --modify-window=1 --verbose --max-size=500K --cvs-exclude --exclude '*~' --exclude libtool --exclude .deps --exclude \*.Po --exclude \*.la --exclude hpc\* --exclude tmp --exclude .libs --exclude aclocal.m4 -a $SBMT_TRUNK ${1:-$dev/sbmt.bak}
    #-lprt
# cp -a $SBMT_TRUNK $dev/sbmt.bak
}
build_sbmt_variant()
{
    #target=check
    variant=debug boostsbmt "$@"
}

boostsbmt()
{
    (
        set -e
        local h=${host:-$HOST}
        nproc_default=5
        if [[ "$h" = cage ]] ; then
            nproc_default=7
        fi
        nproc=${nproc:-$nproc_default}
        variant=${variant:-$releasevariant}
        local linking="link=static"
        linking=
        branch=${branch:-trunk}
        trunkdir=${trunkdir:-$SBMT_BASE/$branch}
        [ -d $trunkdir ] || trunkdir=$HOME/t
        showvars_required branch trunkdir
        pushd $trunkdir
        mkdir -p $h
        local prefix=${prefix:-$FIRST_PREFIX}
        [ "$utility" ] && target="utilities//$utility"
        target=${target:-install-pipeline}
#
#--boost-location=$BOOST_SRCDIR
#-d 4
        local barg boostdir
        local builddir=${build:-$h}
        if [[ $boost ]] ; then
            boostdir=$HOME/src/boost_$boost
            builddir="${builddir}_boost_$boost"
        fi
        if [[ $boostdir ]] ; then
            [[ -d $boostdir ]] || boostdir=/usr/local
            barg="--boost=$boostdir"
        fi
        execpre=${execpre:-$FIRST_PREFIX}
        if [[ $variant = debug ]] ; then
            execpre+=/debug
        fi
        if [[ $variant = release ]] ; then
            execpre+=/valgrind
        fi
        bjam cflags=-Wno-parentheses cflags=-Wno-deprecated cflags=-Wno-strict-aliasing -j $nproc $target variant=$variant toolset=gcc --build-dir=$builddir --prefix=$prefix --exec-prefix=$execpre $linking $barg "$@" -d+${verbose:-2}
        set +x
        popd
    )
}
tmpsbmt() {
    local tmpdir=/tmp/trunk.graehl.$HOST
    backupsbmt $tmpdir
    trunkdir=$tmpdir/trunk boost=${boost:-1_35_0} boostsbmt "$@"
}
vgsbmt() {
    variant=release tmpsbmt
}
dusort() {
    perl -e 'require "$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl";while(<>){$n=()=m#/#g;push @{$a[$n]},$_;} for(reverse(@a)) {print sort_by_num(\&first_mega,$_); }' "$@"
}
realwhich() {
    whichreal "$@"
}
check1best() {
    echo 'grep decoder-*.1best :'
    perl1p 'while(<>) { if (/sent=(\d+)/) { $consec=($1==$last)?"(consecutive)":""; $last=$1; log_numbers("sent=$1"); if ($n{$1}++) { count_info_gen("dup consecutive $ARGV [sent=$1 line=$.]");log_numbers("dup $ARGV $consec: $1") } } } END { all_summary() }' decoder-*.1best
    grep -i "bad_alloc" logs/*/decoder.log
    grep -i "succesful parse" logs/*/decoder.log | summarize_num.pl
    grep -i "pushing grammar" logs/*/decoder.log | summarize_num.pl
# perl1p 'while(<>) { if (/sent=(\d+)/) { next if ($1==$last); $last=$1; log_numbers($1); log_numbers("dup: $1") if $n{$1}++; } } END { all_summary() }' decoder-*.1best
}

blib=$d/bloblib.sh
[ -r $blib ] && . $blib
em() {
    nohup emacs ~/t/sbmt_decoder/include/sbmt/io/logging_macros.hpp ~/t/sblm/sblm_info.hpp &
}
libzpre=/nfs/topaz/graehl/isd/cage/lib
HPF="$USER@$HPCHOST"
browser=${browser:-chrome}
ltd() {
    lt -d "$@"
}
comjam() {
    (
        set +e
        cd ~/t
        mv Jamroot Jamroot.works2; cp Jamroot.svn Jamroot; svn commit -m "$*"; cp Jamroot.works2 Jamroot
    )
}
upjam() {
    (
        set +e
        cd ~/t
        mv Jamroot Jamroot.works2; cp Jamroot.svn Jamroot; svn update; cp Jamroot.works2 Jamroot
    )
}
ld() {
    l -d "$@"
}
flv2aac() {
    local f=${1%.flv}
    set -o pipefail
    local t=`mktemp /tmp/flvatype.XXXXXX`
    local ext
    local codec=copy
    ffmpeg -i "$1" 2>$t || true
    if fgrep -q 'Audio: aac' $t; then
        ext=m4a
    elif fgrep -q 'Audio: mp3' $t; then
        ext=mp3
    else
        ext=wav
        codec=pcm_s16le
    fi
    set -x
    local mapa
    if [[ $stream ]] ; then
        mapa="-map 0:$stream"
    fi
    if [[ $start ]] ;then
        mapa+=" -ss $start"
    fi
    if [[ $time ]] ; then
        mapa+= " -t $time"
    fi
    local f="$1"
    shift
    ffmpeg -i "$f" -vn $mapa -ac 2 -acodec $codec "$f.$ext" "$@"
    set +x
}
tohpc() {
    cp2 $HPCHOST "$@"
}
cp2hpc() {
    cp2 $HPCHOST "$@"
}
buildpypy() {
    (set -e
        #http://codespeak.net/pypy/dist/pypy/doc/getting-started-python.html
        opt=jit
        [[ $jit ]] || opt=2
        # mar 2010 opt=2 is default (jit is 32-bit only)
        cd pypy/translator/goal
        CFLAGS="$CFLAGS -m32" ${python:-python2.7} translate.py --opt=$opt -O$opt --cc=gcc targetpypystandalone.py
        ./pypy-c --help
    )
}
safepath() {
    if [[ $ONCYGWIN ]] ; then
        cygpath -m -a "$@"
    else
        abspath "$@"
    fi
}
web() {
    $browser "file://$(safepath "$@")"
}
upa() {
    (pushd ~/t/graehl/util;
        svn update *.sh
    )
    sa
}
comg() {
    (pushd ~/t/graehl/
        svn commit -m "$*"
    )
}
comt() {
    (pushd ~/t/
        svn commit -m "$*"
    )
}
coma() {
    (pushd ~/t/graehl/util;
        svn commit *.sh -m sh
    )
}
upd() {
    for f; do
        blob_update $f
    done
}
new() {
    for f; do
        blob_new_latest $f
    done
}
ffox() {
    pkill firefox
    find ~/.mozilla \( -name '*lock' -o -name 'places.sqlite*' \) -exec rm {} \;
        firefox "$@"
}
rpdf() {
    cd /tmp
    scp hpc.usc.edu:$1 . && acrord32 `basename $1`
}
cpipe() {
    (pushd ~/pipe/
        svn commit -m "$*"
    )
}
cgraehl() {
    (
        pushd ~/t/graehl/
        set -x
        svn commit -m "$*"
    )
}
alias rot13="tr '[A-Za-z]' '[N-ZA-Mn-za-m]'"
cpdir() {
    local dest
    for dest in "$@"; do true; done
    set -x
    [ -f "$dest" ] && echo file $dest exists && return 1
    mkdir -p "$dest"
# [ -d "$dest" ] || mkdir "$dest"
    cp "$@"
    set +x
}
jobseq() {
    seq -f %7.0f "$@"
}
lcext() {
    perl -e 'for (@ARGV) { $o=$_; s/(\.[^. ]+)$/lc($1)/e; if ($o ne $_) { print "mv $o $_\n";rename $o,$_ unless $ENV{DEBUG};} }' -- "$@"
}

mkstamps() {
    (
        set -e
        local stamp=${stamp:-`mktemp /tmp/stamp.XXXXXX.tex`}
        stamp=${stamp%.tex}.tex
        mkdir -p "`dirname '$stamp'`"
        local title=${title:-""}
        local papertype=${papertype:-letter}
        local npages=${npages:-5}
        local headpg=${headpg:-R}
        local footpg=${footpg:-L}
        local botmargin=${botmargin:-1.3cm}
        local topmargin=${topmargin:-2cm}
        local leftmargin=${leftmargin:-0.4cm}
        local rightmargin=${rightmargin:-$leftmargin}
        showvars_required papertype npages stamp
        cat > "$stamp" <<EOF
        \documentclass[${papertype}paper,english]{article}
        %,9pt
        \usepackage[T1]{fontenc}
        \usepackage{pslatex} % needed for fonts
        \usepackage[latin1]{inputenc}
        \usepackage{babel}
        \usepackage{fancyhdr}
        %\usepackage{color}
        %\usepackage{transparent}
        \usepackage[left=$leftmargin,top=$botmargin,right=$leftmargin,bottom=$botmargin,${papertype}paper]{geometry}
        \title{$title}
        %\pagestyle{plain}
        \fancyhead{}
        \fancyhead[$headpg]{\thepage}
        \fancyfoot{}
        \fancyfoot[$footpg]{\thepage}
        \renewcommand{\headrulewidth}{0pt}
        \renewcommand{\footrulewidth}{0pt}
        \pagestyle{fancy}
        \begin{document}
        %\maketitle
        %\thispagestyle{empty}
        \begin{center}
        \footnotesize
        %\copyright 2008 Some Institute. Add your copyright message here.
        \end{center}
EOF

for i in `seq 1 $npages`; do
# echo '\newpage' >> $stamp
    echo '\mbox{} \newpage' \
        >> $stamp
done

echo '\end{document}' >> $stamp

local sbase=${stamp%.tex}
lat2pdf $sbase
echo $sbase.pdf
    ) | tail -n 1
}
pdfnpages() {
    pdftk "$1" dump_data output - | perl -ne 'print "$1\n" if /^NumberOfPages: (.*)/'
}
pdfstamp() {
    if [ -f "$1" ] ; then
        if [ -f "$2" ] ; then
            pdftk "$1" stamp "$2" output "$3"
        else
            cp "$1" "$3"
        fi
    else
        cp "$2" "$3"
    fi
}
pdfoverlay() {
    # pdftk bot stamp top (1 page at a time)
    (set -e
        local bot=$1
# bot=`abspath $bot`
        shift
        local top=$1
# top=`abspath $top`
        shift
        local out=${1:--}
        shift

        local npages=`pdfnpages "$top"`

        botpre=`tmpnam`.bot
        toppre=`tmpnam`.top
        allpre=`tmpnam`.all

        showvars_required npages botpre toppre allpre

        pdftk "$bot" burst output "$botpre.%04d.pdf"
        pdftk "$top" burst output "$toppre.%04d.pdf"

        local pages=
        for i in $(seq -f '%04g' 1 $npages); do
            pdfstamp $botpre.$i.pdf $toppre.$i.pdf $allpre.$i.pdf
            pages+=" $allpre.$i.pdf"
        done
        pdftk $pages cat output "$out"
        ls -l "$out"
        pdfnpages "$out"
    )
}
pdfnumber1() {
    (
        set -e
        local in=$1
        local inNOPDF=${in%.PDF}
        if [ "$in" != "$inNOPDF" ] ; then
            lcext "$in"
            in=$inNOPDF.pdf
        fi
        local inpre=${1%.pdf}
        shift
        in=`abspath "$in"`
        require_file "$in"
        local stamp=${stamp:-`tmpnam`}
        local stampf=$(stamp=$stamp npages=$(pdfnpages "$in") mkstamps)
        local out=${out:-$inpre.N.pdf}
        pdfoverlay "$in" "$stampf" "$out"
        rm "$stamp"*
        echo "$out"
    )
}
pdfnumber() {
    forall pdfnumber1 "$@"
}
exists_1() {
    [ -f "$1" ] || [ -d "$1" ]
}
based_paths_r() {
    local p=$1
    shift
    local d
    local r
    while true; do
        d=`dirname $p`
        r=`based_paths $d "$@"`
        [ -L $p ] || break
        exists_1 && break
    done
    echo "$r"
}
based_paths() {
    local base=$1
    [ "$base" ] || $base+=/
    shift
    local f
    local r=
    for f in "$@"; do
        r+=" $base$f"
    done
}

to8() {
    for f in "$@"; do
        iconv -c --verbose -f ${encfrom:-UTF16} -t ${encto:-UTF8} "$f" -o "$f"
    done
}

getcert() {
    local REMHOST=$1
    local REMPORT=${2:-443}
    echo | openssl s_client -connect ${REMHOST}:${REMPORT} 2>&1 |sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
}

pmake() {
    perl Makefile.PL PREFIX=$FIRST_PREFIX
    make && make install
}
unlibz() {
    mv $libzpre/libz.a $libzpre/unlibz.a
}

relibz() {
    mv $libzpre/unlibz.a $libzpre/libz.a
}

export PLOTICUS_PREFABS=$HOME/isd/lib/ploticus/prefabs
HPCHOST=hpc-login2.usc.edu
HPC32=hpc-login1.usc.edu
HPC64=hpc-login2.usc.edu
WFHOME=/lfs/bauhaus/graehl/workflow
WFHPC='~/workflow'


function gensym
{
    perl -e '$"=" ";$_="gensym @ARGV";s/\W+/_/g;print;' "$@" `nanotime`
}

function currydef
{
    local curryfn=$1
    shift
    eval function $curryfn { "$@" '$*'\; }
}

function curry
{
   #fixme: global output variable curryout, since can't print curryout and capture in `` because def would be lost.
    curryout=`gensym $*`
    eval currydef $curryout "$@"
}

pdfcat() {
    gs -sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH -sOutputFile=- "$@"
}

pdfrange() {
    local first=${1:-1}
    local last=${2:-99999999}
    shift
    shift
    verbose2 +++ pdfrange first=$first last=$last "$@"
    gs -sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH -dFirstPage=$((first)) -dLastPage=$last -sOutputFile=- "$@"
}

pdf1() {
    pdfhead -1 "$@"
}

pdfcat1() {
    mapreduce_files pdf1 pdfcat "$@"
}

pdftail() {
    local from=${from:--10}
    if [ "$from" -lt 0 ] ; then
        from=$((`nlines "$@"`-$from))
    fi
    pdfrange $from 99999999 "$@"
}

#range: 1-based double-closed interval e.g. (1,2) is first 2 lines
range() {
    local from=${1:-0}
    local to=${2:-99999999}
    shift
    shift
    perl -e 'require "$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl";$"=" ";' \
        -e '$F=shift;$T=shift;&argvz;$n=0;while(<>) { ++$n;;print if $n>=$F && $n<=$T }' \
        $from $to "$@"
    if false ; then
        if [ "$from" -lt 0 ] ; then
            tail $from "$@" | head -$to
        else
            head -$to "$@" | tail +$from
        fi
    fi
}

lastpr() {
    perl -ne 'while (/(P=\S+ R=\S+)/g) { $first=$1 unless $first;$last=$1};END{print "[corpus ",($first eq $last?$last:"$last (i=0: $first)"),"]\n"}' "$@"
}

nthpr() {
    perl -ne '$n=shift;while (/(P=\S+ R=\S+)/g) { $first=$1 unless $first;$last=$1;last if --$n==0;};END{print "[corpus ",($first eq $last?$last:"$last (i=0: $first)"),"]\n"}' "$@"
}
bigclm() {
    perl -i~ -pe ' s/lw/big/g if /clm-lr/' *.sh
}
scts() {
    local l=${1:-ara}
    grep BLEU detok $l-*/$l-decode-iter-*/ibmbleu.out | bleulr
}
mvpre() {
    local pre=$1
    shift
    for f in "$@"; do
        mv $f `dirname $f`/$pre.`basename $f`
    done
}
ofcom() {
    pushd ~/t/graehl/gextract/optfunc
    gcom "$@"
}
obut0() {
    rm -rf 1btn0000;. master.sh; rm -rf *0001;casub 1btn0000
}
but0() {
    for f in *1btn0000; do
        echo $f
        sleep 3
        casub $f
    done
}
chimira0() {
    local l=chi
    local g=$1
    echo genre=$g
    if [ "$g" ] ; then
        local m=$l-mira0000
        exh rm -rf $m
        . mira.sh $g-tune
        casub $m
    fi
}

pwdh() {
    local d=`pwd`
    local e=${d#$HOME/}
    if [ $d != $e ] ; then
        echo '~/'$e
    else
        e=${d#$WFHOME/}
        if [ $d != $e ] ; then
            echo "$WFHPC/$e"
        else
            echo $d
        fi
    fi
}
lnh() {
    ssh $HPCHOST "cd `pwdh` && ln -s $*" && ln -s "$@"
}
rmh() {
    ssh $HPCHOST "cd `pwdh` && rm $*" && rm "$@"
}
exh() {
    ssh $HPCHOST "cd `pwdh` && $*" && $*
}
double1() {
    catz "$@" "$@" > 2x."$1"
}
doublemany() {
    for f in "$@"; do
        double1 $f
    done
}

doubleinplace() {
    local nano=`nanotime`
    local suffix="$$$nano"
    for f in "$@"; do
        mv $f $f.$suffix
        cat $f.$suffix $f.$suffix > $f && rm $f.$suffix
    done
}

split() {
    cat "$@" | tr ' ' '\n'
}


cdr()
{
    cd $(realpath "$@")
}
cdw()
{
    cd $WFHOME/workflow/tune
}
mirasums() {
    for d in ${*:-.}; do
        find $d -name '*mira0*' -print -exec mira-summary.sh {} \;
    done
}
miras() {
    local a=""
    for d in ${*:-.}; do
        a="$a $d/*mira*"
    done
    miradirs $a
}
miradirs() {
    for d in ${*:-*mira000}; do
        if [ -d $d ] ; then
            echo -n $d
            if grep -q /home/nlg-02/data07/eng/agile-p4/lm $d/record.txt; then
                echo -n " AGILE LM"
            fi
            echo
            mira-summary.sh $d

            echo
        fi
    done
}
ln0() {
    mkdir -p $2
    pushd $2
    for f in ../$1/*-*0000; do ln -s $f .; done
    [ "$3" ] && rm *-$3*0000
    ls
    popd
}

cpsh() {
    mkdir -p $2
    cp $1/*.sh $2
    ssh $HPCHOST "cd `pwdh` && mkdir -p $2"
}
cprules() {
    cpsh $1 $2
    pushd $2
    ln -s ../$1/*{xrsdb0000,rules0000} .
    popd
}
srescue() {
    find "$@" -name '*.dag.rescue'
}
drescue() {
    for f in `srescue "$@"`; do
        diff $f $f.rescue
    done
}
rmrescue() {
    find "$@" -name '*.dag.rescue.*' -exec rm {} \;
}
rescue() {
    for f in `srescue "$@"`; do
        pushd `dirname $f`
        vds-submit-dag `basename $f`
        popd
    done
}
csub() {
    pushd `dirname $1`
    vds-submit-dag `basename $1`
    popd
}
casubr() {
    casub `ls -dtr *00* | tail -1` "$@"
}
kajobs() {
    for d in $1/*0000; do
        echo killing: $d
        kjobs $d
    done
}
kalljobs() {
    for d in "$@"; do
        kajobs $d
    done
}
progress() {
    [ "$3" ] && pushd $3
    local jd=*decode-iter-$2-${1}0000
    rm -rf $jd
    . progress.sh $1 $2
    casub $jd
    [ "$3" ] && popd
    true
}
cprogress() {
    [ "$3" ] && pushd $3
    local jd=chi-decode-$2-${1}0000
    exh rm -rf $jd
    . progress.sh $1 $2
    casub $jd
    [ "$3" ] && popd
    true
}

[ "$ONHPC" ] && alias qme="qstat -u graehl"
alias gpi="grid-proxy-init -valid 99999:00"
alias 1but="cd 1btn0000 && vds-submit-dag 1button.dag; cd .."
alias rm0="rm -rf *000?"
alias lsd="ls -al | egrep '^d'"
releasevariant="release debug-symbols=on --allocator=tbb"
variant=$releasevariant
qsi2() {
    local n=${1:-1}
    shift
    qsinodes=$n qsippn=2 qsubi -X "$@"
}
#variant=""
#
DTOOLS=$HOME/isd/decode-tools-trunk/
sbmtargs="$variant toolset=gcc -j4 --prefix=$DTOOLS"
alias pjam="bjam --prefix=$FIRST_PREFIX -j4"
alias sjam="bjam $sbmtargs"
buildpipe() {
    mkdir -p $DTOOLS
    pushd ~/t;svn update;bjam $sbmtargs install-pipeline ;popd
    pushd $DTOOLS
    ln -sf . x86_64;ln -sf . tbb
    cp $FIRST_PREFIX/lib/libtbb{,malloc}.* lib
    popd
}
buildxrs() {
    pushd ~/t;svn update;bjam $sbmtargs utilities//install ;popd
}
alias grepc="$(which grep) --color -n"
buildgraehl() {
    local d=$1
    local v=$2
    (set -e
        pushd ~/t/graehl/$d
        [ "$noclean" ] || make clean
        set -x
#LDFLAGS+="-ldl -pthread -lpthread -L$FIRST_PREFIX/lib"
#LDFLAGS+="-ldl -pthread -lpthread -L$FIRST_PREFIX/lib"
        make CMDCXXFLAGS+="-I$FIRST_PREFIX/include" BOOST_SUFFIX=mt -j$MAKEPROC
        make CMDCXXFLAGS+="-I$FIRST_PREFIX/include" BOOST_SUFFIX=mt install
        set +x
        popd
        if [ "$v" ] ; then
            pushd $FIRST_PREFIX/bin
            cp carmel carmel.$v
            cp carmel.static carmel.$v
            popd
        fi
    )
}
buildcar() {
    buildgraehl carmel "$@"
    # pushd ~/t/graehl/carmel
    # [ "$noclean" ] || make clean
    # set -x
    # make CMDCXXFLAGS+="-I$FIRST_PREFIX/include" LDFLAGS+="-ldl -pthread -lpthread -L$FIRST_PREFIX/lib" BOOST_SUFFIX= -j$MAKEPROC
    # make CMDCXXFLAGS+="-I$FIRST_PREFIX/include" LDFLAGS+="-ldl -pthread -lpthread -L$FIRST_PREFIX/lib" BOOST_SUFFIX= install
    # set +x
    # popd
    # if [ "$1" ] ; then
    # pushd $FIRST_PREFIX/bin
    # cp carmel carmel.$1
    # cp carmel.static carmel.$1
    # popd
    # fi
}
buildfem() {
    buildgraehl forest-em
}
buildboost() {(
        set -e
        local withouts
        [ "$without" ] && withouts="--without-mpi --without-python --without-wave"
        [ "$noboot" ] || ./bootstrap.sh --prefix=$FIRST_PREFIX
        ./bjam --build-type=complete --layout=tagged --prefix=$FIRST_PREFIX $withouts --runtime-debugging=on -j$MAKEPROC install
# ./bjam --threading=multi --runtime-link=static,shared --runtime-debugging=on --variant=debug --layout=tagged --prefix=$FIRST_PREFIX $withouts install -j4
# ./bjam --layout=system --threading=multi --runtime-link=static,shared --prefix=$FIRST_PREFIX $withouts install -j4
        )}
alias gmap='/local/bin/sudo ~/bin/append-gridmap'
alias buildextract="pushd ~/xrs-extract/c++-src;cvs update;make;popd"

PUZZLEBASE=~/puzzle
#PUZZLETO='graehl@isi.edu'
MYEMAIL='graehl@isi.edu'
PUZZLETO='1051962371@facebook.com'
#PUZZLETO=$MYEMAIL
function testp()
{
    pw=`pwd`
    ~/puzzle/test.pl ./`basename $pw` test.expect
}

function ocb()
{
    OCAMLLIB=/usr/lib/ocaml /usr/bin/ocamlbrowser &
}
function puzzle()
{
    (
        set -e
        require_dir $PUZZLEBASE
        puzzle=$1
        puzzledir=$PUZZLEBASE/$puzzle
        pushd $puzzledir
        if make || [ ! -f Makefile ] ; then
            local tar=$puzzle.tar.gz
            tar czf $tar `ls Makefile $puzzle $puzzle.{ml,py,cc,cpp,c} 2>/dev/null`
            tar tzf $tar
            set -x
            [ "$dryrun" ] || EMAIL=$MYEMAIL mutt -s $puzzle -a `realpath $tar` $PUZZLETO -b $MYEMAIL < /dev/null
            set +x
        fi
        popd
    )
}

#SCALA=c:/Users/graehl/.netbeans/6.7rc2/scala/scala-2.7.3.final/lib
SCALABASE=~/puzzle/scala
#SCALABASE=c:/Users/graehl/Documents/NetBeansProjects
function spuzzle()
{
    (
        set -e
        set -x
        puz=$1
        dist=$SCALABASE/$1
# require_dir $dist
        cd $dist
        slib=scala-library.jar
        plib=$puz.jar
        src=$puz.scala
        bin=$puz
        tar=$puz.tar.gz
        extra=
        if [ $puz = breathalyzer ] ; then
            extra=words
            maybe_cp $SCALA_PROJECTS/$puz/twl06.txt $extra || true
        fi
        chmod +x $bin
        all="$bin $slib $src $extra"
        if [ "$nomanifest" ] ; then
            all="$all `ls *.class`"
        else
            all="$all $plib"
        fi
# [ "$SCALA_HOME" ] && scala-jar.sh $1
        pwd
        require_files $all
        tar czf $tar $all
        tar tzf $tar
        set -x
        [ "$dryrun" ] || EMAIL=$MYEMAIL mutt -s $puz -a `realpath $tar` $PUZZLETO -b $MYEMAIL < /dev/null
        set +x
    )
}
rgrep()
{
    local a=$1
    shift
    if [ "$*" ] ; then
        find "$@" -exec egrep "$a" {} \; -print
    else
        find . -exec egrep "$a" {} \; -print
    fi
}

function frgrep()
{
    local a=$1
    shift
    find . -exec fgrep "$@" "$a" {} \; -print
}

function findpie ()
{
    local pattern=$1
    shift
    if [ "$2" ] ; then
        local name="-name $2"
        shift
    fi
    echo "find . $name $* -exec perl -p -i -e $pattern {} \;"
}


other() {
    local f=${1:?'returns $otherdir/`basename $1`'}
    showvars_required otherdir
    echo $otherdir/`basename $f`
}

diffother() {
    local f=$1
    shift
    local o=`other $f`
    require_files $f $o
    diff -u "$@" $f $o
}

other1() {
    local f=${1:?'returns $other1dir/$1 with $other1dir in place of the first part of $1'}
    showvars_required other1dir
    other1=$other1 perl -e 'for(@ARGV) { s|^/?[^/]+/|$ENV{other1}/|; print "$_\n"}' "$@"
}

diffother1() {
    local f=$1
    shift
    local o=`other1 $f`
    require_files $f $o
    diff -u "$@" $f $o
}

SBMT_TEST=~/t/$HOST/sbmt/sbmt_decoder/gcc/debug/link-static/sbmt_tests

cagepath() {
    variant=${variant:-debug}
    export PATH=/nfs/topaz/graehl/t/cage/sbmt/utilities/gcc-3.4.4/$variant/hoard-allocator-off:$PATH
    export PATH=/nfs/topaz/graehl/t/cage/sbmt/utilities/gcc-3.4.4/$variant/hoard-allocator-off/mini-ngram-max-order-7/mini-ngram-order-3:$PATH
}

tagmd() {
    set -x
    local to=$SBMT_SVNREPO/tags/mini_decoder/version-$1
    if [ "$force" ] ; then
        svn rm -m "redo $1" $to
    fi
    svn cp $SBMT_SVNREPO/branches/version-13.x $SBMT_SVNREPO/tags/mini_decoder/version-$1 -m "mini_decoder $1"
    set +x
}

svnmc() {
    svn commit -F svnmerge-commit-message.txt
}

svnmu() {
    svnmerge -S ../trunk merge
}

lastlog() {
    "$@" 2>&1 | tee ~/tmp/lastlog
}

msum() {
    local wh=$1
    shift
    mkdir -p sum
    local out=$wh
    [ "$*" ] && out=$wh.`filename_from "$@"`
    showvars wh out
    echo ~/t/utilities/summarize_multipass.pl -l $wh.log data/$wh.nbest -csv sum/$out.csv "$@"
    ~/t/utilities/summarize_multipass.pl -l $wh.log data/$wh.nbest -csv sum/$out.csv "$@" 2>&1 | tee sum/$out.sum
}

function clean_carmel
{
    pushd $SBMT_TRUNK/graehl/carmel
    make distclean
    popd
}


function build_carmel
{
    cd $SBMT_TRUNK/graehl/carmel

    nproc_default=3
    [ "$h" = cage ] && nproc_default=7
    nproc=${nproc:-$nproc_default}
    local archf
    local args
    args=""
    [ "$install" ] && $args="install"
    local install=${install:-$FIRST_PREFIX}
    [ -d "$install" ] || install=$HOME/isd/$install
    buildsub=${buildsub:-$ARCH}
    [ "$linux32" -o "$buildsub" = linux ] && archf="-m32 -march=i686"
    set -x
    BUILDSUB=$buildsub INSTALL_PREFIX=$install ARCH_FLAGS=$archf make -j $nproc $args "$@"
    set +x
}


function sbmt_test
{
    gdb --args $SBMT_TEST
}

function hoard()
{
    export LD_PRELOAD="$FIRST_PREFIX/lib/libhoard.so"
}

function nohoard()
{
    export LD_PRELOAD=
}


perlf() {
    perldoc -f "$@" | cat
}

alias gc=gnuclientw


VGARGS="--num-callers=16 --leak-resolution=high --suppressions=$HOME/u/valgrind.supp"
function vg() {
    local darg=
    local varg=
    local suparg=
    if [[ $gdb ]] ; then
        gdb --args "$@"
        return
    fi
    [ "$debug" ] && darg="--db-attach=yes"
    [ "$vgdb" ] && varg="--vgdb=full"
    [ "$sup" ] && suparg="--gen-suppressions=yes"
    local lc=
    if [ "$noleak" ] ; then
        lc=no
    else
        lc=yes
    fi
    if [ "$reach" ] ; then
        lc=full
        reacharg="--show-reachable=yes"
    fi
    set -x
    GLIBCXX_FORCE_NEW=1 valgrind $darg $varg $suparg --leak-check=$lc $reacharg --tool=memcheck $VGARGS "$@"
    set +x
}
vgf() {
    vg "$@"
# | head --bytes=${maxvgf:-9999}
}
#--show-reachable=yes
#alias vgfast="GLIBCXX_FORCE_NEW=1 valgrind --db-attach=yes --leak-check=yes --tool=addrcheck $VGARGS"
alias vgfast=vg
alias massif="valgrind --tool=massif --depth=5"

gpp() {
    g++ -x c++ -E "$@"
}
alias jane="ssh 3jane.dyndns.org -l jonathan"
alias shpc="ssh $HPCHOST -l graehl -X"
alias sh2="ssh $HPC64 -l graehl -X"
alias snlg="ssh nlg0.isi.edu -l graehl"

alias rs="rsync --size-only -Lptave ssh"

function hscp
{
    if [ $# = 1 ] ; then
        from=$1
        to=.
    else
        COUNTER=1
        from=''
        while [ $COUNTER -lt $# ]; do
            echo $from
            echo ${!COUNTER}

            from="$from ${!COUNTER}"
            let COUNTER=COUNTER+1
        done
        to=${!#}
    fi
    echo scp \"$from\" $shpchost:$to
    scp -r $from $shpchost:$to
}

function hrscp
{
    if [ $# = 1 ] ; then
        from=$1
        to=.
    else
        COUNTER=1
        from=''
        while [ $COUNTER -lt $# ]; do
            echo $from
            echo ${!COUNTER}

            from="$from ${!COUNTER}"
            let COUNTER=COUNTER+1
        done
        to=${!#}
    fi
    echo scp \"$shpchost:$from\" $to
    scp -r $shpchost:$from $to
}

function hrs
{
    if [ $# = 1 ] ; then
        from=$1
        to=.
    else
        COUNTER=1
        from=''
        while [ $COUNTER -lt $# ]; do
            echo $from
            echo ${!COUNTER}

            from="$from ${!COUNTER}"
            let COUNTER=COUNTER+1
        done
        to=${!#}
    fi
    echo rs \"$from\" $shpchost:$to
    rs $from $shpchost:$to
}


JOBTIME=${JOBTIME:-23:50:00}
qg() {
    qstat -au graehl
}
qsd() {
    qsub -q default -I -l walltime=$JOBTIME,pmem=4000mb "$@"
}


function xe
{
    xemacs "$@" &
    disown
}

function xt
{
    xterm -sb -ls -fn fixed "$@" &
    disown
}
HOST=${HOST:-`hostname`}
if [ "$HOST" = twiki ] ; then
    alias sudo=/local/bin/sudo
fi

function rebin
{
    pdq ~/bin
    for f in ../dev/tt/scripts/* ; do ln -s $f . ; done
    popd
}
alias pd=pdq
getattr() {
    attr=$1
    shift
    perl -ne '/\Q'"$attr"'\E=\{\{\{([^}]+)\}\}\}/ or next;print "$ARGV:" if ($ARGV ne '-'); print $.,": ",$1,"\n";close ARGV if eof' "$@"
}
#,qsh.pl,checkjobs.pl
alias commh="pdq ~/isd/hints;cvs update && comml;popd"
alias sb=". ~/.bashrc"
alias sa=". ~/u/aliases.sh"
alias sbl=". ~/u/bashlib.sh"
alias sl=". ~/local.sh"
export PBSQUEUE=isi

cp_sbmt() {
    local to=$1
    local sub=$2
    [ "$sub" ] && sub="/$sub"
    if [ "$to" ] ; then
        echo2 copying trunk to $to
        svn cp -m "trunk->$to" $SBMT_SVNREPO/trunk$sub $SBMT_SVNREPO/$to
    fi
}

tag_module() {
    local ver=$1
    local module=${2:-mini_decoder}
    showvars_required ver module
    if [ "$ver" ] ; then
        local to=tags/$module/version-$ver
        if [ "$force" ] ; then
            svn rm -m "redo $to" $SBMT_SVNREPO/$to
        fi
        cp_sbmt $to $3
    fi
}

tag_fem() {
    local ver=$1
    tag_module $ver forest-em graehl
}

tag_carmel() {
    local ver=$1
    tag_module $ver carmel graehl
}

tag_mini() {
    tag_module "$@"
}

set -b
shopt -s checkwinsize
shopt -s cdspell

hpcquota() {
    ssh almaak.usc.edu /opt/SUNWsamfs/bin/squota -U graehl
}


export LESS='-d-e-F-X-R'


function lastbool
{
    echo $?
}


greph() {
    fgrep "$@" $HISTORYOLD
}

export IGNOREEOF=10

#alias hrssd="hrs ~/dev/syntax-decoder/src dev/syntax-decoder"
rgrep()
{
    a=$1
    shift
    find . \( -type d -and -name .svn -and -prune \) -o -exec egrep -n -H "$@" "$a" {} \; -print
}
frgrep()
{
    a=$1
    shift
    find . \( -type d -and -name .svn -and -prune \) -o -exec fgrep -n -H "$@" "$a" {} \; -print
}
dos2unix()
{
    perl -p -i~ -e 'y/\r//d' "$@"
}
isdos()
{
    perl -e 'while(<>) { if (y/\r/\r/) { print $ARGV,"\n"; last; } }' "$@"
}
psgn1()
{
    psgn $1 | head -1
}
psgn()
{
    psg $1 | awk '{print $2}'
}
openssl=/usr/local/ssl/bin/openssl
certauth=/web/conf/ssl.crt/ca.crt
function sslverify()
{
    $openssl verify -CAfile $certauth "$@"
}
function sslx509()
{
    $openssl x509 -text -noout -in "$@"
}
function ssltelnet()
{
    $openssl s_client -connect "$@"
}

function bak()
{
    for x in "$@"; do
        cp $x ${x}`timestamp`
    done
}
function m()
{
    clear
    make "$@" 2>&1 | more
}
function ll ()
{
    /bin/ls -lA "$@"
}
function lt ()
{
    /bin/ls -lrtA "$@"
}
function l ()
{
    /bin/ls -ls -A "$@"
}
function c ()
{
    cd "$@"
}
function s ()
{
    su - "$@"
}
function f ()
{
    find / -fstype local -name "$@"
}
function e ()
{
    emacs "$@"
}
function wgetr ()
{
    wget -r -np -nH "$@"
}
function cleanr ()
{
    find . -name '*~' -exec rm {} \;
}
#function perl1 {
# local libgraehl=~/isd/hints/libgraehl.pl
# perl -e 'require "'$libgraehl'";' "$@" -e ';print "\n";'
#}
alias perl1="perl -e 'require \"\$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl\";\$\"=\" \";' -e "
alias perl1p="perl -e 'require \"\$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl\";\$\"=\" \";END{println();}' -e "
alias perl1c="perl -ne 'require \"\$ENV{HOME}/blobs/libgraehl/latest/libgraehl.pl\";\$\"=\" \";END{while((\$k,\$v)=each \%c) { print qq{\$k: \$v };println();}' -e "
alias clean="rm *~"
alias nitro="ssh -1 -l graehl nitro.isi.edu"
alias hpc="ssh -1 -l graehl $HPCHOST"
alias nlg0="ssh -1 -l graehl nlg0.isi.edu"
alias more=less
alias h="history 25"
alias jo="jobs -l"
alias err="tail -f /etc/httpd/logs/error_log"
alias errd="tail -f /etc/httpd-devel/logs/error_log"
alias apc="/var/www/twiki/apachectl"
alias apcd="/var/www/twiki/apachectl-devel"

function comm() {
    svn commit -m "$*"
}
function comml() {
    svn commit -l -m "$*"
}
#alias rtt="pdq ~/dev/shared;cvs update;popd;pdq ~/dev/tt;cvs update;make;popd
#alias comm="cvs commit -m ''"

alias cpup="cp -vRdpu"
# alias hem="pdq ~/dev/tt; hscp addfield.pl forest-em-button.sh dev/tt; popd"

coml() {
    for f; do
        echo commiting $f
        pushd $f && comml
        popd
    done
}
com() {
    for f; do
        echo commiting $f
        pushd $f && comm
        popd
    done
}
ch() {
    e nlg0.isi.edu coml "$@"
    e $HPCHOST up "$@"
}
# alias ls="/bin/ls"
RCFILES=~/isd/hints/{.bashrc,aliases.sh,bloblib.sh,bashlib.sh,add_paths.sh,inpy,dir_patt.py,.emacs}
alias hb="scp $RCFILES graehl@$HPCHOST:isd/hints"
alias fb="scp $RCFILES graehl@false.isi.edu:isd/hints"
alias dp=`/usr/bin/which d 2>/dev/null`
alias d="d -c-"
sd="~/dev/syntax-decoder/src"
sds=$sd/../scripts
alias hsds="coml $sds;hup $sds"
e() {
    local host=$1
    shift
    ssh -t $host -l graehl <<EOF
"$@"
EOF
}
ehost() {
    local p=`homepwd`
    local host=$1
    shift
    ssh -t $host -l graehl <<EOF
cd $p
"$@"
EOF
#"/bin/bash"' --login -c "'"$*"'"'
}

enlg() {
    ehost enlg "$@"
}
function homepwd
{
    perl -e '$_=`pwd`;s|^/cygdrive/z|~|;print'
}
eerdos() {
    local p=`homepwd`
    ssh -t erdos.isi.edu -l graehl <<EOF
cd $p
"$@"
EOF
}
estrontium() {
    local p=`homepwd`
    ssh -t strontium.isi.edu -l graehl <<EOF
cd $p
"$@"
EOF
}
ercage() {
    local p=`homepwd`
# ssh -t cage.isi.edu -l graehl <<EOF
    rsh -l graehl cage bash <<EOF
cd $p
"$@"
EOF
}
egrieg() {
    local p=`homepwd`
    ssh -t grieg.isi.edu -l graehl <<EOF
cd $p
"$@"
EOF
}
ecage() {
    local p=`homepwd`
    ssh -t cage.isi.edu -l graehl <<EOF
cd $p
$*
EOF
}
epro() {
    local p=`homepwd`
    ssh -t prokofiev.isi.edu -l graehl <<EOF
cd $p
$*
EOF
}
pro() {
    ssh prokofiev.isi.edu -l graehl
}
dhelp() {
    decoder --help 2>&1 | grep "$@"
}

grepnpb() {
    catz "$@" | egrep '^NPB\(x0:NN\) -> x0 \#'
}
perfnbest() {
    perfs "$@" | grep 'best derivations in '
}
tarxzf() {
    catz "$@" | tar xvf -
}
wxzf() {
    local b=`basename "$@"`
    wget "$@"
    tarxzf $b
}


redo() {
    local blob=$1
    local which=$2
    (cd $BLOBS/$blob && reblob $2 && realpath $2)

}
pdq() {
    local err=`mktemp /tmp/pdq.XXXXXX`
    pushd "$@" 2>$err || cat $err 1>&2
    rm -f $err
}
pawd() {
    perl1p "print &abspath_from qw(. . 1)"
}
comsd() {
    com ~/dev/syntax-decoder/"$@"
}
comtt() {
    coml ~/dev/shared
    coml ~/dev/tt
    coml ~/dev/xrsmodels
}
comh() {
    coml ~/isd/hints
}
comxrs() {
    coml ~/dev/xrsmodels
    coml ~/isd/hints
    coml ~/dev/shared
}
comdec() {
    comh
    comsd
    comsd
    comxrs
}
comall() {
    comh
    comsd
    comtt
}
redodecb() {
    redo decoder/decoder-bin
}
redodec() {
    redo bashlib
    redo libgraehl
    redo decoder
}
rdec() {
    comdec
    ehpc redodec
}
rdecs() {
    coml ~/dev/syntax-decoder/scripts
    ehpc redo decoder
}
rdecb() {
    coml ~/dev/syntax-decoder/src
    ehpc redo decoder/decoder-bin
}
rtt() {
    enlg comtt
    ehpc redo forest-em
}
alias sl=". ~/isd/hints/bashlib.sh"
alias hh="comh;huh"
if [ $HOST = TRUE ] ; then
    alias startxwin="/usr/X11R6/bin/startxwin.sh"
    alias rr="ssh nlg0 rdec"
    alias rdb="ssh nlg0 rdecb"
    alias rrs="ssh nlg0 rdecs"
fi

cb() {
    pushd $BLOBS/$1/unstable
}

export EMAIL='graehl@isi.edu'

allscripts="bashlib libgraehl qsh decoder"
allblobs="bashlib libgraehl qsh decoder/decoder-bin decoder rule-prep/identity-ascii-xrs rule-prep/add-xrs-models"
refresh_all() {
    (
        set -e
        for f in $allblobs; do redo $f latest ; done
    )
}
refresh_scripts() {
    (
        set -e
        for f in $allscripts; do redo $f latest ; done
    )
}
new_all() {
    (
        set -e
        for f in $allblobs; do blob_new_latest $f ; done
    )
}

xscripts() {
    find $1 -name '*.pl*' -exec chmod +x {} \;
    find $1 -name '*.sh*' -exec chmod +x {} \;
}

if [ "$ONCYGWIN" ] ; then
    sshwrap() {
        local which=$1
        shift
        set -x
        /usr/bin/$which -i c:/cache/.ssh/id_dsa "$@"
    }

    wssh() {
        sshwrap ssh "$@"
    }

    wscp() {
        sshwrap scp "$@"
    }

    cscp() {
        scp -2 $1 graehl@cage.isi.edu:/users/graehl/$2
    }
fi


function dvi2ps
{
    papertype=${papertype:-letter}
    local b=${1%.dvi}
    local d=`dirname $1`
    local b=`basename $1`
    pushd $d
    b=${b%.dvi}
    dvips -t $papertype -o $b.ps $b.dvi
    popd
}

function latrm
{
    rm -f *-qtree.aux $1.aux $1.dvi $1.bbl $1.blg $1.log
}
cplatex=~/texmf/pst-qtree.tex
[ -f $cplatex ] || cplatex=
function latp
{
    local d=`dirname $1`
    local b=`basename $1`
    pushd $d

    [ "$cplatex" ] && cp $cplatex .
    latrm $b
    local i
    for i in `seq 1 ${latn:=1}`; do
        if [ "$batchmode" ] ; then
            latex "\batchmode\input $b.tex"
        else
            latex $b.tex
        fi
    done
    [ "$cplatex" -a -f "$cplatex" ] && rm $cplatex
    popd
}
function latq
{
    local f=${1%.tex}
    latp $f && dvi2pdf $f
    latrm $f
}
function dvi2pdf
{
    local d=`dirname $1`
    local b=`basename $1`
    pushd $d
    b=${b%.dvi}
    dvi2ps $b
    ps2pdf $b.ps $b.pdf || true
    popd
}
function lat2pdf
{
    latq "$@"
}
function lat2pdf_landscape
{
    papertype=landscape lat2pdf $1
}

function vizalign
{
    echo2 vizalign "$@"
    local f=$1
    shift
    local n=`nlines "$f.a"`
    if [ "$n" = 0 ] ; then
        warn "no lines to vizalign in $f.a"
    fi
    local lang=${lang:-chi}
# if [ -f $f.info ] ; then
# viz-tree-string-pair.pl -t -l $lang -i $f -a $f.info
# else
    quietly viz-tree-string-pair.pl -c "$f" -t -l $lang -i "$f" "$@"
# fi
    quietly lat2pdf_landscape $f
}
function lat
{
    papertype=${papertype:-letter}
    latp $1 && bibtex $1 && latex $1.tex && ((latex $1.tex && dvips -t $papertype -o $1.ps $1.dvi) 2>&1 | tee log.lat.$1)
    ps2pdf $1.ps $1.pdf
}


comwei() {
    com $DEV/shared
    com $DEV/syntax-decoder-wei
}

st() {
    pushd ~/dev/sbmt/trunk/sbmt_decoder
}

sw() {
    cd $DEV/syntax-decoder-wei/src
}

HPCBASE="$HPCUSER@$HPCHOST"
ISIBASE="$ISIUSER@nlg0.isi.edu"

syncdev() {
    pushd $DEV
    if [ "$2" = "isi" -o "$SYNCTO" = "isi" ] ; then
        SSHBASE="$ISIBASE"
    else
        SSHBASE="$HPCBASE"
    fi
    echo2 sync to $SSHBASE
    if [ -d "$1" ] ; then
        echo2 sync $1
        set -x
#--exclude '*.o' --exclude '*~' --exclude 'cygwin' --exclude '*cygwin*'
#-qtprv
        rsync --rsh=ssh --exclude '*.o' --exclude '*~' --exclude '*.d' --verbose --size-only -lptav $1/ $SSHBASE:$SSHDEV/$1
        set +x
    else
        error directory ~/$1 not found - cannot sync
    fi
    popd
}

sync_shared() {
    syncdev shared "$@"
}


sbmtdir=$SBMT_TRUNK/sbmt_decoder

sbmt() {
    pushd $sbmtdir
}


SBMT_STAGE=$ARCHBASE/sbmt
sbmtcp() {
    if [ "$ONCAGE" ] ; then
        local trunkdest=$SBMT_STAGE
        mkdir -p $trunkdest
        set -x
        rsync --verbose --size-only --existing --cvs-exclude --exclude libtool --exclude .deps --exclude \*.Po --exclude \*.la --exclude build-linux --exclude tmp --exclude .libs --exclude config\* --exclude Makefile\* --exclude auto\* --exclude aclocal.m4 -lprt "$@" $SBMT_TRUNK $trunkdest
    else
        echo2 not copying sbmt - will only run on cage
    fi
}

BOOST_VERSION=1_50_0
BOOST_SUFFIX=
if true ; then
    BOOST_SUFFIX=-xgcc42-mt-d-1_49
    BOOST_VERSION=1_49_0
fi
if [[ -d $XMT_EXTERNALS_PATH ]] ; then
    BOOST_INCLUDE=$XMT_EXTERNALS_PATH/libraries/boost_$BOOST_VERSION/include
    BOOST_LIB=$XMT_EXTERNALS_PATH/libraries/boost_$BOOST_VERSION/lib
    add_ldpath $BOOST_LIB
fi

g1() {
    program_options_lib="-lboost_program_options$BOOST_SUFFIX -lboost_system$BOOST_SUFFIX"
    local source=$1
    shift
    [ -f "$source" ] || cd ~/t/graehl/shared
    local out=${OUT:-$source.`filename_from $HOST "$*"`}
    (
        set -e
        #set -x
        local flags="$CXXFLAGS $MOREFLAGS -I$GRAEHL_INCLUDE -I$BOOST_INCLUDE -DGRAEHL_G1_MAIN"
        showvars_optional ARGS MOREFLAGS flags
        if ! [ "$OPT" ] ; then
            flags="$flags -O0"
        fi
        local ccmd="g++"
        local linkcmd="g++"
        local archarg=
        if [[ $OS = Darwin ]] ; then
            ccmd="g++"
            linkcmd="g++"
            archarg="-arch x86_64"
        fi
        set -x
        $ccmd $archarg $MOREFLAGS -ggdb -fno-inline-functions -x c++ -DDEBUG -DGRAEHL__SINGLE_MAIN $flags "$@" $source -c -o $out.o
        $linkcmd $archarg $LDFLAGS $out.o -o $out $program_options_lib 2>/tmp/g1.ld.log
        LD_RUN_PATH=$BOOST_LIB $gdb ./$out $ARGS
        set +x
        set +e
    )
}
euler() {
    source=${source:-euler$1.cpp}
    local flags="$CXXFLAGS $MOREFLAGS -I$BOOST_INCLUDE -DGRAEHL__SINGLE_MAIN"
    local out=${source%.cpp}
    g++ -O euler$1.cpp $flags -o $out && echo running $out ... && ./$out
}
gtest() {
#"-I$SBMT_TRUNK
    MOREFLAGS="$GCPPFLAGS" OUT=$1.test ARGS="--catch_system_errors=no" g1 "$@" -DGRAEHL_TEST -DINCLUDED_TEST -ffast-math -lboost_unit_test_framework-${BOOST_SUFFIX:-mt} -lboost_test_exec_monitor-${BOOST_SUFFIX:-mt} -L/usr/local/lib
#
#
#-I/usr/include/db4 -L/usr/local/lib
}
gsample() {
    local s=$1
    shift
    GRAEHL_INCLUDE=${GRAEHL_INCLUDE:-$HOME/x/3rdparty} OUT=$s.sample ARGS=""$@"" g1 $s -DSAMPLE
}

hsbmt() {
    hscp ~/isd/strontium/bin/* ~/t/utilities/*.pl blobs/mini_decoder/unstable
    hscp ~/isd/erdos/bin/* blobs/mini_decoder/unstable/x86_64
}


function conf
{
    ./configure $CONFIG "$@"
}

function myconfig
{
    local C=$CONFIGBOOST
    [ "$noboost" ] && C=$CONFIG
    showvars_required C BUILDDIR LD_LIBRARY_PATH
    [ -x configure ] || ./bootstrap
    [ "$distclean" ] && [ "$BUILDDIR" ] && [ -d $BUILDDIR ] && rm -rf $BUILDDIR
    mkdir -p $BUILDDIR
    pushd $BUILDDIR
    [ "$reconfig" ] && rm -f Makefile
    echo ../configure $C $myconfigargs "$@"
    [ -f Makefile ] || ../configure $C $myconfigargs "$@"
    popd
}

function doconfig
{
    noboost=1 myconfig
}

function dobuild
{
    if doconfig "$@" ; then
        pushd $BUILDIR && make && make install
        popd
    fi
}


makesrilm_c() {
    make OPTION=_c World
}

makedb() {
    cd build_unix
    make distclean
    ../dist/configure --enable-cxx --prefix=$ARCHBASE
}


set_i686() {
    set_build i686
}
set_i686_debug() {
    set_build i686 -O0
}

chpc() {
    hscp ~/$1 $1
}

cpmd() {
    local v=${2:-latest}
    local d=${3:-~/blobs/mini_decoder/$v}
    require_files $1
    require_dirs $d
    chmod -R +w $d $d
    cp -f $1 $d
    cp -f $1 $d/x86_64
    chmod -R -w $d $d
    touch $d/../unstable
}

cpimd() {
    local v=${2:-latest}
    local d=${3:-~/blobs/mini_decoder/$v}
    local f=~/isd/hpc/bin/$1
    local f64=~/isd/hpc-opteron/bin/$1
    require_files $f $f64
    require_dirs $d
    chmod -R +w $d $d
    cp -f $f $d
    cp -f $f64 $d/x86_64
    chmod -R -w $d $d
    touch $d/../unstable
}


#function sssbmt
#{
#cd ~/t;svn update;ssbmt;ssh hpc-master '. .bashrc; ssbmt'
#}

function ehpcs
{
    for hpc in $HPC32 $HPC64; do
        ehost $hpc.usc.edu "$@" &
    done
    wait
}

#function ehpc
#{
#ssh $HPCHOST ". .bashrc;"$@""
#}

function uihpcs
{
    local which=${1:-unstable}
    ehpc svn update t/utilities
    ehpcs sbmt_static_build utilities
    ehpc redo mini_decoder $which
}

function svnu
{
    pushd $1
    svn update
    popd
}

function sssbmt
{
    local which=${1:-unstable}
    ehpc svnu t
    ehpcs noclean=$noclean ssbmt
    ehpc redo mini_decoder $which
}

function retrain_lm
{
    local base=${1:-small}
    cd ~/t/utilities/sample;. ../make.lm.sh;lwlms_train $base.lm.training $base.lm.LW 5
    cp $base.lm.LW* ~/projects/mini
}
upt()
{
    pushd ~/t
    svn update
    popd
}

mlm=~/t/utilities/make.lm.sh
[ -f $mlm ] && . $mlm

function cwhich
{
    l `which "$@"`
    cat `which "$@"`
}

function sbmtgrep
{
    ssh erdos.isi.edu "~/t/grep-source.sh $1"
}

function gar_dump
{
    grammar_view --cost 1 -a - -i -0 -g "$@"
}


function brf_dump
{
    grammar_view --cost 1 -a - -i -0 -b "$@"
}

function truex
{
    export DISPLAY=true.isi.edu:0.0
}

function xhosts
{
    xhost +hpc-opteron.usc.edu
    xhost +hpc-master.usc.edu
    xhost +bauhaus.isi.edu
    xhost +cage.isi.edu
    xhostc
}

function lennonbin
{
    if [ "$HOST" = erdos ] ; then
        set_extra_paths ~/isd/grieg
    fi
}

function vgx
{
    (
#lennonbin
        local outarg smlarg out vgprog dbarg leakcheck
        [ "$out" ] && outarg="--log-file-exactly=$out"
        [ "$xml" ] && xmlarg="--xml=yes"
        [ "$xml" ] && out=${out:-valgrind.xml}
        vgprog=valgrind
        [ "$valk" ] && vgprog=valkyrie
        [ "$valk" ] || leakcheck="--leak-check=yes --tool=memcheck"
        [ "$debug" ] && dbarg="--db-attach=yes"
        set -x
        GLIBCXX_FORCE_NEW=1 $vgprog $xmlarg $leakcheck $dbarg $VGARGS $outarg "$@"
        set +x
        [ "$xml" ] && valkyrie --view-log $out
    )
#--show-reachable=yes
}

function cm
{
    pushd ~/projects/mini
}

function redoxy
{
    pushd ~/t/sbmt_decoder
    doxygen sbmt_decoder.doxygen
    popd
}


function bak
{
    local ext=${2:-bak}
    [ -f "$1" ] && mv $1 $1.$ext
}

function goo2
{
    #mstsc &
    ssh -L 3390:192.168.1.200:3389 -p 4640 pontus.languageweaver.com "$@"
}


att=12.129.193.246

function unshuffle
{
    perl -e 'while(<>){print;$_=<>;die unless $_;print STDERR $_}' "$@"
}

diffwei() {
    local jon=${jon:-/cache/syntax-decoder/src}
    local wei=${wei:-~/dev/wei/syntax-decoder/src}
    local ttable=${ttable:-~/dev/wei/jon_code_names}
    for f; do
        local wfile=$wei/$f
        local jfile=$jon/$f
        if [ -f $ttable ] ; then
            local newjfile=`tmpnam`
            translate.pl -t $ttable < $jfile > $newjfile
            jfile=$newjfile
        fi
        diff -b -u $wfile $jfile
        echo2 + is from $jon, - is from $wei - for $f
    done
}

ngr() {
    local lm=$1
    shift
    ngram -ppl - -debug 1 -lm $lm "$@"
}


compare_length() {
    extract-field.pl -print -f text-length,foreign-length "$@" | summarize_num.pl
}

ogetbleu() {
    local log=${log:-bleu.`filename_from $1`}
    local nbest=${2:-1.NBEST.err}
    opt-nbest.out -maxiter 0 -init $1 -nos 0 -inputfile $nbest -keepInitsZero 2>&1 | tee $log
}


hypfromdata() {
    perl -e '$whole=$ENV{whole};$ns=$ENV{nsents};$ns=999999999 unless defined $ns;while(<>) { if (/^(\d+) -1 \# \# (.*) \# \#/) { if ($l ne $1) { print ($whole ? $_ : "$2\n");last unless $n++ < $ns; $l=$1; } } } ' "$@"
}

stripbracespace() {
    perl -pe 's/^\s+([{}])/$1/' "$@"
}

# input is blank-line separated paragraphs. print first nlines of first nsents paragraphs. blank=1 -> print separating newline
firstlines() {
    perl -e '$blank=$ENV{blank};$ns=$ENV{nsents};$ns=999999999 unless defined $ns;$max=1;$max=$ENV{nlines} if exists $ENV{nlines};$nl=0;while(<>) { print if $nl++<$max; if (/^$/) {$nl=0;print "\n" if $blank;last unless $n++ < $ns;} }' "$@"
}

stripunknown() {
    perl -pe 's/\([A-Z]+ \@UNKNOWN\@\) //g' "$@"
}

fixochbraces() {
# perl -ne '
# s/^\s+\{/ \{\n/ if ($lastcond);
# s/\s+$//;
# print;
# $lastcond=/^\s+(if|for|do)/;
# print "\n" unless $lastcond;
# END {
# print "\n" if $lastcond;
# }
# ' "$@"
    perl -e '$/=undef;$_=<>;print $_
$ws=q{[ \t]};
$kw=q{(?:if|for|while|else)};
$notcomment=q{(?:[^/\n]|/(?=[^/\n]))};
s#(\b$kw\b$notcomment+)$ws*(?:(//[^\n]*\n)|\n)$ws*\{$ws*#$1 { $2#gs;
s/}\s*else/} else/gs;
print;
# @lines=split "\n";
# for (@lines) {
# s#(\b$kw\b$notcomment*)(//.*?)\s*\{\s*$#$1 { $2#;
# print "$_\n";
# }
' "$@"
#s|(\b$kw\b$notcomment*)(//[^\n]*)(\{$ws*)\n|$1$3\n$2\n|gs;

}


tviz() {
    (
        set -e
        captarg=
        work=${work:-tviz}
        if [ "$caption" ] ; then
            captionfile=`mktemp /tmp/caption.XXXXXXXX`
            echo "$caption" > $captionfile
            captarg="-c $captionfile"
        fi
        escapetree | treeviz -s -p 'graph [fontsize=12,labelfontsize=10,center=0]; node [fontsize=10,height=.06,margin=".04,.02",nodesep=.02,shape=none] ;'"$*" $captarg > $work.dot
        require_files $work.dot
        out=$work
        dot -Tpng < $work.dot > $out.png
        require_files $out.png
        rm -f $captionfile
        ls $work.{dot,png}
        if ! [[ $noview ]] ; then
            firefox $work.png
        fi
    )
}
treevizn() {
    (
        set -e
        local graehlbin=`echo ~graehl/bin`
        export PATH=$BLOBS/forest-em/latest:$graehlbin:$PATH
        local n=$1
        shift
        local f=$1
        shift
        showvars_required n f
        require_files $f
        local dir=`dirname -- $f`
        local file=`basename -- $f`
        local outdir=$dir/treeviz.$file
        local workdir=$outdir/work
        mkdir -p $outdir
        mkdir -p $workdir
        local work=$workdir/line$n
        local out=$outdir/line$n
        local captionfile=`mktemp /tmp/caption.XXXXXXXX`
        showvars_required out captionfile
        get $n $f > $work.1best
        require_files $work.1best
        extract-field.pl -f hyp -pass $work.1best > $work.hyp
        require_files $work.hyp
        orig_pos=`extract-field.pl -f unreranked-n-best-pos $work.1best`
        (echo -n "line $n of $f (orig #$orig_pos): "; cat $work.hyp; ) > $captionfile
        require_files $captionfile
        cat $work.1best | extract-field.pl -f tree -pass | escapetree > $work.treeviz.tree
        if [ "$*" ] ; then
            cat $work.treeviz.tree | treeviz -s -p 'graph [fontsize=12,labelfontsize=10,center=0]; node [fontsize=10,height=.06,margin=".04,.02",nodesep=.02,shape=none] ;'"$*" -c $captionfile > $work.dot
        else
            cat $work.treeviz.tree | treeviz -s -p 'graph [fontsize=12,labelfontsize=10,center=0]; node [fontsize=10,height=.06,margin=".04,.02",nodesep=.02,shape=none] ;' -c $captionfile > $work.dot
        fi
        require_files $work.dot
        dot -Tpng < $work.dot > $out.png
        require_files $out.png
        rm -f $captionfile
    )
}


spaste() {
    lodgeit.py -l scala $*
}

wtake() {
    wget -r -l1 -H -t1 -nd -N -np -A.mp3 -erobots=off "$@"
}
alias slo='ssh login.clsp.jhu.edu -l jgraehl'
cplo1() {
    local dest=`relpath ~ $1`
    local dd=`dirname $dest`
    [ "$dd" == "." ] || elo mkdir -p "$dd"
    [ -d "$1" ] && dest=$dd
    echo scp -r "$1" jgraehl@login.clsp.jhu.edu:"$dest"
    scp -r "$1" jgraehl@login.clsp.jhu.edu:"$dest"
}
rfromlo1() {
# set -x
    local dest=`relpath ~ $1`
    mkdir -p `dirname $dest`
    echo scp -r jgraehl@login.clsp.jhu.edu:"$dest" "$1"
    scp -r jgraehl@login.clsp.jhu.edu:"$dest" "$1"
}
flo() {
    local f
    for f in "$@"; do
        echo scp -r jgraehl@login.clsp.jhu.edu:"$f" .
        scp -r jgraehl@login.clsp.jhu.edu:"$f" .
    done
}

elo() {
    local cdir=`pwd`
    local lodir=`relpath ~ $cdir`
    ssh login.clsp.jhu.edu -l jgraehl ". .bashrc;. isd/hints/aliases.sh;cd $lodir && $*"
# "$@"
}
eboth() {
    echo "$@"
    "$@" && echo && echo HPC: && echo && ehpc "$@"
}
DefaultBaseAddress=0x70000000
DefaultOffset=0x10000

cygbase() {
    local BaseAddress=${base:-$DefaultBaseAddress}
    local Offset=${off:-$DefaultOffset}
    local f=$1
    shift
    [ -f "$f" ] || f=c:/cygwin/bin/$f
    set -x
    rebase -v -d -b $BaseAddress -o $Offset $f "$@"
    set +x
}

export SVNAUTHORS=~/isd/hints/svn.authorsfile
clonecar() {
    set -x
    local CR=https://nlg0.isi.edu/svn/sbmt/
    git config svn.authorsfile $SVNAUTHORS && git svn --authors-file=$SVNAUTHORS clone --username=graehl --ignore-paths='^(NOTES.*|scraps|syscom|tt|xrsmodels|Jamfile|dagtt)' ---trunk=$CR/trunk/graehl "$@"
#--tags=$CR/tags --branches=$CR/branches
#-r 3502 at
# https://nlg0.isi.edu/svn/sbmt/trunk/graehl@3502
#e4bd1e594dd7051a9e50561d19bdc31139ba1159

    #--no-metadata
    set +x
}


testws() {
    cd $WSMT
    makews && ./tests/run-system-tests.pl
}

svncom() {
    (
        proj=${project:-$WSMT}
        cd $proj
        echo $project $proj
        set -e
        set -x
        (
            if [ $# = 1 ] ; then
                git commit -a -m "$1"
            else
                git commit -a "$@"
            fi
        )
        git svn rebase
        git svn dcommit
# git push
    )
}
alias wscom="project=$WSMT svncom"

alias c10="pushd $WSMT"

grcom() {
    (
        set -e
# project=~/graehl svncom "$@"
        cd ~/t/graehl
        (
            if [ $# = 1 ] ; then
                svn commit -m "$1"
            elif [ $# -gt 0 ] ; then
                svn commit "$@"
            fi
        )
        cd ~/2git/fromsvn/
# git svn fetch
        git svn rebase
        git branch
        git push github master
        [ "$grtag" ] && git tag -a "$grtag" -m 'tag:$grtag'
    )
}


toy() {
    local h=$1
    shift
    set -x
    $cdec -c ${TOYG:-~/toy-grammar}/cdec-$h.ini "$@"
    set +x
}

feo() {
    local tt=${1:-hiero}
    shift
    echo 'eso perro feo .' | toy $tt "$@"
}

par() {
    local npar=${npar:-20}
    local parargs=${parargs:-"-p 9g -j $npar"}
    local logdir=${logdir:-`filename_from log "$@"`}
    logdir="`abspath $logdir`"
    mkdir -p "$logdir"
    showvars_required npar parargs logdir
    logarg="-e $logdir"
    set -x
    $WSMT/vest/parallelize.pl $parextra $parargs $logarg -- "$@"
    set +x
}

cmakews() {
    (cd $WSMT
        [ "$HOST" = zergling ] || svn update
        makews "$@"
    )
}

cmakevest() {
    cmakebin decoder libcdec.a
    cmakebin vest
}
qjhu() {
    SGE_ROOT=/usr/local/share/SGE /usr/local/share/SGE/bin/lx24-x86/qlogin -l mem_free=9g
}
qelo() {
    elo qjhu
}
w10com() {
    project=$WSMT svncom "$@"
}
mkdest() {
    if [ "$2" ] ; then
        dest=$2
    else
        dest=`dirname "$1"`
        mkdir -p "$dest"
    fi
}
fromnlg1() {
    mkdest "$@"
    echo scp -r 'graehl@nlg0.isi.edu:'"$1" "$dest"
    scp -r graehl@nlg0.isi.edu:"$1" "$dest"
}
fromnlg() {
    forall fromnlg1 "$@"
}

fromhost1() {
    (
        cd
        mkdest "$@"
        user=${user:-`userfor $host`}
        echo scp -r "$user@$host:$1" "$dest"
        scp -r $user@$host:"$1" "$dest"
    )
}
fromlo1() {
    user=jgraehl host=login.clsp.jhu.edu fromhost1 "$@"
}
fromhost() {
    local host=$1
    shift
    host=$host forall fromhost1 "$@"
}
fromlo() {
    user=jgraehl fromhost login.clsp.jhu.edu "$@"
}
relhomeby() {
    ${relpath:-$UTIL/relpath} ~ "$@"
}

shost1() {(set -e
        local portarg=
        if [[ $port ]] ; then
            portarg=-P$port
        fi
        )}
tohost1() {
    (
        set -e
        f=$(relhomeby $1)
        cd
        local u
        user=${user:-`userfor $host`}
        [ "$user" ] && u="$user@"
        echo scp -r "$f" "$u$host:`dirname $f`"
        local portarg=
        if [[ $port ]] ; then
            portarg=-P$port
        fi
        if [ "$dryrun" ] ; then
            showvars_optional relpath
        else
            scp $portarg -r "$f" "$u$host:`dirname $f`"
        fi
    )
}
tohostp1() {
    relpath=$UTIL/relpathp tohost1 "$@"
}
tohost() {
    local host=$1
    shift
    host=$host forall tohost1 "$@"
}
tohostp() {
    local host=$1
    shift
    host=$host forall tohostp1 "$@"
}

fromhpc() {
    fromhost $HPCHOST "$@"
}
fromhpc1() {
    host=$HPCHOST fromhost1 "$@"
}
tonlg1() {
    (
        set -e
        f=`relpath ~ $1`
        cd
        echo scp -r "$f" 'graehl@nlg0.isi.edu:'"`dirname $f`"
        scp -r "$f" 'graehl@nlg0.isi.edu:'"`dirname $f`"
    )
}
tonlg() {
    forall tonlg1 "$@"
}
cplo() {
    forall cplo1 "$@"
}
rfromlo() {
    forall rfromlo1 "$@"
}
tcmi() {
    local d=$1
    local f=$1
    d=${d%.tar.bz2}
    d=${d%.tar.gz}
    d=${d%.tgz}
    d=${d%.tar.xz}
    shift
    set -x
    tarxzf "$f" && cd "$d" && cmi "$@"
}
wtx() {
    wget "$1" && tarxzf $(basename $1)
}
wcmi() {
    wget "$1" && tcmi "$(basename $1)"
}
cmi() {
    if ./configure $CONFIG "$@"; then
        make -j 4
        make && make install
    fi
}

cpanforce() {
    perl -MCPAN -e '*CPAN::_flock = sub { 1 }; install( "Test::Output" );' "$@"
}

bleulog() {
    perl -ne 'BEGIN{$x=shift};print "$x\t$1\n" if /BLEU(?: score)? = ([\d.]+)/' -- "$@"
}

firstnum() {
    # 1: string to find number in: .*prefix.*(\d[\d.e-+]*)
    # 2: optional match - first number after match gets printed.
    perl -e '$_=shift; $p=shift; $_=$1 if /\Q$p\E(.*)/;if (/((?:[-+\d]|(?<=\.)\.)[-\d.e+]*)/) { $_=$1;s/\.$//;print "$_\n"}' "$@"
}

shortsh1() {
    perl -i~ -pe 's/^\s*function\s+(\w+)\s*\{/\1() {/' -- "$@"
}
shortsh() {
    shortsh1 *.sh "$@"
}
conff=`echo `
allconff="$conff elisp"
rsync_exclude="--exclude=.git/ --cvs-exclude"

sync2() {
    (
        cd
        local h=$1
        shift
        local u
        user=${user:-$(userfor $h)}
        [ "$user" ] && u="$user@"
        local f
        local darg
        [ "$dryrun" ] && darg="-n"
        echo sync2 user=$user host=$h "$@"
        set -x
        (for f in "$@"; do if [ -d "$f" ] ; then echo $f/; else echo $f; fi; done) | rsync $darg -avruz -e ssh --files-from=- $rsyncargs $rsync_exclude . $u$h:${dest:=.}
    )
}
syncto() {
    sync2 "$@"
}
userfor() {
    case $1 in
        login*) echo -n jgraehl ;;
        *) echo -n graehl ;;
    esac
}
syncfrom() {
    (
        cd
        local h=$1
        shift
        local u
        user=${user:-`userfor $h`}
        [ "$user" ] && u="$user@"
        local f
        local darg
        [ "$dryrun" ] && darg="-n"
        echo syncFROM user=$user host=$h "$@"
        sleep 2
        set -x
        (for f in "$@"; do echo $f; done) | rsync $darg $rsync_exclude -avruz -e ssh --files-from=- $u$h:. .
    )
}
conf2() {
    sync2 $1 isd/hints/
    sync2 $1 .inputrc .screenrc .bashrc .emacs
    sync2 $1 elisp/
}
conffrom() {
    fromhost $1 isd/hints/
    fromhost $1 .inputrc .screenrc .bashrc .emacs
# syncfrom $1 elisp/
}
conf2l() {
    conf2 login.clsp.jhu.edu
}
alias lob="(cd;cplo isd/hints/{aliases.sh,bashlib.sh};cplo .inputrc .bashrc .emacs )"
alias loa="(cd;cplo1 isd/hints/aliases.sh)"
alias froma="(cd;fromlo1 isd/hints/aliases.sh)"
alias loe="(cd;cplo .emacs elisp)"
alias qs="qstat -f -j"
qdelrange() {
    for i in `seq -f "%.0f" "$@"`; do
        qdel $i
    done
}
cdech() {
    $cdec --help 2>&1 | more
}
gitundo() {
    git stash save --keep-index
}
gitundorm() {
    git stash drop
}
alias comlo=ws10com
makews() {
    local dargs
    [ "$debug" ] && dargs="CXXFLAGS+='-O0'"
    [ "$clean" ] && make clean
    [ "$ONCYGWIN" ] && rm gi/posterior-regularisation/prjava/prjava.jar
    #rm -f $WSMT/decoder/*.o $WSMT/decoder/lib*.a
    set -x
    if [ "$confonly" ] ; then
        CXXFLAGS="$CXXFLAGS -O0 -ggdb -Wno-sign-compare -Wno-unused-parameter" ./configure
    else
        #-O0 -ggdb
        make CXXFLAGS+="-Wno-sign-compare -Wno-unused-parameter" LIBS+="-loolm -ldstruct -lmisc -lz -lboost_program_options -lpthread -lboost_regex -lboost_thread" -j $MAKEPROC $dargs "$@"
    fi
    set +x
}
cdecmake() {
    (
        set -e
        cd $WSMT/decoder
        makews decoder "$@"
    )
}
gitcom() {
    git commit -a -m "$*"
}
rwpaths() {
    perl -i -pe 's#/home/jgraehl/#/home/graehl/#g;s#/export/ws10smt/#/home/graehl/e/#g' "$@"
}
s0() {
    ssh -l jgraehl a0${1:-3}
}
alias ec='emacsclient -n '
gitsvnbranch() {
    git config --get-all svn-remote.$1.branches
}
gdcommit() {
    (cd $WSMT
        git svn dcommit --commit-url https://graehl:ts7sr8dG9nj2@ws10smt.googlecode.com/svn/trunk
    )
}
refargs() {
    local f
    local r
    local refarg=${refarg:--R}
    for f in "$@"; do
        r="$r $refarg $f"
    done
    echo $r
}
makesrilm() {
    (set -e;
        if [ -f "$1" ] ;then
            mkdir -p srilm
            cd srilm
            tarxzf ../$1
            local d=`realpath .`
            perl -i -pe 's{# SRILM = .*}{SRILM = '$d'}' Makefile
            shift
        fi
        head Makefile
        [ "$noclean" ] || make cleanest OPTION=_c
        local a64
        [ "$force64" ] && a64="MACHINE_TYPE=i686-m64"
        MACHINE_TYPE=`sbin/machine-type`
        for d in bin lib; do
            ln -sf $d/${MACHINE_TYPE}_c $d/${MACHINE_TYPE}
        done
        make $a64 World OPTION=_c "$@"
    )
}
allhosts="login.clsp.jhu.edu hpc.usc.edu"
conf2all() {
    local h
    for h in $allhosts; do
        conf2 $h
    done
}
cp2() {
    tohost "$@"
}
cp2all() {
    local h
    for h in $allhosts; do
        cp2 $h "$@"
    done
}
c2() {
    sync2 "$@"
}
vgd() {
    debug=1 vg "$@"
}
page() {
    "$@" 2>&1 | more
}
page2() {
    page=most save12 "$@"
}
scr() {
    screen -UaARRD
}
scrls() {
    screen -list
}

#for cygwin:
altinstall() {
    local b=$1
    local ver=$2
    local exe=$3
    local f=/usr/bin/$b-$ver$exe
    showvars_required b ver f
    require_file $f && /usr/sbin/update-alternatives --install /usr/bin/$b$exe $b $f 30
}

altgcc4() {
    /usr/sbin/update-alternatives \
        --install "/usr/bin/gcc.exe" "gcc" "/usr/bin/gcc-4.exe" 30 \
        --slave "/usr/bin/ccc.exe" "ccc" "/usr/bin/ccc-4.exe" \
        --slave "/usr/bin/i686-pc-cygwin-ccc.exe" "i686-pc-cygwin-ccc" \
        "/usr/bin/i686-pc-cygwin-ccc-4.exe" \
        --slave "/usr/bin/i686-pc-cygwin-gcc.exe" "i686-pc-cygwin-gcc" \
        "/usr/bin/i686-pc-cygwin-gcc-4.exe"

    /usr/sbin/update-alternatives \
        --install "/usr/bin/g++.exe" "g++" "/usr/bin/g++-4.exe" 30 \
        --slave "/usr/bin/c++.exe" "c++" "/usr/bin/c++-4.exe" \
        --slave "/usr/bin/i686-pc-cygwin-c++.exe" "i686-pc-cygwin-c++" \
        "/usr/bin/i686-pc-cygwin-c++-4.exe" \
        --slave "/usr/bin/i686-pc-cygwin-g++.exe" "i686-pc-cygwin-g++" \
        "/usr/bin/i686-pc-cygwin-g++-4.exe"
}

plboth() {
    local o=$1
    local oarg="-landscape"
    [ "$portrait" ] && oarg=
    shift
    pl -png -o $o.png "$@"
    pl -ps -o $o.ps $oarg "$@"
    ps2pdf $o.ps $o.pdf
}

graph() {
    local xaxis=${xaxis:-1}
    local yaxis=${yaxis:-2}
    local zaxis=${zaxis:-3}
    local xlbl="$1"
    local ylbl="$2"
    shift
    shift
    [ "$zlbl" ] && zarg="y2=$zaxis ylbl2=$zlbl"
    [ "$zlbl" ] && zword=".and.$zlbl"
    local ylbldistance=${ydistance:-'0.7"'}
    local scale=${scale:-1.4}
    [ "$topub" ] && pubb=~/pub/
    local name=${name:-`filename_from $in.$ylbl$zword.vs.$xlbl$zword`}
    local obase=${obase:-$pubb$name}
    mkdir -p `dirname $obase`
    local title=${title:-$obase}
    local darg
    if [ "$data" ] ; then
        darg="data=$data"
        if [ "$pubb" ] ; then
            banner cp "$data" $pubb/
            cp "$data" $pubb/
        fi
    fi
    set -x
    pubb=$pubb plboth $obase -prefab lines $darg x=$xaxis xlbl="$xlbl" y=$yaxis ylbl="$ylbl" ylbldistance=$ylbldistance title="$title" ystubfmt '%6g' ystubdet="size=6" -scale $scale $zarg "$@"
    set +x
    local of=$obase.png
    ls -l $obase.* 1>&2
    echo $of
}


graph3() {
    local y=$1
    local ylbl="$2"
    local y2=$3
    local ylbl2="$4"
    local y3=$5
    local ylbl3="$6"
    local ylbldistance=${7:-'0.7"'}
    local name=${name:-$data}
    local obase=${obase:-$opre$name.x_`filename_from $xlbl`.$y.`filename_from $ylbl`.$y2.`filename_from $ylbl2`.$y3.`filename_from $ylbl3`}
    local of=$obase.png
    local ops=$obase.ps
        #yrange=0
    local yrange_arg
    [ "$ymin" ] && yrange_arg="yrange=$ymin $ymax"
    #pointsym=none pointsym2=none
    title=${title:-"$ylbl $ylbl2 $ylbl3 vs. $xlbl"}
    xlbl=${xlbl:=x}
    showvars_required obase xlbl ylbl ylbl2 ylbl3
    showvars_optional yrange yrange_arg title
    require_files $data
    plboth $obase -prefab lines data=$data x=1 "$yrange_arg" y=$y name="$ylbl" y2=$y2 name2="$ylbl2" y3=$y3 name3="$ylbl3" ylbldistance=$ylbldistance xlbl="$xlbl" title="$title" ystubfmt '%4g' ystubdet="size=6" linedet2="style=1" linedet3="style=3" -scale ${scale:-1.4}
    echo $of
}

cppdb() {
    local f=$1
    shift
    g++ -x c++ -dD -E -I. -I.. -I../.. -I$FIRST_PREFIX/include "$@" "$f" > "$f.ii"
    preview "$f.ii"
}

clear_gcc() {
    unset C_INCLUDE_PATH
    unset CPPFLAGS
    unset LD_LIBRARY_PATH
    unset LIBRARY_PATH
    unset LDFLAGS
    unset CXXFLAGS
    unset CFLAGS
    unset CPPFLAGS
}

first_gcc() {
    clear_gcc
    export LD_LIBRARY_PATH=$FIRST_PREFIX/lib:$FIRST_PREFIX/lib64
    export C_INCLUDE_PATH=$FIRST_PREFIX/include
    export CXXFLAGS="-I$FIRST_PREFIX/include"
    export LDFLAGS="-L$FIRST_PREFIX/lib -L$FIRST_PREFIX/lib64"
}

config_gcc_bare() {
    first_gcc
    local nomp=--disable-libgomp
        #--disable-shared
    local skip="--disable-libssp --disable-libmudflap --disable-nls --disable-decimal-float"
# --disable-bootstrap
# gomp: open mp. ssp: stack corruption mitigation. mudflap: buffer overflow instrumentation (optional). nls: non-english text
    local basegcc=${basegcc:--enable-language=c,c++ --enable-__cxa_atexit --enable-clocale=gnu --enable-threads=posix --disable-multilib $skip}
            #--with-gmp-include=`realpath gmp` --with-gmp-lib=`realpath gmp`/.libs
# local basegcc=${basegcc:--enable-language=c,c++ --enable-clocale=gnu --enable-shared --enable-threads=posix --disable-multilib}

    src=${src:-.}

    echo $src/configure --prefix=$FIRST_PREFIX $basegcc "$@" > my.config.sh
    . my.config.sh
        #--with-mpfr=$FIRST_PREFIX --with-mpc=$FIRST_PREFIX --with-gmp=$FIRST_PREFIX
}

config_gcc() {
    ( set -e
        config_gcc_bare "$@"
    )
}


make_gcc() {
    ( set -e
        first_gcc
        make -j 4 "$@"
    )
}

install_gcc() {
    (
        first_gcc
        make install
    )
}

build_gcc() {
    (
        set -e
        config_gcc_bare "$@"
        make_gcc
        install_gcc
    )
}

dmakews() {
    g++ --version
    debug=1 MAKEPROC=4 cmakews "CXXFLAGS+=-fdiagnostics-show-option" "$@"
}

checkws() {
    debug=1 MAKEPROC=4 cmakews check
}

uninstgcc() {
    (
        set -e
        cd $FIRST_PREFIX
        cd bin
        mkdir uninstgcc
        mv *gcc* *g++* cpp gcov uninstgcc/
    )
}

confws() {
    (
        cd $WSMT
        ./configure --with-srilm=`realpath ~/src/srilm` --prefix=$FIRST_PREFIX "$@"
    )
}

bootstrap() {
    ( set -e
        aclocal
        automake --add-missing
        autoconf
        libtoolize -i --recursive
    )
}

fastflags() {
    CFLAGS+=-Ofast
    CXXFLAGS+=-Ofast
    export CFLAGS CXXFLAGS
# turns on fast-math, and maybe some unsafe opts beyond -O3
}

slowflags() {
    CFLAGS+=-O0
    CXXFLAGS+=-O0
    export CFLAGS CXXFLAGS
}
makecdec() {
    make cdec CXXFLAGS+="-Wno-sign-compare -Wno-unused-parameter -loolm -ldstruct -lmisc -lz -lboost_program_options -lpthread -lboost_regex -lboost_thread -O0 -ggdb"
}
fsadbg() {
    (
        set -e
        cd $WSMT/decoder
        makecdec
        ./dbg.cfg.sh
    )
}
carmelv() {
    grep VERSION ~/t/graehl/carmel/src/carmel.cc
}
pdf2() {
    batchmode=1 latn=2 lat2pdf_landscape "$@"
}
function toisi {
    local ARGV=( $@ )
    local ARGC=${#ARGV[@]}
    local to=${ARGV[ARGC-1]}
    echo scp -r "${ARGV[@]}" graehl@prokofiev.isi.edu:$to
}
function toisi {
    local ARGV=( $@ )
    local ARGC=${#ARGV[@]}
    local to=${ARGV[ARGC-1]}
    if (($ARGC>1)) ; then unset ARGV[ARGC-1]; fi
    set -x
    scp -r "${ARGV[@]}" graehl@prokofiev.isi.edu:$to
    set +x
}
alias ..="cd .."
alias c=cd
if [[ $OS = Darwin ]] ; then
    alias l="ls -alFG"
    alias lo="ls -alHLFCG"
    export CLICOLOR=1
else
    alias l="ls -alF --color=auto"
    alias lo="ls -alHLFC --color=auto"
fi
alias k=colormake
alias g=git
alias s=svn
getcert() {
    local REMHOST=$1
    local REMPORT=${2:-443}
    echo |\
openssl s_client -connect ${REMHOST}:${REMPORT} 2>&1 |\
sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
}
showprompt()
{
    echo $PS1 | less -E
    echo $PROMPT_COMMAND | less -E
}
