#! /bin/bash

# All of the Leiningen project.clj files should either already contain
# a profile called 1.6 that uses Clojure 1.6.0-master-SNAPSHOT, or I
# have made a modified project.clj file for them that does, and made
# things so that they all use Clojure 1.5.1 if you do not specify a
# profile.
#
# Thus change the value of the shell variable PROFILE below to
# "with-profile +1.6" to use Clojure 1.6.0-master-SNAPSHOT for all of
# these.


# set -e    exit immediately if a command exits with a non-0 exit status
# set +e    stop doing that

# set -x    echo expanded commands before executing them
# set +x    stop doing that

PROFILE=""
#PROFILE="+1.6"

do_eastwood()
{
    local project="$1"
    local ns="$2"

    local p
    if [ "x${PROFILE}" != "x" ]
    then
	p="with-profile ${PROFILE}"
    else
	p=""
    fi

    set +e   # Do not stop if an eastwood run returns a non-0 exit status.  Keep going with more checking, if any.
    if [ "x${ns}" = "x" ]
    then
        case ${project} in
	    http-kit)
		lein ${p} eastwood '{:exclude-namespaces [ org.httpkit.client-test org.httpkit.server-test org.httpkit.ws-test ]}'
		;;
	    reply|neocons)
		lein ${p} eastwood '{:namespaces [ :source-paths ]}'
		;;
	    timbre)
		local q
		if [ "x${p}" != "x" ]
		then
		    q="$p,+test"
		else
		    q="with-profile +test"
		fi
		lein ${q} eastwood '{:exclude-namespaces [ taoensso.timbre.appenders.android ]}'
		;;
	    *)
		lein ${p} eastwood
		;;
        esac
    elif [ "${project}" = "clojure" -a "${ns}" = "clojure-special" ]
    then
	# Namespaces to exclude when analyzing namespaces in Clojure itself:

	# These namespaces throw exceptions related to their use of
	# test.generative:
	# == Linting clojure.test-clojure.api ==
	# == Linting clojure.test-clojure.compilation ==
        # == Linting clojure.test-clojure.data-structures ==
        # == Linting clojure.test-clojure.edn ==
        # == Linting clojure.test-clojure.generators == (data.generators for this one)
        # == Linting clojure.test-clojure.numbers ==
        # == Linting clojure.test-clojure.reader ==

        # This namespace throws an exception because of something to
        # do with a use of in-ns:

        # == Linting clojure.test-clojure.evaluation ==

        # This namespace throws an exception because it could not find
        # the class
        # clojure.test_clojure.genclass.examples.ExampleClass.
        # Perhaps this could be avoided by analyzing the namespaces in
        # a different order.

        # == Linting clojure.test-clojure.genclass ==
        # == Linting clojure.test-clojure.try-catch == ClassNotFoundException clojure.test.ReflectorTryCatchFixture

        # I am not sure, but perhaps Eastwood hangs trying to analyze
        # this namespace:
        # == Linting clojure.test-helper ==

	# Sometimes analyzing this namespace throws an exception, and
	# then hang, but I think not always:
        # == Linting clojure.test-clojure.protocols ==

	lein ${p} eastwood '{:namespaces [ :test-paths ] :exclude-namespaces [ clojure.core clojure.parallel clojure.test-clojure.api clojure.test-clojure.compilation clojure.test-clojure.data-structures clojure.test-clojure.edn clojure.test-clojure.generators clojure.test-clojure.numbers clojure.test-clojure.reader clojure.test-clojure.evaluation clojure.test-clojure.genclass clojure.test-clojure.try-catch clojure.test-helper clojure.test-clojure.protocols ]}'
    elif [ "${project}" = "clojure" ]
    then
	lein ${p} eastwood "{:namespaces [ ${ns} ]}"
    else
	echo "do_eastwood called with unknown combo project=${project} ns=${ns}"
	exit 1
    fi
    set -e
}

set -e   # Fail if any of the directories do not exist, so this script can be fixed
cd repos

echo 
echo "Linting 3rd party Clojure libraries"
echo 
for lib in \
    http-kit \
    neocons \
    reply \
    timbre \
    potemkin \
    automat \
    stencil \
    clj-ns-browser \
    collection-check \
    fs \
    medley \
    utf8 \
    vclock \
    archimedes \
    chash \
    ogre \
    pantomime \
    quartzite \
    scrypt \
    serialism \
    support \
    urly \
    vclock \
    cheshire \
    criterium \
    elastisch \
    enlive \
    hiccup \
    lib-noir \
    mailer \
    meltdown \
    money \
    buffy \
    cassaforte \
    seesaw \
    titanium \
    useful
do
    echo
    echo "=== $lib"
    echo
    cd $lib
    do_eastwood $lib
    cd ..
done

echo
echo "Linting most, but not all, namespaces in Clojure itself."
echo "Skipping these namespaces, which tend to throw exceptions:"
echo "    clojure.core - might not be feasible to analyze this code"
echo "    clojure.parallel - perhaps only fails if you use JDK < 7"
echo "This is done from within algo.generic project directory"
echo
cd algo.generic
for core_ns in \
    clojure.core.protocols \
    clojure.core.reducers \
    clojure.data \
    clojure.edn \
    clojure.inspector \
    clojure.instant \
    clojure.java.browse \
    clojure.java.browse-ui \
    clojure.java.io \
    clojure.java.javadoc \
    clojure.java.shell \
    clojure.main \
    clojure.pprint \
    clojure.reflect \
    clojure.repl \
    clojure.set \
    clojure.stacktrace \
    clojure.string \
    clojure.template \
    clojure.test.junit \
    clojure.test.tap \
    clojure.test \
    clojure.uuid \
    clojure.walk \
    clojure.xml \
    clojure.zip
do
    do_eastwood clojure ${core_ns}
done
cd ..

# This mostly seems to work for analyzing Clojure's test namespaces,
# but it 'hangs' at the end without exiting.  I do not know why yet.

#cd clojure
#do_eastwood clojure clojure-special
#cd ..

echo 
echo "Linting Clojure contrib libraries"
echo "Leaving out core.typed, which has known reasons for throwing many"
echo "exceptions, and jvm.tools.analyzer, which has a namespace that"
echo "conflicts with Eastwood's tools.analyzer"
echo 
for lib in \
    algo.generic \
    algo.graph \
    algo.monads \
    core.async \
    core.cache \
    core.contracts \
    core.incubator \
    core.logic \
    core.match \
    core.memoize \
    core.rrb-vector \
    core.unify \
    data.avl \
    data.codec \
    data.csv \
    data.finger-tree \
    data.fressian \
    data.generators \
    data.json \
    data.priority-map \
    data.xml \
    data.zip \
    java.classpath \
    java.data \
    java.jdbc \
    java.jmx \
    math.combinatorics \
    math.numeric-tower \
    test.generative \
    tools.analyzer \
    tools.analyzer.jvm \
    tools.cli \
    tools.emitter.jvm \
    tools.logging \
    tools.macro \
    tools.namespace \
    tools.nrepl \
    tools.reader \
    tools.trace
do
    echo
    echo "=== $lib"
    echo
    cd $lib
    do_eastwood $lib
    cd ..
done
