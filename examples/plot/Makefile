# -*- sh -*-

PNG_FILES = \
  axisxform.png \
  color.png \
  errbar.png \
  histplt.png \
  image.png \
  multiplot.png \
  scatter.png \
  simple.png \
  subplot.png \
  symbol.png \
  ticlabels.png \
  world.png
# overlay.png \
# project.png \

png: $(PNG_FILES)
%.png: %.sl
	./run.sl ./$<
clean:
	/bin/rm -f $(PNG_FILES) *.fig *~
	/bin/rm -rf slxfigtmp
	/bin/rm -rf tmp* autoeps
