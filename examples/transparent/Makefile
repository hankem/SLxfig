PNG_FILES = \
  mandelbrot.pdf

ADDITIONAL_FILES_TO_CLEAN = \
  mandelbrot.svg mandelbrot_alpha.png

%.pdf: %.sl
	slsh -DSLXFIG_RENDER_LATEX_AS_TRANSPARENT_PNG ../run.sl $<

include ../Makefile.sub
