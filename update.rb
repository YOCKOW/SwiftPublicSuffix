#!/usr/bin/ruby

=begin
 
update.rb
  ©︎ 2017-2018 YOCKOW.
   Licensed under MIT License.
   See "LICENSE.txt" for more information.
 
=end

require 'fileutils'
require 'open-uri'

ROOT_DIR = File.realpath('.', File.dirname(__FILE__))
SOURCE_FILE = File.expand_path('Sources/PublicSuffix/PublicSuffixList.swift', ROOT_DIR)

$stdout.puts("Updating '#{SOURCE_FILE}'")

BACKUP = SOURCE_FILE.sub(/\.[0-9A-Z_a-z]+$/, '~\&')
if FileTest.exist?(SOURCE_FILE)
  FileUtils.cp(SOURCE_FILE, BACKUP)
end


File.open(SOURCE_FILE, 'w') { |file|
  $stdout.puts("* Fetching Mozilla Public License Version 2.0 (MPL 2.0)")
  license_url = URI.parse('https://www.mozilla.org/media/MPL/2.0/index.txt')
  license = ""
  license_url.open{|file| license = file.read }
  raise "Cannot fetch license." if license.length < 1
  
  
  $stdout.puts("* Fetching Public Suffix List")
  blacklist = {}
  whitelist = {}
  last_modified = nil
  list_url = URI.parse('https://publicsuffix.org/list/public_suffix_list.dat')
  list_url.open {|io|
    last_modified = io.last_modified
    
    io.each {|line|
      line.strip!
      next if line =~ %r{^//}
      
      white = (line.gsub!(/^!/, '') == nil) ? false : true
      list = white ? whitelist : blacklist
      
      labels = line.split('.').reverse
      nn = labels.count
      next if nn < 1
      
      for ii in 0..(nn - 1)
        label = labels[ii]
        label = :any if label == '*'
        list[label] = {} if !list.has_key?(label)
        list = list[label]
        if ii == nn - 1 && label != :any
          list[:termination] = true
        end
      end
    }
  }
  raise "No data about Public Suffix" if blacklist.keys.count < 1
  
  file.puts("// This file was created automatically")
  file.puts("//   from #{list_url} (Last-Modified: #{last_modified ? last_modified.to_s : 'unknown'})")
  # file.puts("//   at #{DateTime.now.to_s}")
  
  file.puts()
  file.puts("// NOTICE: Original source code is licensed under Mozilla Public License Version 2.0 (MPL2.0)")
  file.puts("//         and, this file contains the source converted to Swift language.")
  file.puts("//         Subjecting to MPL 2.0, this FILE is also licensed under the same license.")
  file.puts("//         Please read comments of the original source file, and the license.")
  file.puts()
  file.puts("/*\n\n#{license}\n\n  */\n\n")
  
  $stdout.puts("** It will take a while to convert the data... **")
  
=begin
   Avoid error "expression was too complex to be solved in reasonable time;
                consider breaking up the expression into distinct sub-expressions"
   What code I want is:
      extension PublicSuffix {
        private static let _white_ck_www: PublicSuffix.Node = .label("www", next:[.termination])
        private static let _white_ck: PublicSuffix.Node = .label("ck", next:[_white_ck_www])
        private static let _white_jp_kawasaki_city: PublicSuffix.Node = .label("city", next:[.termination])
        private static let _white_jp_kawasaki: PublicSuffix.Node = .label("kawasaki", next:[_white_jp_kawasaki_city])
        private static let _white_jp_kitakyushu_city: PublicSuffix.Node = .label("city", next:[.termination])
        :
        :
        internal static let whitelist: Set<PublicSuffix.Node> = [_white_ck, _white_jp]
        :
      }
=end

  label_to_constant_name = lambda {|name|
    return name.gsub(/\-/, '$')
  }

  constants = {}
  list_to_constants = lambda {|list, prefix|
    keys = list.keys
    nn = keys.count
    for ii in 0..(nn - 1)
      key = keys[ii]
      if key != :termination && key != :any
        name = prefix + '_' + label_to_constant_name.call(key)
        constants[name] = [key, []]
        list[key].keys.each{|node|
          if node == :termination
            constants[name][1].push('.termination')
          elsif node == :any
            constants[name][1].push('.any')
          else
            constants[name][1].push(name + '_' + label_to_constant_name.call(node))
            list_to_constants.call(list[key], name)
          end
        }
      end
    end
  }

  list_to_constants.call(whitelist, '_white')
  list_to_constants.call(blacklist, '_black')
  
  file.puts('extension PublicSuffix {')
  
  constants.keys.sort{|aa,bb| bb <=> aa}.each {|constant_name|
    info = constants[constant_name]
    label = info[0]
    next_list = info[1]
    file.puts("  private static let #{constant_name}: PublicSuffix.Node = " +
              ".label(\"#{label}\", next:[#{next_list.join(', ')}])")
  }
  
  file.puts("  public static let whitelist: Set<PublicSuffix.Node> = [" +
            whitelist.keys.map{|kk| '_white_' + label_to_constant_name.call(kk)}.join(", ") + "]")
  file.puts("  public static let blacklist: Set<PublicSuffix.Node> = [" +
            blacklist.keys.map{|kk| '_black_' + label_to_constant_name.call(kk)}.join(", ") + "]")
  
  
  file.puts('}')
}

FileUtils.rm(BACKUP) if FileTest.exist?(BACKUP)

$stdout.puts("DONE.")

