# This is the start of what will become my "ultimate Makefile for RevTeX"
# 20 April 2014, David W.H. Swenson

# REQUIRED:
# 	RevTeX4-1 (and obviously pdflatex, etc)
# 	flatex (modified to ignore missing bibstyle)
# 	pdf2eps (my script; requires poppler's pdftops installed)

# USAGE:
#   make 	    Generates a PDF of the file
#   make view	    Generates PDF and launches a viewer
#   make tar	    Generates .tar file for all the files in this directory.
#   make jcp	    Generates a *_jcp.tex file ready for JCP submission
#   make clean	    Gets rid of extraneous files (before committing to a repo)

# NOTE: USER MUST SET THE VARIABLE papername! (Currently my recent paper)
# This should be the name (without .tex extension) of your main TeX file
# (i.e., the one you use for pdflatex, bibtex, etc.)
papername=dimer_fluid_retis
# 	Also, viewcmd is system-dependent: I've got it set for Mac OS X
viewcmd=open -a Preview

# Here are a few aspects of how I work that show up in this:
#    * git for version control (in `make diff`), and I tag when we submit
#    * figures are initially PDFs (in method for converting figs to EPS)
#    * all main paper files (*tex, *bib, figs) are in the main directory;
#      cover letter etc. are in separate subdirectories
#    * no directories that you want to save begin with diff_

# These are the preprint arguments we pass along to each journal. They
# replace whatever RevTeX documentclass parameters the paper had during the
# development stage.
jcppreprint="preprint,onecolumn,endfloats*,english,jcp,aip,preprintnumbers,amsmath,amssymb,array"

figepss := $(shell ls -1 *pdf | grep -v "${papername}" | sed 's/\.pdf/.eps/')
figpdfs := $(shell ls -1 *pdf | grep -v "${papername}" )

${papername}.pdf : ${papername}.aux *.tex *.bib
	pdflatex ${papername}

${papername}.aux : *.tex *.bib
	pdflatex ${papername} && bibtex ${papername} && pdflatex ${papername}

clean :
	rm -f *bbl *blg *log *aux *Notes.bib ${papername}.tar ${papername}_flat.* *fgx *tbx *vdx

view : ${papername}.pdf
	${viewcmd} ${papername}.pdf

%.eps : %.pdf 
	pdf2eps $<

${papername}_flat.tex : ${papername}.aux *tex *bib
	flatex ${papername}.tex && mv ${papername}.flt ${papername}_flat.tex

flatten : ${papername}_flat.tex
	echo "Flat paper made"

${papername}_flat.aux : ${papername}_flat.tex ${papername}.aux
	pdflatex ${papername}_flat 


# NOTE: currently we assume all eps files are figures -- if that isn't the
# case, then I'm blaming you for your poor directory organization
jcp : ${papername}_flat.aux ${figepss}
	rm -rf jcp
	mkdir jcp && mv *eps jcp/
	cat ${papername}_flat.tex | sed 's/documentclass\[.*\]/documentclass\[${jcppreprint}\]/' > jcp/${papername}_flat.tex 
	cd jcp && pdflatex ${papername}_flat.tex && pdflatex ${papername}_flat.tex
	make jcpclean

jcpclean :
	cd jcp && rm -f *converted-to.pdf
	cd jcp && rm -f *fgx *aux *vdx *log *bib *tbx

tar :
	rm -f *bbl *blg *log *aux ${papername}.tar
	cd .. && tar --exclude .git -cLf ${papername}.tar ${papername} && mv ${papername}.tar ${papername}/ 

TAG=submit
DIFF_MAKE=jcp

# DIFF_DIR may take a slight change to get it to work with the non-jcp
# version
DIFF_DIR=${DIFF_MAKE}
DIFF_FILE=${papername}_flat.tex

#TAG=HEAD
#DIFF_MAKE=
#DIFF_DIR=./

DIFF_FILEB=$(shell echo ${DIFF_FILE} | sed 's/.tex//')
DIFFED_FILE=${DIFF_FILEB}_diff_${TAG}.tex
diff : 
	git archive --prefix diff_${TAG}/ ${TAG} | tar -x
	cp Makefile diff_${TAG}/                            # DEBUG
	cd diff_${TAG} && make ${DIFF_MAKE}
	make ${DIFF_MAKE}
	latexdiff -f IDENTICAL --allow-spaces --exclude-textcmd="citenamefont" diff_${TAG}/${DIFF_DIR}/${DIFF_FILE} ${DIFF_DIR}/${DIFF_FILE} > ${DIFF_DIR}/${DIFFED_FILE}
	cd ${DIFF_DIR} && pdflatex ${DIFFED_FILE} && pdflatex ${DIFFED_FILE}
	cd ${DIFF_DIR} && pdflatex ${DIFFED_FILE} && pdflatex ${DIFFED_FILE}
	make ${DIFF_MAKE}clean
	rm -rf diff_${TAG}
	open -a Preview ${DIFF_DIR}/${DIFF_FILEB}_diff_${TAG}.pdf

