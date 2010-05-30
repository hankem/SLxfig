#%+
  These macros are used to format tm help docs into slang's internal
  doc format.  It is an alternative to the tm2txt program.
#%-
#i tmutil.tm

#d __comment_begin
#d __comment_end
#d __passthru_begin
#d __passthru_end
#d __verbatim_begin
#d __verbatim_end
#d __remove_empty_lines 2
#d __remove_comment_lines 1

#s+
tm_map_character ('&', "&");
tm_map_character ('<', "<");
tm_map_character ('>', ">");
#s-

#d _hlp_section#1 \__newline__\__space__{1}$1
#d function#1 \__newline__{}$1\__newline__
#d variable#1 \__newline__{}$1\__newline__
#d datatype#1 \__newline__{}$1\__newline__
#d synopsis#1 \_hlp_section{SYNOPSIS}\__newline__{}\__space__{2}$1\__newline__
#d usage#1 \_hlp_section{USAGE}\__newline__\__space__{2}$1
#d altusage#1 \__space__{2}% or\__newline__\__space__{2}$1
#d description \_hlp_section{DESCRIPTION}
#d example \_hlp_section{EXAMPLE}
#d methods \_hlp_section{METHODS}
#d qualifiers \_hlp_section{QUALIFIERS}
#d qualifier#2:3 \__space__{2}; $1: $2\__btrim__\ifarg{$3}{ (default: $3)}
#d notes \_hlp_section{NOTES}
#d seealso#1 \_hlp_section{SEE ALSO}\__newline__\__space__{2}$1
#d done \__newline__{}--------------------------------------------------------------

#d sfun#1 `$1'
#d exmp#1 `$1'
#d var#1 `$1'
#d ifun#1 `$1'
#d cfun#1 `$1'
#d ivar#1 `$1'
#d cvar#1 `$1'
#d svar#1 `$1'
#d module#1 `$1'

#d file#1 `$1'

#% intrinsic constants
#d icon#1 $1
#% datatype
#d dtype#1 $1
#% keyword
#d kw#1 `$1'
#% env variable
#d env#1 `$1'
#% exception
#d exc#1 `$1'

#d em#1 _$1_
#d NULL NULL
#d slang S-Lang
#d jed jed
#d 0 0
#d 1 1
#d 2 2
#d 3 3
#d 4 4
#d 5 5
#d 6 6
#d 7 7
#d 8 8
#d 9 9
#d -1 -1
