flickrup.rb - A utility to upload photos to Flickr.

---

Create a config file ~/.flickrup and add your Flickr API Key and secret key
For example:
 
secret: SECRET_KEY
api_key: API_KEY
 
To run the script do something like the following:
flickrup.rb --upload dir_to_upload
or
flickrup.rb --upload path_to_file

Note that currently flickrup is uploads recursively.

List the current sets
flickrup.rb --set --list

List the links to the pictures in the set:
flickrup.rb --set SET_ID --list

Get the SET_ID by doing a '--set --list'.

Requirements:

Curl needs to be installed on your computer.

TODO:
    - Add to existing set
    - Create a new set and upload images to that set
    - Upload to existing set if it exists
