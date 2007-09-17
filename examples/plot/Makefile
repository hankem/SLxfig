# -*- sh -*-

SL_FILES = simple.sl subplot.sl color.sl histplt.sl image.sl errbar.sl \
  overlay.sl symbol.sl scatter.sl
PNG_FILES = simple.png subplot.png color.png histplt.png image.png \
  errbar.png symbol.png scatter.png

png: $(PNG_FILES)
%.png: %.sl
	./run.sl ./$<
clean:
	/bin/rm -f $(PNG_FILES) *.fig *~
	/bin/rm -rf slxfigtmp
	/bin/rm -rf tmp_* autoeps
