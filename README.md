# flickrup.rb 
A utility to upload and download photos from Flickr.

## Config
Create a config file ~/.flickrup and add your Flickr API Key and secret key
For example:

``` 
   secret: SECRET_KEY
   api_key: API_KEY
```
 
## Upload
To run the script do something like the following:

```
   flickrup.rb --upload dir_to_upload/or/path_to_file
```

Note that currently flickrup is uploads recursively.

## Sets

### List the current sets

```
   flickrup.rb --sets
```

### List the pictures in set

```
   flickrup.rb --set {set_id}
```

### List pictures not in sets.

```
   flickrup.rb --no-set-pics
```

## Download

List the links to the pictures in the set:
```
   flickrup.rb --set SET_ID --list
```

Get the SET_ID by doing a '--set --list'.

Requirements:

Curl needs to be installed on your computer.

TODO:
    - Add to existing set
    - Create a new set and upload images to that set
    - Upload to existing set if it exists
