require 'rexml/document'



PACKAGE_EXTENSION = "itmsp"


INFO_TOKENS = {
  :title => "### TITLE ###", 
  :description => "### DESCRIPTION ###",
  :whats_new => "### WHATS_NEW ###",
  :software_url => "### SOFTWARE_URL ###",
  :support_url => "### SUPPORT_URL ###",
  :keywords => "### KEYWORDS ###"
}




def getInfoFile(version, locale) 
  return File.join(getLocaleDirectory(version, locale), "info.txt")
end

def getLocaleDirectory(version, locale)
  return File.join(getVersionDirectory(version), locale)
end

def getVersionDirectory(version)
  return File.join($outputDirectory, version)
end

def getXMLDocument
  if (ARGV.length < 1)
    puts "Usage " + File.basename($0) + " <my." + PACKAGE_EXTENSION + ">"
    puts "e.g " + File.basename($0) + " my." + PACKAGE_EXTENSION
    exit
  end
  
  $packageFile = ARGV[0];

  metadataFile = File.join($packageFile, "metadata.xml");

  if (!File.exists?(metadataFile))
    puts "Metadata.xml does not exist"
    exit
  end

  $outputDirectory = File.basename($packageFile, File.extname($packageFile))


  return REXML::Document.new File.new(metadataFile)
end