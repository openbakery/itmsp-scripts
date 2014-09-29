#!/usr/bin/env ruby
# coding: utf-8

require 'fileutils'
require 'fastimage'
require_relative 'itms.rb'


def processVersion(element)
  version = element.attributes["string"]
  
  element.each_element("locales/locale") { |localeElement|
    processLocale(localeElement, version)
  }
end

def processLocale(element, version)
  locale = element.attributes["name"]
  
  localDirectory = getLocaleDirectory(version, locale)
  puts "process #{localDirectory}"

  infoFilename = File.join(localDirectory, 'info.txt')
  infoFile = File.new(infoFilename, "r:UTF-8")

  info = {}
  currentKey = nil;
  currentValue = "";
  while (line = infoFile.gets)
    line.chomp!
    newKey = false
    INFO_TOKENS.each do |key, value|
      if (line == value)
        if (currentKey != nil)
          info[currentKey] = currentValue.rstrip
        end
        currentKey = key
        currentValue = ""
        newKey = true
        break;
      end
    end
    if (!newKey)
      currentValue += line
      currentValue += "\n"
    end
  end

  setElementValue(element, "title", info[:title]);
  setElementValue(element, "description", info[:description]); 
  setElementValue(element, "version_whats_new", info[:whats_new]); 
  setElementValue(element, "software_url", info[:software_url]); 
  setElementValue(element, "support_url", info[:support_url]); 


  if (info[:keywords])
    keywords = getElement(element, "keywords");
    keywords.each_element{|keyword| keywords.delete_element(keyword) }
    
    info[:keywords].split(",").each {|token|
      keyword = REXML::Element.new 'keyword'
      keyword.text = token.strip
      keywords.add_element keyword
    }
  end
  
  
  processScreenshots(element, locale, version)
  
end


def getScreenshots(version, locale, type, validSizes)
  localDirectory = getLocaleDirectory(version, locale)
  
  directory = File.join(localDirectory, type)
  
  images = Array.new
  
  Dir.chdir(directory) do
    Dir['*'].each { |item| 
      if (FastImage.type(item) == :png)
        size = FastImage.size(item)
        validSize = false
        validSizes.each {|item| 
          if (item == size)
            validSize = true
            break
          end
        }
        
        if (validSize)
          images << File.join(localDirectory, type, item)
          if (images.length == 5)
            return images
          end 
        else
          puts "Size is not supported"
        end
      else
        puts "Image '#{item}' is not supported"
      end
    }
  end
  
  return images
end

def processScreenshots(element, locale, version)
  
  iPadSizes = [
    [1024, 748],
    [1024, 768],
    [2048, 1496],
    [2048, 1536],
    [768, 1004],
    [768, 1024],
    [1536, 2008],
    [1536, 2048]
  ]
  
  iPhone3_5Sizes = [
    [640, 920], 
    [640, 960], 
    [960, 600], 
    [960, 640] 
  ]
  
  iPhone4inchSizes = [
    [640, 1096],
    [640, 1136],
    [1136, 600],
    [1136, 640]
  ]

  iPhone4_7inchSizes = [
    [1334, 750],
    [750, 1334]
  ]
  

  iPhone5_5inchSizes = [
    [2208, 1242],
    [1242, 2208]
  ]

  images = getScreenshots(version, locale, "iPad", iPadSizes)
  replaceScreenshots(element, images, "iOS-iPad", locale, version)
  
  images = getScreenshots(version, locale, "iPhone-3.5inch", iPhone3_5Sizes)
  replaceScreenshots(element, images, "iOS-3.5-in", locale, version)

  images = getScreenshots(version, locale, "iPhone-4inch", iPhone4inchSizes)
  replaceScreenshots(element, images, "iOS-4-in", locale, version)

  images = getScreenshots(version, locale, "iPhone-4.7inch", iPhone4_7inchSizes)
  replaceScreenshots(element, images, "iOS-4.7-in", locale, version)

  images = getScreenshots(version, locale, "iPhone-5.5inch", iPhone5_5inchSizes)
  replaceScreenshots(element, images, "iOS-5.5-in", locale, version)
  
end

def replaceScreenshots(element, images, target, locale, version)

  if (images.size == 0) 
    return
  end

  screenshots = getElement(element, "software_screenshots");
  screenshots.each_element{|screenshot| 
    if (screenshot.attributes["display_target"] == target)
      screenshots.delete_element(screenshot)
    end
  }
  

  images.to_enum.with_index(1).each do |image, index|
    screenshot = REXML::Element.new 'software_screenshot'
    screenshot.attributes["display_target"] = target
    screenshot.attributes["position"] = index

    size = REXML::Element.new 'size'
    size.text = File.new(image).size

    screenshot.add_element size
    
    filename = REXML::Element.new 'file_name'
    filename.text = File.basename(image, File.extname(image)) + "_" + locale + "_" + version + "_" +  target + File.extname(image)
    screenshot.add_element filename
    
    # copy file
    File.copy_stream(image, File.join($packageFile, filename.text))
    
    
    checksum = REXML::Element.new 'checksum'
    checksum.text = Digest::MD5.hexdigest(File.read(image))
    
    screenshot.add_element checksum
    
    
    screenshots.add_element screenshot

  end
  
  #screenShotsElement = getElement(element, "software_screenshots");
  #screenShotsElement.each {|shot| 
  #  puts shot
  #}
  
  
  #<software_screenshot display_target="iOS-iPad" position="5">
  #    <size>384591</size>
  #    <file_name>IMG_0331.PNG</file_name>
  #    <checksum type="md5">d2975455ca3ce98238c0c0a6fddecbe7</checksum>
  #</software_screenshot>
  
  
  puts images
end
  

def setElementValue(rootElement, name, value) 
  if (value == nil)
    return;
  end
  
  element = getElement(rootElement, name);
  
  if (element == nil)
    puts "create element for #{name}"
    
    element = REXML::Element.new name
    rootElement.add_element element
    
  end
  element.text = value
end

def getElement(element, name)
  result = nil;
  
  if (element == nil)
    return nil;
  end
  
  element.each_element(name) { |childElement| 
    result = childElement
  }
  return result
end

if (ARGV.length < 1)
  puts "Usage itmsUpdate.rb <my." + PACKAGE_EXTENSION + ">"
  puts "e.g itmsUpdate.rb my." + PACKAGE_EXTENSION
  exit
end

xmlDocument = getXMLDocument()

xmlDocument.elements.each("package/software/software_metadata/versions/version") { |element| 
  processVersion(element)
}

xmlDocument.context[:attribute_quote] = :quote
metadataFile = File.join($packageFile, "metadata.xml");
File.open(metadataFile ,"w") do |data|
  data<<xmlDocument
end



