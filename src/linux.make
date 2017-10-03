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

release_url=https://github.com/alchemistanaut/contact/releases/download/v2017.0.0

uid = support
dn  = gombos.info
password = wildthing

output_dir = build
src_dir    = src
work_dir   = work
#SUBDIRS = $(output_dir)
basename = email
products = $(output_dir)/$(basename).svg\
	   $(work_dir)/node_muas.aux\
	   $(work_dir)/node_muas.dvi\
	   $(work_dir)/node_muas.log\
	   $(work_dir)/node_muas.png\
	   $(work_dir)/node_email_addresses.aux\
	   $(work_dir)/node_email_addresses.log\
	   $(work_dir)/node_email_addresses.pdf\
	   $(work_dir)/node_email_addresses.png\
	   $(work_dir)/node_webmail_addresses.aux\
	   $(work_dir)/node_webmail_addresses.log\
	   $(work_dir)/node_webmail_addresses.pdf\
	   $(work_dir)/node_webmail_addresses.png\
	   $(work_dir)/pubkeys.aux\
	   $(work_dir)/pubkeys.log\
	   $(work_dir)/pubkeys.out\
	   $(work_dir)/pubkeys.pdf\
	   $(work_dir)/suprt_ea.png\
           $(work_dir)/pubkeys_aes.pdf\
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

$(work_dir)/%.pdf: $(src_dir)/%.tex
	pdflatex -output-directory $(work_dir)/ "$<"

$(work_dir)/%.dvi: $(src_dir)/%.tex
	latex -output-directory $(work_dir)/ "$<"

$(work_dir)/%_aes.pdf: $(src_dir)/%.tex
#	cd $(work_dir)/; pdflatex -output-directory ../$(output_dir)/ ../"$<"
	cd $(work_dir)/; pdflatex ../"$<"
	qpdf --encrypt "$(password)" "$(password)" 128 --use-aes=y -- $(work_dir)/"$(notdir $(basename $<))".pdf "$@"

$(work_dir)/%.png: $(work_dir)/%.dvi
	dvipng -o "$@" "$<"

$(work_dir)/%.png: $(work_dir)/%.pdf
	convert "$<" "$@"

$(output_dir)/%.svg: $(work_dir)/%.dvi
	tools/dvisvgm --color --output=$(output_dir)/%f.svg "$<"

$(output_dir)/%.svg: $(src_dir)/%.gv
	#cd $(output_dir)/; dot -Tsvg:svg:core ../"$<" > ../"$@"; # better font and working URLs, but nodes are not embedded
	cd $(work_dir); dot -Tsvg:svg:core ../"$<" > ../"$@"; # better font and working URLs, but nodes are not embedded
	#cd $(output_dir)/; dot -Tsvg:cairo:cairo -Nfontname=Arial ../"$<" > ../"$@"; # nodes are embeeded but URLs broken
	sed -i -e "/[.]png/s![^\"]*.png!$(release_url)/&!gi;/@releaseurl@/s!@releaseurl@!$(release_url)!gi" "$@"; # hack to remedy dot's broken by design approach (image references cannot be URLs "for security reasons")

####### Build rules

$(work_dir)/pubkeys_aes.pdf: $(work_dir)/pubkeys_files.tex

# it's a shame we depend on muas.png instead of muas.svg, but svg images render blank
$(output_dir)/$(basename).svg: $(work_dir)/suprt_ea.png $(work_dir)/node_webmail_addresses.png $(work_dir)/node_email_addresses.png $(work_dir)/node_muas.png $(work_dir)/pubkeys_aes.pdf

$(work_dir)/suprt_ea.png:
#	convert -channel RGBA -background none -fill black -pointsize 16 -font Ananda-Hastakchyar label:"$(uid)"@"$(dn)" "$@"
	convert -channel RGBA -background none -fill black -pointsize 16 -font Scriptina label:"$(uid)"@"$(dn)" "$@"

all: $(output_dir)/$(basename).svg

clean:
	-rm -f $(products) */*~ *~ src/*aux src/*log src/*out src/*dvi
