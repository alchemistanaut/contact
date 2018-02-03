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

# Parse the URL from the readme file.
#pub_url=$(shell sed -ne '/http.*how_to_e-mail_justin.svg/s!.*\(http.*\)/data/how_to_e-mail_justin.svg.*!\1!p' README.md)
pub_url=https://alchemistanaut.github.io
release_url=https://github.com/alchemistanaut/contact/releases/tag/v2017.3.0

# support address components
uid = support
dn  = gombos.info

# password for the PDF file containing public keys (which have metadata that bots shall not see)
pdfpassword = wildthing

output_dir = build
src_dir    = src
work_dir   = work
pub_dir    = ../alchemistanaut.github.io

#SUBDIRS = $(output_dir)
product_basename = how_to_e-mail_justin
products = $(output_dir)/$(product_basename).svg\
	   $(output_dir)/node_email_addresses.png\
	   $(output_dir)/node_item_suprt_ea.png\
	   $(output_dir)/node_muas.png\
	   $(output_dir)/node_webmail_addresses.png\
	   $(output_dir)/outlook_smime_setup.pdf\
	   $(output_dir)/mailapp_smime_setup.pdf\
           $(output_dir)/pubkeys_aes.pdf\
	   $(output_dir)/thumbnail.png\
	   $(work_dir)/$(product_basename)_ugly.svg\
	   $(work_dir)/node_email_addresses.aux\
	   $(work_dir)/node_email_addresses.log\
	   $(work_dir)/node_email_addresses.pdf\
	   $(work_dir)/node_muas.aux\
	   $(work_dir)/node_muas.dvi\
	   $(work_dir)/node_muas.log\
	   $(work_dir)/node_webmail_addresses.aux\
	   $(work_dir)/node_webmail_addresses.log\
	   $(work_dir)/node_webmail_addresses.pdf\
	   $(work_dir)/outlook_smime_setup.aux\
	   $(work_dir)/outlook_smime_setup.log\
	   $(work_dir)/outlook_smime_setup.out\
	   $(work_dir)/outlook_smime_setup.toc\
	   $(work_dir)/mailapp_smime_setup.aux\
	   $(work_dir)/mailapp_smime_setup.log\
	   $(work_dir)/mailapp_smime_setup.out\
	   $(work_dir)/mailapp_smime_setup.toc\
	   $(work_dir)/pubkeys.aux\
	   $(work_dir)/pubkeys.log\
	   $(work_dir)/pubkeys.out\
	   $(work_dir)/pubkeys.pdf\
	   $(work_dir)/pubkeys_files.tex\
           $(work_dir)/thumbnail.gv

.PHONY: all clean deploy
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

$(output_dir)/%.pdf: $(work_dir)/%.pdf
	qpdf --linearize "$<" "$@"
	rm "$<"

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
# @pdfurl@      <= replaced by $(release_url) <= cannot use pub_url b/c it opens using pdf.js, which lacks pdf attachment handling.
# @pdfpassword@ <= replaced by $(pdfpassword)
#
# URLs are also inserted into the SVG file by sed, because graphviz
# has blocked URL-referenced images ("for security reasons").
$(work_dir)/%_ugly.svg: $(src_dir)/%.gv
	cd $(output_dir)/; dot -Tsvg:svg:core ../"$<" > ../"$@"; # better font and working URLs, but nodes are not embedded
	#cd $(work_dir); dot -Tsvg:svg:core ../"$<" > ../"$@"; # better font and working URLs, but nodes are not embedded
	#cd $(output_dir)/; dot -Tsvg:cairo:cairo -Nfontname=Arial ../"$<" > ../"$@"; # nodes are embeeded but URLs broken
	sed -i -e '/[<]a xlink:href/s!xlink:href!xlink:show=\"new\" &!'\
               -e '/pubkeys_aes.pdf/s!xlink:href!id="pdflink-svg" &!'\
	       -e "/[.]png/s![^\"]*.png!$(release_url)/&!gi"\
	       -e "/@pdfurl@/s!@pdfurl@!$(release_url)!gi"\
               -e "/@pdfpassword@/s!@pdfpassword@!$(pdfpassword)!gi" "$@"

$(output_dir)/thumbnail.png: $(src_dir)/$(product_basename).gv
	sed '/bgcolor/s/^/ratio=0.6; size=5;/' "$<" > $(work_dir)/thumbnail.gv
	cd $(output_dir)/; dot -Tpng ../$(work_dir)/thumbnail.gv > ../"$@"

# Make the SVG file pretty.  Note that svgpp introduces artifacts
# (extra whitespace on the rendered diagram surrounding <title>-tagged
# text).  It could be a firefox defect, but in any case the sed
# expression below kills that whitespace.
$(output_dir)/%.svg: $(work_dir)/%_ugly.svg
	svgpp "$<" | sed '/[<]title[>]/{;N;N;s/\n//g;s/[<]title[>] */<title>/g;s! *[<]/title[>]!</title>!;}' > "$@"
	#mv "$<" "$@"

####### Build rules

$(work_dir)/pubkeys.pdf: $(work_dir)/pubkeys_files.tex
$(work_dir)/mailapp_smime_setup.pdf $(work_dir)/outlook_smime_setup.pdf: $(src_dir)/key_export_firefox.tex $(src_dir)/key_export_chrome.tex

# it's a shame we depend on node_muas.png instead of node_muas.svg, but svg images render blank
$(output_dir)/$(product_basename).svg: $(output_dir)/node_item_suprt_ea.png $(output_dir)/node_webmail_addresses.png $(output_dir)/node_email_addresses.png $(output_dir)/node_muas.png $(output_dir)/pubkeys_aes.pdf

$(output_dir)/node_item_suprt_ea.png:
#	convert -channel RGBA -background none -fill black -pointsize 16 -font Ananda-Hastakchyar label:"$(uid)"@"$(dn)" "$@"
	convert -channel RGBA -background none -fill black -pointsize 16 -font Scriptina label:"$(uid)"@"$(dn)" "$@"

all: $(output_dir)/$(product_basename).svg $(output_dir)/outlook_smime_setup.pdf $(output_dir)/mailapp_smime_setup.pdf $(output_dir)/thumbnail.png

clean:
	-rm -f $(products) */*~ *~ src/*aux src/*log src/*out src/*dvi

deploy:
	cp README.md $(pub_dir)
	cp $(output_dir)/*.pdf $(pub_dir)/data/
	cp $(output_dir)/*.png $(pub_dir)/images/
	sed -e "/href.*png/s!$(release_url).\(.*[.]png\"\)!$(pub_url)/images/\1!g"\
            -e "/href.*[ps][dv][fg]/s!$(release_url).\([^\"]*\"\)!$(pub_url)/data/\1!g"\
            $(output_dir)/$(product_basename).svg > $(pub_dir)/data/$(product_basename).svg
