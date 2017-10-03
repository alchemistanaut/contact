# Copyright 2017 Justin Gombos
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Parse the release URL from the readme file.
release_url=$(shell sed -ne '/http.*how_to_e-mail_justin.svg/s!.*\(http.*\)/how_to_e-mail_justin.svg.*!\1!p' README.md)

# support address components
uid = support
dn  = gombos.info

# password for the PDF file containing public keys (which have metadata bots shouldn't see)
pdfpassword = "wildthing"

output_dir = build
src_dir    = src
work_dir   = work
#SUBDIRS = $(output_dir)
basename = how_to_e-mail_justin
products = $(output_dir)/$(basename).svg\
	   $(output_dir)/node_email_addresses.png\
	   $(output_dir)/node_muas.png\
	   $(output_dir)/node_webmail_addresses.png\
           $(output_dir)/pubkeys_aes.pdf\
	   $(output_dir)/suprt_ea.png\
	   $(work_dir)/$(basename)_ugly.svg\
	   $(work_dir)/node_email_addresses.aux\
	   $(work_dir)/node_email_addresses.log\
	   $(work_dir)/node_email_addresses.pdf\
	   $(work_dir)/node_muas.aux\
	   $(work_dir)/node_muas.dvi\
	   $(work_dir)/node_muas.log\
	   $(work_dir)/node_webmail_addresses.aux\
	   $(work_dir)/node_webmail_addresses.log\
	   $(work_dir)/node_webmail_addresses.pdf\
	   $(work_dir)/pubkeys.aux\
	   $(work_dir)/pubkeys.log\
	   $(work_dir)/pubkeys.out\
	   $(work_dir)/pubkeys.pdf\
	   $(work_dir)/pubkeys_files.tex

.PHONY: all clean
#subdirs $(SUBDIRS)
.SUFFIXES: .pdf .tex .png .svg .dvi .aux .log

####### Implicit rules
#subdirs: $(SUBDIRS)

#$(output_dir):
#	mkdir -p "$@"

$(work_dir)/pubkeys_files.tex:
	$(src_dir)/pubkeys_gen_tex.sh

$(output_dir)/%_aes.pdf: $(work_dir)/%.pdf
#	cd $(work_dir)/; pdflatex -output-directory ../$(output_dir)/ ../"$<"
	qpdf --encrypt "$(pdfpassword)" "$(pdfpassword)" 128 --use-aes=y -- $(work_dir)/"$(notdir $(basename $<))".pdf "$@"

$(work_dir)/%.pdf: $(src_dir)/%.tex
	pdflatex -output-directory $(work_dir)/ "$<"

$(work_dir)/%.dvi: $(src_dir)/%.tex
	latex -output-directory $(work_dir)/ "$<"

$(output_dir)/%.png: $(work_dir)/%.dvi
	dvipng -o "$@" "$<"

$(output_dir)/%.png: $(work_dir)/%.pdf
	convert "$<" "$@"

$(output_dir)/%.svg: $(work_dir)/%.dvi
	tools/dvisvgm --color --output=$(output_dir)/%f.svg "$<"

# Renders ugly machine-generated SVG code from a graphviz file.
# Some string replacements are done with sed:
#
# @releaseurl@  <= replaced by $(release_url)
# @pdfpassword@ <= replaced by $(pdfpassword)
#
# URLs are also inserted into the SVG file by sed, because graphviz
# has blocked URL-referenced images ("for security reasons").
$(work_dir)/%_ugly.svg: $(src_dir)/%.gv
	cd $(output_dir)/; dot -Tsvg:svg:core ../"$<" > ../"$@"; # better font and working URLs, but nodes are not embedded
	#cd $(work_dir); dot -Tsvg:svg:core ../"$<" > ../"$@"; # better font and working URLs, but nodes are not embedded
	#cd $(output_dir)/; dot -Tsvg:cairo:cairo -Nfontname=Arial ../"$<" > ../"$@"; # nodes are embeeded but URLs broken
	sed -i -e "/[.]png/s![^\"]*.png!$(release_url)/&!gi;/@releaseurl@/s!@releaseurl@!$(release_url)!gi;/@pdfpassword@/s!@pdfpassword@!$(pdfpassword)!gi" "$@"

# Make the SVG file pretty.  Note that svgpp introduces artifacts
# (extra whitespace on the rendered diagram), so it's disabled until
# that's worked out.
$(output_dir)/%.svg: $(work_dir)/%_ugly.svg
	#svgpp "$<" "$@"
	mv "$<" "$@"

####### Build rules

$(work_dir)/pubkeys.pdf: $(work_dir)/pubkeys_files.tex

# it's a shame we depend on node_muas.png instead of node_muas.svg, but svg images render blank
$(output_dir)/$(basename).svg: $(output_dir)/suprt_ea.png $(output_dir)/node_webmail_addresses.png $(output_dir)/node_email_addresses.png $(output_dir)/node_muas.png $(output_dir)/pubkeys_aes.pdf

$(output_dir)/suprt_ea.png:
#	convert -channel RGBA -background none -fill black -pointsize 16 -font Ananda-Hastakchyar label:"$(uid)"@"$(dn)" "$@"
	convert -channel RGBA -background none -fill black -pointsize 16 -font Scriptina label:"$(uid)"@"$(dn)" "$@"

all: $(output_dir)/$(basename).svg

clean:
	-rm -f $(products) */*~ *~ src/*aux src/*log src/*out src/*dvi
