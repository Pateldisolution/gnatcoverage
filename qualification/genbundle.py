#!python

from gnatpython.ex import Run
from datetime import date

import optparse, sys, os.path, shutil

class Error (Exception):
    def __init__(self):
        pass

def fail_if (p, msg):
    if p:
        print msg
        raise Error

def run (s, out=None):
    print "run : %s" % s
    l = s.split()
    if out == None:
        out = l[0]+".log"
    return Run (s.split(), output=out)

def announce (s):
    print "=========== " + s

OPENDO_SVN = "svn://scm.forge.open-do.org/scmrepos/svn"

class QMAT:

    def __init__(self, options):
        self.rootdir = options.rootdir
        self.pname = options.pname

    def to_root (self):
        os.chdir (self.rootdir)

    def setup_basedirs (self):

        announce ("setting up working dirs from %s" % self.rootdir)

        fail_if (
            os.path.exists (self.rootdir),
            "root dir '%s' exists already" % self.rootdir
            )

        self.rootdir = os.path.abspath (self.rootdir)

        os.mkdir (self.rootdir)
        fail_if (
            not os.path.isdir(self.rootdir),
            "creation of root dir '%s' failed somehow" % self.rootdir
            )

        self.itemsdir = os.path.join (self.rootdir, "ITEMS")
        os.mkdir (self.itemsdir)


    def checkout_sources (self):
        announce ("checking out sources")

        os.chdir(self.rootdir)
        run ("svn co -q %s" % OPENDO_SVN + "/couverture/trunk/couverture")

        self.repodir = os.path.join (self.rootdir, "couverture")

    def build_tor (self):
        announce ("building TOR")

        os.chdir (os.path.join (
                self.repodir, "qualification", "tor", "scripts"))
        run ("make")
        shutil.move (
            os.path.join ("build", "html"),
            os.path.join (self.itemsdir, "TOR"))

    def build_str (self):
        announce ("building STR")

        os.chdir (os.path.join (self.repodir, "testsuite"))
        shutil.move (
            os.path.join ("..", "tools", "xcov", "examples", "support"),
            "support")

        run ("python testsuite.py --target=ppc-elf --disable-valgrind "
             + "--qualif-level=doA -j6")

        os.chdir (os.path.join (self.repodir, "testsuite", "qreport"))
        run ("make html")

        shutil.move (
            os.path.join ("build", "html"),
            os.path.join (self.itemsdir, "STR"))

    def build_plans (self):
        announce ("building PLANS")

        os.mkdir ("%s/PLANS" % self.itemsdir)
        shutil.copy (
            os.path.join (self.repodir, "qualification", "plans", "plans.pdf"),
            os.path.join (self.itemsdir, "PLANS"))

    def build_pack (self):
        announce ("building INDEX")

        os.chdir (os.path.join (self.repodir, "qualification", "index"))
        run ("make html")

        packroot = os.path.join (self.rootdir, self.pname)

        fail_if (
            os.path.exists (packroot), "%s exists already !!" % packroot
            )

        shutil.move (os.path.join ("build", "html"), packroot)
        shutil.move (self.itemsdir, packroot)

        os.chdir (self.rootdir)

        run ("zip -q -r %(packname)s.zip %(packname)s" % {
                "packname": self.pname})

if __name__ == "__main__":

    op = optparse.OptionParser(usage="%prog <options>")
    op.add_option ("-r", "--root-dir", dest="rootdir")
    op.add_option ("-p", "--package-name", dest="pname")

    (options, args) = op.parse_args()

    fail_if (
        not options.rootdir,  "no root dir specified"
        )

    if not options.pname:
        today = date.today()
        options.pname = "GNATCOV-QMAT-%4d-%02d-%02d" % (
            today.year, today.month, today.day)

    qmat = QMAT (options=options)
    qmat.setup_basedirs()
    qmat.checkout_sources()
    qmat.build_tor()
    qmat.build_str()
    qmat.build_plans()
    qmat.build_pack()

