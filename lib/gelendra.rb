#!/usr/bin/env ruby

=begin
    gelendra is a package(archive) manager for managing counterstrike 1.6 maps, addons, etc.
    Copyright (C) 2010  Andrius Bentkus

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'rubygems'

#default stuff
require 'yaml'
require 'fileutils'
require 'ftools'
require 'etc'

# external gem
require 'zip/zip'

require 'gelendra/ext'
require 'gelendra/bsp'

require 'gelendra/info'

require 'gelendra/package'
require 'gelendra/cli'
