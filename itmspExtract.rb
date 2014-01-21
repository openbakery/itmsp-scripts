#!/usr/bin/env ruby
# coding: utf-8

require 'fileutils'
require_relative 'itmsp.rb'



  
def processVersion(element)
  version = element.attributes["string"]
  versionDirectory = getVersionDirectory(version)
  #puts versionDirectory 
  FileUtils.mkdir_p versionDirectory
  
  element.each_element("locales/locale") { |localeElement|
    processLocal(localeElement, version)
  }
end

def processLocal(element, version)
  locale = element.attributes["name"]
  #puts locale
  
  localDirectory = getLocaleDirectory(version, locale)
  #puts localDirectory 
  FileUtils.mkdir_p localDirectory
  
  title = getElementValue(element, "title");
  description = getElementValue(element, "description");
  whatsNew = getElementValue(element, "version_whats_new");
  softwareUrl = getElementValue(element, "software_url");
  supportUrl = getElementValue(element, "support_url");

  
  keywords = "";
  element.each_element("keywords/keyword") { |childElement| 
    if (keywords.length > 0)
      keywords += ", "
    end

    keywords += childElement.text
  }
  #puts keywords
  
  # create info file with data from the metadata file
  infoFilename = getInfoFile(version, locale)
  puts infoFilename
  infoFile = File.new(infoFilename, "w:UTF-8")
  
  infoFile.puts INFO_TOKENS[:title]
  infoFile.puts title
  infoFile.puts
  
  infoFile.puts INFO_TOKENS[:description]
  infoFile.puts description
  infoFile.puts
  
  infoFile.puts INFO_TOKENS[:whats_new]
  infoFile.puts whatsNew
  infoFile.puts
  
  infoFile.puts INFO_TOKENS[:keywords]
  infoFile.puts keywords
  infoFile.puts

  infoFile.puts INFO_TOKENS[:software_url]
  infoFile.puts softwareUrl
  infoFile.puts
  
  infoFile.puts INFO_TOKENS[:support_url]
  infoFile.puts supportUrl
  infoFile.puts
  
  infoFile.close()
  
  
  # create screenshots directory
  
  FileUtils.mkdir_p File.join(localDirectory, "iPad")
  FileUtils.mkdir_p File.join(localDirectory, "iPhone")
  FileUtils.mkdir_p File.join(localDirectory, "iPhone-4inch")
  
  
end


def getElementValue(element, name)
  result = "";
  element.each_element(name) { |childElement| 
    result = childElement.text
  }
  return result
end

if (ARGV.length < 1)
  puts "Usage itmsExtract.rb <my." + PACKAGE_EXTENSION + ">"
  puts "e.g itmsExtract.rb my." + PACKAGE_EXTENSION
  exit
end

xmlDocument = getXMLDocument()

xmlDocument.elements.each("package/software/software_metadata/versions/version") { |element| 
  processVersion(element)
}


