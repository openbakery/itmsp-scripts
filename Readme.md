# Scripts to manipulate App Store package

Scripts to extract the metadata from the App Store package so make it easier to edit. 

This package contais two scripts:

- itmspExtract.rb: parses the itmsp package an extracts the data into a new directory for application
- itmspUpdate.rb: Take the data from the applications directory and updates the itmsp package


Note: The scripts uses fastimage package, so run ```sudo gem install fastimage``` first to install the fastimage package