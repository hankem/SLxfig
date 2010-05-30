# -*- sh -*-
#
# To create the SGML files, you will need to install the tm-utils
# package.  See http://www.jedsoft.org/ for more information.
#
TMEXPAND = tmexpand
SL2TM = sl2tm
TM2HLP = $(TMEXPAND) -Mslhlp

MODULE = slxfig
GCONTOUR = gcontour
HLPFUNS_TM = 
AUTOGEN_TM = slxfigfuns.tm 
MODULE_DEPS = $(AUTOGEN_TM)

TXT_FILES = $(MODULE).txt 
SGML_FILES = $(MODULE).sgml
HTML_FILES = $(MODULE).html
TEX_FILES = $(MODULE).tex
PS_FILES = $(MODULE).ps 
PDF_FILES = $(MODULE).pdf
HLP_FILE = $(MODULE).hlp
HLP_FILES = $(HLP_FILE) gcontour.hlp

SGML2LATEX = sgml2latex -p letter -o tex
SGML2HTML = sgml2html
SGML2TXT = sgml2txt -f
LATEX = latex
PDFLATEX = pdflatex

TEXTDIR = ../text
PSDIR = ../ps
HTMLDIR = ../html
SGMLDIR = ../sgml
PDFDIR = ../pdf
HELPDIR = ../help

SUBDIRS = $(TEXTDIR) $(HTMLDIR) $(PSDIR) $(SGMLDIR) $(PDFDIR) $(HELPDIR)
SRCDIR = `pwd`

text-files: $(TXT_FILES) $(HLP_FILES)
all: $(SGML_FILES) $(HTML_FILES) $(TEX_FILES) $(TXT_FILES)
slxfigfuns.tm: ../../src/xfig/*.sl
	$(SL2TM) ../../src/xfig/*.sl > slxfigfuns.tm
	tm-sort.sl slxfigfuns.tm
#----- SGML Files -----------------------------------------------------------
$(MODULE).sgml : $(MODULE).tm $(MODULE_DEPS)
	$(TMEXPAND) $(MODULE).tm $(MODULE).sgml
#----- HTML Files -----------------------------------------------------------
$(MODULE).html : $(MODULE).sgml
	$(SGML2HTML) $(MODULE).sgml
#----- TeX Files ------------------------------------------------------------
$(MODULE).tex : $(MODULE).sgml
	$(SGML2LATEX) $(MODULE).sgml
	jed -script ./fixtex.sl $(MODULE).tex
#----- PDF Files -----------------------------------------------------------
$(MODULE).pdf : $(MODULE).tex
	$(MAKE) texclean
	$(PDFLATEX) $(MODULE).tex
	$(PDFLATEX) $(MODULE).tex
	$(PDFLATEX) $(MODULE).tex
#----- PS Files -----------------------------------------------------------
$(MODULE).ps : $(MODULE).tex texclean
	$(LATEX) $(MODULE).tex
	$(LATEX) $(MODULE).tex
	$(LATEX) $(MODULE).tex
	dvips -o $(MODULE).ps $(MODULE).dvi
#----- Text Files -----------------------------------------------------------
$(MODULE).txt: $(MODULE).sgml
	$(SGML2TXT) $(MODULE).sgml
#----------------------------------------------------------------------------
help-files: $(HLP_FILES)
$(HLP_FILE): slxfigfuns.tm
	$(TM2HLP) slxfigfuns.tm $(HLP_FILE)
gcontour.hlp:
	$(SL2TM) ../../src/gcontour.sl | $(TM2HLP) - gcontour.hlp
texclean:
	-rm -f *.dvi *.log *.aux *.toc *.out
clean: texclean
	-rm -f *~ rtl/*.BAK rtl/*~ *.tmp *-error
distclean: clean
	-rm -f *.html *.ps $(HLP_FILES) $(TXT_FILES) $(TEX_FILES) $(SGML_FILES) $(PDF_FILES) $(AUTOGEN_TM)
install-txt: $(TXT_FILES)
	-mv $(TXT_FILES) ../text
install-help: $(HLP_FILES)
	-mkdir -p $(HELPDIR)
	-mv $(HLP_FILES) $(HELPDIR)
install-all: all install-help install-txt $(PS_FILES) $(PDF_FILES)
	-mkdir -p $(HTMLDIR) $(PSDIR) $(SGMLDIR) $(PDFDIR)
	-mv *.html $(HTMLDIR)
	-mv $(PS_FILES) ../ps
	-mv $(SGML_FILES) ../sgml
	-mv $(PDF_FILES) ../pdf
install: install-txt install-help
