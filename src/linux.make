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

uid = support
dn  = gombos.info
password = wildthing

output_dir = build
src_dir    = src
work_dir   = work
#SUBDIRS = $(output_dir)
basename = email
products = $(output_dir)/$(basename).svg\
	   $(output_dir)/muas.png\
	   $(output_dir)/node_email_addresses.png\
	   $(output_dir)/node_webmail_addresses.png\
	   $(output_dir)/suprt_ea.png\
           $(output_dir)/pubkeys_aes.pdf\
	   $(work_dir)/$(basename).aux\
	   $(work_dir)/$(basename).log\
	   $(work_dir)/muas.aux\
	   $(work_dir)/muas.dvi\
	   $(work_dir)/muas.log\
	   $(work_dir)/node_email_addresses.aux\
	   $(work_dir)/node_email_addresses.log\
	   $(work_dir)/node_email_addresses.pdf\
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

$(work_dir)/%.pdf: $(src_dir)/%.tex
	pdflatex -output-directory $(work_dir)/ "$<"

$(work_dir)/%.dvi: $(src_dir)/%.tex
	latex -output-directory $(work_dir)/ "$<"

$(output_dir)/%_aes.pdf: $(src_dir)/%.tex
#	cd $(work_dir)/; pdflatex -output-directory ../$(output_dir)/ ../"$<"
	cd $(work_dir)/; pdflatex ../"$<"
	qpdf --encrypt "$(password)" "$(password)" 128 --use-aes=y -- $(work_dir)/"$(notdir $(basename $<))".pdf "$@"

$(output_dir)/%.png: $(work_dir)/%.dvi
	dvipng -o "$@" "$<"

$(output_dir)/%.png: $(work_dir)/%.pdf
	convert "$<" "$@"

$(output_dir)/%.svg: $(work_dir)/%.dvi
	tools/dvisvgm --color --output=$(output_dir)/%f.svg "$<"

$(output_dir)/%.svg: $(src_dir)/%.gv
	cd $(output_dir)/; dot -Tsvg ../"$<" > ../"$@"

####### Build rules

$(output_dir)/pubkeys_aes.pdf: $(work_dir)/pubkeys_files.tex

# it's a shame we depend on muas.png instead of muas.svg, but svg images render blank
$(output_dir)/$(basename).svg: $(output_dir)/suprt_ea.png $(output_dir)/node_webmail_addresses.png $(output_dir)/node_email_addresses.png $(output_dir)/muas.png $(output_dir)/pubkeys_aes.pdf

$(output_dir)/suprt_ea.png:
#	convert -channel RGBA -background none -fill black -pointsize 16 -font Ananda-Hastakchyar label:"$(uid)"@"$(dn)" "$@"
	convert -channel RGBA -background none -fill black -pointsize 16 -font Scriptina label:"$(uid)"@"$(dn)" "$@"

all: $(output_dir)/$(basename).svg

clean:
	-rm -f $(products) */*~ *~ src/*aux src/*log src/*out src/*dvi
