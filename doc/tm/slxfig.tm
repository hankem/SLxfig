#% -*- mode: tm; mode: fold -*-

#%{{{Macros

#i linuxdoc.tm
#d it#1 <it>$1</it>

#d slang \bf{S-lang}
#d exmp#1 \tt{$1}
#d var#1 \tt{$1}

#d ivar#1 \tt{$1}
#d ifun#1 \tt{$1}
#d cvar#1 \tt{$1}
#d cfun#1 \tt{$1}
#d svar#1 \tt{$1}
#d sfun#1 \tt{$1}
#d icon#1 \tt{$1}

#d chapter#1 <chapt>$1<p>
#d preface <preface>
#d tag#1 <tag>$1</tag>

#d function#1 \sect{<bf>$1</bf>\label{$1}}<descrip>
#d variable#1 \sect{<bf>$1</bf>\label{$1}}<descrip>
#d function_sect#1 \sect{$1}
#d begin_constant_sect#1 \sect{$1}<itemize>
#d constant#1 <item><tt>$1</tt>
#d end_constant_sect </itemize>
#d synopsis#1 <tag> Synopsis </tag> $1
#d keywords#1 <tag> Keywords </tag> $1
#d usage#1 <tag> Usage </tag> <tt>$1</tt>
#d altusage#1 <newline>\__newline__{}% or <newline>\__newline__{}$1
#d description <tag> Description </tag>
#d example <tag> Example </tag>
#d notes <tag> Notes </tag>
#d qualifiers <tag> Qualifiers </tag>
#d qualifier#2:3 ; \tt{$1}: $2 \ifarg{$3}{(default: \tt{$3})}<newline>
#d seealso#1 <tag> See Also </tag> <tt>\linuxdoc_list_to_ref{$1}</tt>
#d done </descrip><p>
#d -1 <tt>-1</tt>
#d 0 <tt>0</tt>
#d 1 <tt>1</tt>
#d 2 <tt>2</tt>
#d 3 <tt>3</tt>
#d 4 <tt>4</tt>
#d 5 <tt>5</tt>
#d 6 <tt>6</tt>
#d 7 <tt>7</tt>
#d 8 <tt>8</tt>
#d 9 <tt>9</tt>
#d NULL <tt>NULL</tt>
#d file#1 <tt>$1</tt>

#d documentstyle book

#%}}}

#d module#1 \tt{$1}

\linuxdoc
\begin{\documentstyle}

\title SLxfig Reference
\author John E. Davis, with small contributions from Manfred Hanke
\date \__today__

\toc

\chapter{Introduction}
\href{http://jedsoft.org/fun/slxfig/}{SLxfig} is a
\href{http://www.jedsoft.org/slang/}{S-Lang} package that produces
plots, drawings, etc in a variety of formats (.ps, .eps, .png,
.jpeg,...).  It accomplishes this via S-Lang functions that
automatically run \href{http://www.xfig.org/}{Xfig's fig2dev} and LaTeX
to produce the desired output format.  See the
\href{http://jedsoft.org/fun/slxfig/examples.html}{examples page} for
some sample publication-quality plots and the code that produced them.

\sect{History}
In October of 2003 I was asked to give a talk at a workshop on
modeling pileup in the Chandra CCDs and was told that it should be an
electronic presentation using, for example, powerpoint.  I installed
the OpenOffice version of powerpoint and started working on the
presentation.  After about 30 minutes of frustration, I turned to
xfig, which is a very flexible and simple to use drawing program
familiar to many scientists and engineers.

Using xfig, I proceeded to draw several grids representing the CCD
pixels. At some point, I wanted to go back and change the orientation
of some of the grids such as changing vertical lines to diagonal ones.
Unfortunately, this would require recreating the grids, which would
take time. But what if I was not happy with the new orientation and
wanted to try another one? Clearly, a manual approach was not going to
work. So I started to look for an automated approach to xfig. I
searched the web and found the specification of the xfig file format
and proceeded to write a S-Lang script to automatically generate the
appropriate .fig file from a mathematical description of the object as
coded in S-Lang. SLxfig was born.

The following set of SLxfig-generated figures, which shows two
perspectives of a pair photons interacting in the CCD, illustrates the
solution to the orientation problem described above.

\href{http://jedsoft.org/fun/slxfig/2photon_a.png}{Figure 1},
\href{http://jedsoft.org/fun/slxfig/2photon_b.png}{Figure 2}

See \href{http://jedsoft.org/fun/slxfig/pileup2008.pdf}{the updated
version of the pileup-presentation} for more examples of SLxfig
generated drawings and plots.

\chapter{Function Reference}
#i slxfigfuns.tm

\end{\documentstyle}
