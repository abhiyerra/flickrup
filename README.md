# flickrup.rb 
A utility to upload and download photos from Flickr.

## Config
Create a config file flickrup.yml and add your Flickr API Key and secret key
For example:

``` 
api_key: API_KEY
secret: SECRET_KEY
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

Just add --download to any of the Set commands.

Ex. This will download all the items in {set_id} to the optional
folder.

```
flickrup.rb --set {set_id} --download {folder}
```

## Requires

 - curl
