# Character Guess

A simple character guessing game - written in [elm](http://elm-lang.org).

## Local setup

### Pull down api data

Use `rake` to pulldown api information.

    rake pull:starships
    rake pull:people
    rake pull:vehicles

To removed downloaded file use

    rake clear


### Install elm:

```bash
$ npm install -g elm@0.18
```

### Run it:

```bash
$ npm start
```

## Build and Deploy

To deploy to the gh-pages branch, simply do:

```bash
$ npm deploy
```
