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

OS:= $(shell uname -s)

# This is a boilerplate, made to accommodate different OSs in forks or
# in the future of this project.  ATM it's all the same Makefile.

ifeq ($(findstring Linux, $(OS)), Linux)
include src/linux.make
else ifeq ($(findstring CYGWIN, $(OS)), CYGWIN)
include src/linux.make
else ifeq ($(findstring Darwin, $(OS)), Darwin)
include src/linux.make
else ifeq ($(findstring FreeBSD, $(OS)), FreeBSD)
include src/linux.make
else
$(error "Unsupported OS or unable to determine OS")
endif
